# frozen_string_literal: true

require_relative 'base'
require 'net/imap'
require 'json'
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
  get '/menu', :auth => [:user, :teacher, :admin] do
    @userid = session[:userid]
    level =  @params[:level] || 'D'

    sql = %{
      select q.*, p.status, p.submitted
        from questions q left outer join progresses p
          on q.id = p.question_id and p.userid = ?
       where q.level = ?
      order by cast(substr(q.task, 3) as signed)
    }
    dao = STUDY::BaseDao.new(@@client)
    @questions = dao.query(sql, @userid, level)

    @level = 'DCBA'.split(//).map {|x| [x, level == x ? "active" : ""]}.to_h

    erb :menu
  end

  #
  # 認証
  #
  post '/auth' do
    userid, passwd = @params[:user], @params[:passwd]
    begin
      db = $yaml['DATABASE']
      @@client = Mysql2::Client.new(
        :host => db['HOST'], :username => db['USERNAME'], :password => db['PASSWORD'], :encoding => 'utf8', :database => db['DBNAME'])

      ml = $yaml['MAIL']
      users_dao = Users.new(@@client)
      user = users_dao.find_by("userid = ?", userid).first
      if user != nil
        if user.auth_type == 1
          imap = Net::IMAP.new(ml['HOST'])
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
      #session[:authority] = user.authority
      session[:authority] = $auth[user.authority]
      session[:userid] = userid

      dao = Languages.new(@@client)
      res = dao.find_by
      @@langs = res.map {|r| [r.shot_name, r] }.to_h
    
      redirect @params[:back] || '/menu'
    end
  end

  get '/auth' do
    redirect "/"
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
  get '/study', :auth => [:user, :teacher, :admin] do
    # 認証
    #redirect '/' unless session[:userid]

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
  get '/get_question_api', :auth => [:user, :teacher, :admin] do
    #redirect '/' unless session[:userid]
    no = @params['no']
    userid = session[:userid]

    sql = %{
      SELECT
        q.id, q.level, q.task, q.outline, q.question, p.code as source, p.lang_id, l.shot_name, q.input_type, q.parameter, q.file_name, q.file_data, p.result, q.answer, p.userid, q.cr_user
      FROM
        questions q
        LEFT OUTER JOIN progresses p ON p.question_id = q.id and p.userid = ?
        LEFT OUTER JOIN languages l ON p.lang_id = l.id
      WHERE
        q.id = ?;
    }
    dao = AnswerCodes.new(@@client)
    question = dao.query(sql, userid, no).first

    # パラメータのセット
    input_type, input_name, input_data, readonly = STUDY::Utils.set_parameter(userid, question)
    if question.lang_id == nil
      answer = dao.find_by("question_id = ? and lang_id = ? and userid = ?", question.id, question.lang_id, userid).first
      if answer
        question.source = answer.code
      end
    end

    {
      question: question.to_h,
      input_type: input_type,
      input_data: input_data,
      input_name: input_name,
      input_readonly: readonly
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
    result = nil
    begin
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
      rescue; end

      result = STUDY::Utils.exec_source_file(user, "javac #{source_file} && java #{exec_name}")
    rescue
      p $!
      result = "予期せぬエラーが発生しました。クラスが定義されているか確認してください。"
    end
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
  get '/lang', :auth => [:user, :teacher, :admin] do
    lang = @@langs[params['lang']]
    lang_id = lang.id
    userid = session[:userid]
    no = params['no'] || "0"
    source = lang.source
    p [no, lang_id, userid]
    if no.to_i > 0
      answer_code_dao = AnswerCodes.new(@@client)
      answer = answer_code_dao.find_by("question_id = ? and lang_id = ? and userid = ?", no, lang_id, userid).first
      if answer
        source = answer.code
      end
    end
    p [lang, userid, no, source]
    { lang: lang.mode, indent: lang.indent, source: source }.to_json
  end

  # ユーザ情報取得
  get '/userid' do
    redirect '/' unless session[:userid]
    userid = session[:userid]
    { userid: userid }.to_json
  end

#
  # 解答保存API
  #
  post '/save_api', :auth => [:user, :teacher, :admin] do
    #redirect '/' unless session[:userid]
    userid = session[:userid]
    params = JSON.parse(request.body.read)
    no = params['question_id']
    code = params['code']
    lang_dao = Languages.new(@@client)
    lang = lang_dao.find_by("shot_name = ?", params['lang']).first
    
    answer_code_dao = AnswerCodes.new(@@client)
    res = answer_code_dao.find_by("question_id = ? and lang_id = ?", no, lang.id).first
    data = {
      question_id: no,
      lang_id: lang.id,
      userid: userid,
      code: code,
      del_flag: '0'
    }
    if res == nil
      data['cr_user'] = userid
      answer_code_dao.insert(data)
    else
      data['up_user'] = userid
      answer_code_dao.update(data, "id = ?", res.id)
    end

    {}.to_json
  end

  # ソースコード提出
  post '/submit_code', :auth => [:user, :teacher, :admin] do
    # パラメータの取得
    json = JSON.parse(request.body.read)
    user = json['user']
    lang = json['lang']
    task = json['task']
    code = json['source']
    result = json['result']

    lang_info = @@langs[lang]
    source_file = "/home/#{user}/#{user}.#{lang_info.suffix}"

    languages_dao = Languages.new(@@client)
    language = languages_dao.find_by("shot_name = ?", lang).first
    questions_dao = Questions.new(@@client)
    question = questions_dao.find_by("task = ?", task).first
    teachers_dao = Teachers.new(@@client)
    teachers = teachers_dao.find_by("lang_id = ?", language.id).first

    # 進捗データ登録
    progresses_dao = Progresses.new(@@client)
    progresses = progresses_dao.find_by("userid = ? and question_id = ?", user, question.id)

    data = {
      userid: user,
      lang_id: language.id,
      code: code,
      sb_date: Time.now,
      result: result,
      submitted: 1,
      del_flag: '0'
    }
    if progresses.size == 0
      # 登録
      data['question_id'] = question.id
      data['cr_user'] = user
      progresses_dao.insert(data)
    else
      # 更新
      data['up_user'] = user
      progresses_dao.update(data, "userid = ? AND question_id = ?", user, question.id)
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
      if session[:authority] == :admin or (session[:authority] == :teacher and cr_user == session[:userid])
        ret = true
      end
      ret
    end

    # 作成＆チェック権限有無
    def auth_create_and_check
      ret = false
      if session[:authority] != :user
        ret = true
      end
      ret
    end

  end

end