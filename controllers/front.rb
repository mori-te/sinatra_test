# frozen_string_literal: true

require_relative 'base'
require 'net/imap'
require 'json'
require 'yaml'
require 'mysql2'
require 'fileutils'
require './lib/model'
require './lib/simplemail'

#
# index
#
class FrontController < BaseController
  set :views, (proc { File.join(root, 'views/front') })
  enable :sessions

  client = Mysql2::Client.new(
   :host => 'study-mysql', :username => 'root', :password => 'mysql', :encoding => 'utf8', :database => 'study')

  # 初期設定
  configure do
    $yaml = YAML.load_file('master.yaml')
  end

  # ログイン
  get '/' do
    erb :front
  end

  # 問題一覧
  get '/menu' do
    redirect '/' unless session[:userid]
    @userid = session[:userid]
    level =  @params[:level]
    @level = level == nil ? 'D' : level
    @questions = []
    res = client.query("select * from questions where level = '#{@level}'")
    res.each do |row|
      @questions << row
    end
    @level_d = @level == "D" ? "active" : ""
    @level_c = @level == "C" ? "active" : ""
    @level_b = @level == "B" ? "active" : ""
    @level_a = @level == "A" ? "active" : ""

    erb :menu
  end

  # 認証
  post '/auth' do
    user, passwd = @params[:user], @params[:passwd]
    begin
      #user = 'mori-te'
      # imap = Net::IMAP.new('mail.tsone.co.jp')
      # imap.authenticate('PLAIN', user, passwd)
    rescue Net::IMAP::NoResponseError
      @error = "ユーザまたはパスワードが間違っています！"
    end

    if @error != nil
      erb :home
    else
      session[:userid] = user
      redirect '/menu'
    end
  end

  # ログアウト
  get '/logout' do
    session[:userid] = nil
    erb :logout
  end

  #
  # 学習ページ
  #

  # サイトトップ
  get '/study' do
    redirect '/' unless session[:userid]
    no = @params['no']
    @userid = session[:userid]
    session[:no] = no
    res = client.query("select * from questions where id = #{no}")
    @question = res.first
    input_type = @question['input_type']
    if input_type == '1'
      @input_type = '標準入力データ'
      @input_data = @question['parameter']
      set_input_file(@userid, '.input.txt', @question['parameter'])
    elsif input_type == '2'
      @input_type = "入力ファイル（#{@question['file_name']}）"
      @input_data = @question['file_data']
      set_input_file(@userid, @question['file_name'], @question['file_data'])
    else
      @input_type = '入力データなし'
      @input_data = '-'
    end
    erb :study
  end

  # ruby実行・結果出力
  post '/exec_ruby' do
    source_file, user = write_source_file(request.body.read, 'rb')
    result = exec_source_file(user, "ruby #{source_file}")
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

    result = exec_source_file(user, "javac #{source_file} && java #{exec_name}")
    { result: result }.to_json
  end

  # javascript実行・結果出力
  post '/exec_js' do
    source_file, user = write_source_file(request.body.read, 'js')
    result = exec_source_file(user, "node #{source_file}")
    { result: result }.to_json
  end

  # python実行・結果出力
  post '/exec_python' do
    source_file, user = write_source_file(request.body.read, 'py')
    result = exec_source_file(user, "python3.10 #{source_file}")
    { result: result }.to_json
  end

  # go実行・結果出力
  post '/exec_golang' do
    source_file, user = write_source_file(request.body.read, 'go')
    result = exec_source_file(user, "go run #{source_file}")
    { result: result }.to_json
  end

  # COBOL実行・結果出力
  post '/exec_cobol' do
    source_file, user = write_source_file(request.body.read, 'cbl')
    result = exec_source_file(user, "cobc -x #{source_file} && #{source_file.sub('.cbl', '')}")
    { result: result }.to_json
  end

  # CASL2実行・結果出力
  post '/exec_casl2' do
    source_file, user = write_source_file(request.body.read, 'cas')
    result = exec_source_file(user, "node-casl2 #{source_file} && node-comet2 -r #{source_file.sub('.cas', '.com')}")
    { result: result }.to_json
  end

  # C言語実行・結果出力
  post '/exec_clang' do
    source_file, user = write_source_file(request.body.read, 'c')
    result = exec_source_file(user, "cc #{source_file} && ./a.out")
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

    languages_dao = Languages.new(client)
    language = languages_dao.find_by("shot_name = ?", lang).first
    questions_dao = Questions.new(client)
    question = questions_dao.find_by("task = ?", task).first
    teachers_dao = Teachers.new(client)
    teachers = teachers_dao.find_by("lang_id = ?", language.id).first

    # 進捗データ登録
    sql = %{
      INSERT INTO progresses (userid, question_id, lang_id, code, result, status, submitted, cr_user, cr_date, del_flag)
      VALUES (?, ?, ?, ?, ?, null, 1, ?, NOW(), '0')
    }
    stmt = client.prepare(sql)
    res = stmt.execute(user, question.id, language.id, code, result, user)

    # ソースコードメール提出
    mail = STUDY::SimpleMail.new('smtp.tsone.co.jp', 25)
    from = "#{user}@tsone.co.jp"
    to = "#{teachers.userid}@tsone.co.jp"
    p [from, to]
    body = "課題 #{task} のソースコードを提出します。\n\n"
    body += "【問題文】\n#{question.question}\n\n"
    if question.input_type == "0"
    elsif question.input_type == "1"
      body += "【入力値】標準入力で以下になります。\n#{question.parameter}\n"
    else question.input_type == "2"
      body += "【入力値】#{question.file_name}ファイルで以下になります。\n"
      body += "#{question.file_data}\n"
    end
    body += "\n【正解】\n#{question.answer}"
    body += "\n\nご確認の程よろしくお願いいたします。\n"
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
  # 管理機能
  #

  # 問題作成
  # サイトトップ
  get '/create' do
    redirect '/' unless session[:userid]

    @userid = session[:userid]
    @question = {}
    @question['task'] = "新規"
    @question['no'] = @params['no'] ? @params['no'] : '0'
    p @question['no']
    erb :create
  end

  get '/edit' do
    redirect '/' unless session[:userid]
    @userid = session[:userid]
    no = @params['no']

    questions_dao = Questions.new(client)
    qa = questions_dao.find_by("id = ?", no.to_i).first
    input_data = qa.parameter if qa.input_type == "1"
    input_data = qa.file_data if qa.input_type == "2"

    { 
      task: qa.task,
      level: qa.level,
      outline: qa.outline,
      question: qa.question,
      input_type: qa.input_type,
      input_data: input_data,
      input_file_name: qa.file_name,
      answer: qa.answer
    }.to_json
  end

  post '/create' do
    redirect '/' unless session[:userid]
    params = JSON.parse(request.body.read)
    userid = session[:userid]
    level = params["level"]

    input_type = params["input_type"]
    parameter = params["input_data"] if input_type == "1"
    file_data = params["input_data"] if input_type == "2"
    file_name = params["input_file_name"] if input_type == "2"
    outline = params["outline"]
    question = params["question"]
    answer = params["answer"]

    if params["no"] == "0"
      res = client.query("select substring_index(max(task), '-', -1) as level_max from questions where level = '#{level}'")
      no = res.first["level_max"].to_i + 1
      task = conv_level(level).to_s + "-" + no.to_s
      sql = %{
        INSERT INTO questions (task, level, input_type, parameter, file_name, file_data, outline, question, answer, cr_user, cr_date, up_user, up_date, del_flag)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), ?, NOW(), '0')
      }
      stmt = client.prepare(sql)
      res = stmt.execute(task, level, input_type, parameter, file_name, file_data, outline, question, answer, userid, userid)
    else
      no = params["no"].to_i
      task = params["task"]
      sql = %{
        UPDATE questions SET level = ?, input_type = ?, parameter = ?, file_name = ?, file_data = ?, outline = ?, question = ?, answer = ?, up_user = ?, up_date = NOW(), del_flag = '0'
      }
      stmt = client.prepare(sql)
      res = stmt.execute(level, input_type, parameter, file_name, file_data, outline, question, answer, userid)
    end

    ""
  end



  # 共通処理
  def write_source_file(body, suffix)
    json = JSON.parse(body)
    user = json['user']
    source_file = "/home/#{user}/#{user}.#{suffix}"
    File.open(source_file, 'w') do |io|
      io.print(json['source'])
    end
    FileUtils.chown(user, user, [source_file])
    [source_file, user]
  end

  def exec_source_file(user, cmd)
    result = nil
    begin
      IO.popen(['su', '-', user, '-c', "#{cmd}", :err => [:child, :out]], 'r+') do |io|
        # 標準入力データ
        File.open("/home/#{user}/.input.txt", "r").each do |buf|
          io.print(buf)
        end
        io.close_write
        result = io.read
      end
    rescue
      result = $!
    end
    result
  end

  def set_input_file(user, file_name, data)
    input_data_file = "/home/#{user}/#{file_name}"
    File.open(input_data_file, "w") do |io|
        io.print(data)
    end
    FileUtils.chown(user, user, [input_data_file])
  end  

  def conv_level(level)
    69 - level[0].ord
  end

end