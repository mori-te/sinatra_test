# frozen_string_literal: true

require_relative 'base'
require 'net/imap'
require 'json'
require 'yaml'
require 'fileutils'
require 'mysql2'
require 'digest/sha2'
require './lib/model'
require './lib/utils'
require './lib/simplemail'


#
# フロント機能コントローラ
#
class FrontController < BaseController
  set :views, (proc { File.join(root, 'views/front') })

  # 初期設定
  configure do
    $yaml = YAML.load_file('master.yaml')
  end

  # -------
  # 画面表示処理
  # -------

  #
  # ログイン
  #
  get '/' do
    @back_url = @params[:back]

    erb :front
  end

  #
  # 問題一覧
  #
  get '/menu' do
    redirect '/' unless session[:userid]
    @userid = session[:userid]
    level =  @params[:level] || 'D'
    @questions = []
    sql = %{
      select q.*, p.status, p.submitted
        from questions q left outer join progresses p
          on q.id = p.question_id and p.userid = '#{@userid}'
       where q.level = '#{level}'
      order by cast(substr(q.task, 3) as signed)
    }
    res = @@client.query(sql)
    res.each do |row|
      @questions << row
    end
    @level_d = level == "D" ? "active" : ""
    @level_c = level == "C" ? "active" : ""
    @level_b = level == "B" ? "active" : ""
    @level_a = level == "A" ? "active" : ""
    erb :menu
  end

  #
  # 認証
  #
  post '/auth' do
    userid, passwd = @params[:user], @params[:passwd]
    begin
      users_dao = Users.new(@@client)
      user = users_dao.find_by("userid = ?", userid).first
      if user != nil
        if user.auth_type == 1
          imap = Net::IMAP.new('mail.tsone.co.jp')
          imap.authenticate('PLAIN', userid, passwd)
        elsif user.auth_type == 0
          if user.passwd != Digest::SHA512.hexdigest(passwd)
            @error = "ユーザまたはパスワードが間違っています！"
          end
        else
          @error = "ユーザまたはパスワードが間違っています！"
        end
      else
        @error = "権限がありません。管理者に問合せて下さい。"
      end
    rescue Net::IMAP::NoResponseError
      @error = "ユーザまたはパスワードが間違っています！"
    end

    if @error != nil
      erb :front
    else
      session[:authority] = user.authority
      session[:userid] = userid
      redirect @params[:back] || '/menu'
    end
  end

  #
  # ログアウト
  #
  get '/logout' do
    session[:userid] = nil
    erb :logout
  end

  #
  # 問題回答画面
  #
  get '/study' do
    # 認証
    redirect '/' unless session[:userid]

    # パラメータ・セッション情報取得
    @no = @params['no']
    @userid = session[:userid]
    session[:no] = @no

    erb :study
  end

  # -------
  # WEBAPI
  # -------

  #
  # 問題の取得API
  #
  get '/get_question_api' do
    redirect '/' unless session[:userid]
    no = @params['no']
    @userid = session[:userid]

    sql = %{
      SELECT
        q.level, q.task, q.outline, q.question, p.code, l.shot_name, q.input_type, q.parameter, q.file_name, q.file_data, p.result, q.answer, p.userid, q.cr_user
      FROM
        questions q
        LEFT OUTER JOIN progresses p ON p.question_id = q.id and p.userid = '#{@userid}'
        LEFT OUTER JOIN languages l ON p.lang_id = l.id
      WHERE
        q.id = #{no};
    }
    res = @@client.query(sql)
    @question = res.first
    input_type = @question['input_type']
    if input_type == '1'
      @input_type, @input_data = '標準入力データ', @question['parameter']
      STUDY::Utils.set_input_file(@userid, '.input.txt', @question['parameter'])
    elsif input_type == '2'
      @input_type, @input_data = "入力ファイル（#{@question['file_name']}）", @question['file_data']
      STUDY::Utils.set_input_file(@userid, @question['file_name'], @question['file_data'])
    else
      @input_type, @input_data = '入力データなし', '-'
    end
    {
      question: @question,
      input_type: @input_type,
      input_data: @input_data
    }.to_json
  end

  # ruby実行・結果出力
  post '/exec_ruby' do
    source_file, user = STUDY::Utils.write_source_file(request.body.read, 'rb')
    result = STUDY::Utils.exec_source_file(user, "ruby #{source_file}")
    { result: result }.to_json
  end

  # java実行・結果出力
  post '/exec_java' do
    json = JSON.parse(request.body.read)
    user = json['user']
    source_code = json['source']
    class_name = source_code.scan(/class (\w+)/)[0]
    source_file = "/home/#{user}/#{user}.java"
    class_file = "/home/#{user}/#{class_name[0]}.class"
    exec_name = File.basename(class_file, '.*')
    File.open(source_file, 'w') do |io|
      io.print(json['source'])
    end
    FileUtils.chown(user, user, [source_file])
    begin
      FileUtils.rm(class_file)
    rescue
    end

    result = STUDY::Utils.exec_source_file(user, "javac #{source_file} && java #{exec_name}")
    { result: result }.to_json
  end

  # javascript実行・結果出力
  post '/exec_js' do
    source_file, user = STUDY::Utils.write_source_file(request.body.read, 'js')
    result = STUDY::Utils.exec_source_file(user, "node #{source_file}")
    { result: result }.to_json
  end

  # python実行・結果出力
  post '/exec_python' do
    source_file, user = STUDY::Utils.write_source_file(request.body.read, 'py')
    result = STUDY::Utils.exec_source_file(user, "python3.10 #{source_file}")
    { result: result }.to_json
  end

  # go実行・結果出力
  post '/exec_golang' do
    source_file, user = STUDY::Utils.write_source_file(request.body.read, 'go')
    result = STUDY::Utils.exec_source_file(user, "go run #{source_file}")
    { result: result }.to_json
  end

  # COBOL実行・結果出力
  post '/exec_cobol' do
    source_file, user = STUDY::Utils.write_source_file(request.body.read, 'cbl')
    result = STUDY::Utils.exec_source_file(user, "cobc -x #{source_file} && #{source_file.sub('.cbl', '')}")
    { result: result }.to_json
  end

  # CASL2実行・結果出力
  post '/exec_casl2' do
    source_file, user = STUDY::Utils.write_source_file(request.body.read, 'cas')
    result = STUDY::Utils.exec_source_file(user, "node-casl2 #{source_file} && node-comet2 -r #{source_file.sub('.cas', '.com')}")
    { result: result }.to_json
  end

  # C言語実行・結果出力
  post '/exec_clang' do
    source_file, user = STUDY::Utils.write_source_file(request.body.read, 'c')
    result = STUDY::Utils.exec_source_file(user, "cc #{source_file} && ./a.out")
    { result: result }.to_json
  end

  # 言語情報取得
  get '/lang' do
    lang, extension, indent, source = $yaml['LANG'][params['lang']]
    { lang: lang, indent: indent, source: source }.to_json
  end

  # ユーザ情報取得
  get '/userid' do
    redirect '/' unless session[:userid]
    userid = session[:userid]
    { userid: userid }.to_json
  end

  # ソースコード提出
  post '/submit_code' do
    # パラメータの取得
    json = JSON.parse(request.body.read)
    user = json['user']
    lang = json['lang']
    task = json['task']
    code = json['source']
    result = json['result']

    type, extension, indent, source = $yaml['LANG'][lang]
    source_file = "/home/#{user}/#{user}.#{extension}"

    languages_dao = Languages.new(@@client)
    language = languages_dao.find_by("shot_name = ?", lang).first
    questions_dao = Questions.new(@@client)
    question = questions_dao.find_by("task = ?", task).first
    teachers_dao = Teachers.new(@@client)
    teachers = teachers_dao.find_by("lang_id = ?", language.id).first

    # 進捗データ登録
    progresses_dao = Progresses.new(@@client)
    progresses = progresses_dao.find_by("userid = ? and question_id = ?", user, question.id)

    if progresses.size == 0
      sql = %{
        INSERT INTO progresses (userid, question_id, lang_id, code, sb_date, result, status, submitted, cr_user, cr_date, del_flag)
        VALUES (?, ?, ?, ?, NOW(), ?, null, 1, ?, NOW(), '0')
      }
      stmt = @@client.prepare(sql)
      res = stmt.execute(user, question.id, language.id, code, result, user)
    else
      sql = %{
        UPDATE progresses SET lang_id = ?, code = ?, sb_date = NOW(), result = ?, status = null, submitted = 1, up_user = ?, up_date = NOW(), del_flag = '0'
        WHERE userid = ? AND question_id = ?
      }
      stmt = @@client.prepare(sql)
      res = stmt.execute(language.id, code, result, user, user, question.id)
    end

    progresses = progresses_dao.find_by("userid = ? and question_id = ?", user, question.id).first

    # メール文章作成
    template = $yaml['MAIL']['MESSAGE']

    if question.input_type == "0"
      input = "入力なし"
      data = ""
    elsif question.input_type == "1"
      input = "標準入力"
      data = question.parameter
    elsif question.input_type == "2"
      input = "#{question.file_name}ファイル"
      data = question.file_data
    end

    items = {
      task: task,
      question: question.question,
      input: input,
      data: data,
      answer: question.answer,
      server: $yaml['SERVER']['SITE_ROOT'],
      check_url: $yaml['MAIL']['CHECK_URL'],
      pid: progresses.id
    }

    body = template
    items.each do |k, v|
      body = body.gsub("{#{k}}", v.to_s)
    end

    # ソースコードメール提出
    mail = STUDY::SimpleMail.new('smtp.tsone.co.jp', 25)
    from = "#{user}@tsone.co.jp"
    to = "#{teachers.userid}@tsone.co.jp"
    p [from, to]
    attach_files = [source_file]
    mail.send(from, to, body, attach_files)
    ""
  end

  # ファイルアップロード
  post '/upload' do
    name = params[:file][:filename]
    body = params[:file][:tempfile]
    user = params[:user]
    file_path = "/home/#{user}/#{name}"
    File.open(file_path, 'w') do |io|
      io.print(body.read)
    end
    FileUtils.chown(user, user, [file_path])
    ""
  end

  #
  # ヘルパーメソッド
  #

  helpers do
    # 修正権限有無
    def auth_edit(cr_user)
      ret = false
      if session[:authority] == 9 or (session[:authority] >= 1 and cr_user == session[:userid])
        ret = true
      end
      ret
    end

    # 作成＆チェック権限有無
    def auth_create_and_check
      ret = false
      if session[:authority] > 0
        ret = true
      end
      ret
    end

  end

end