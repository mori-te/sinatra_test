# frozen_string_literal: true

require_relative 'base'

#
# 管理機能コントローラ
#
class AdminController < BaseController
  set :views, (proc { File.join(root, 'views/admin') })
  
  db = Mysql2::Client.new(
    :host => 'study-mysql', :username => 'root', :password => 'mysql', :encoding => 'utf8', :database => 'study')

  # -------
  # 画面表示処理
  # -------

  get '/' do
    redirect '/'
  end

  #
  # 問題作成＆編集画面表示
  #
  get '/create_and_edit' do
    redirect '/' unless session[:userid]

    @userid = session[:userid]
    @question = {}
    @question['no'] = @params['no'] || '0'
    @question['task'] = @question['no'] == '0' ? "新規" : "修正"
    erb :create
  end

  #
  # 提出ソースチェック画面表示
  #
  get '/check' do
    redirect '/' unless session[:userid]
    @userid = session[:userid]
    erb :check
  end

  get '/submmited_list_api' do
    userid = @params['user']
    sql = %{
      SELECT q.id, p.id as pid, q.task, p.userid, q.outline, l.name, q.cr_user
        FROM progresses p join questions q
          ON p.question_id = q.id join languages l
          ON p.lang_id = l.id
       WHERE p.userid = '#{userid}' and p.status is null
    }
    p sql
    res = db.query(sql)
    recodes = []
    res.each { |r| recodes << r }
    p recodes
    {
      user: userid,
      list: recodes
    }.to_json
  end

  get '/get_submmited_users_api' do
    redirect '/' unless session[:userid]
    res = db.query("select distinct userid from progresses where status is null")
    recodes = []
    res.each { |r| recodes << r }
    p recodes
    {
      list: recodes
    }.to_json
  end

  post '/set_status_api' do
    redirect '/' unless session[:userid]
    userid = session[:userid]
    json = JSON.parse(request.body.read)
    no = json["id"]
    status = json["status"]
    p json
    p [no, status]

    sql = %{
      UPDATE progresses SET status = ?, up_user = ?, up_date = NOW(), del_flag = '0' WHERE id = ?
    }
    stmt = db.prepare(sql)
    res = stmt.execute(status, userid, no)
    ""
  end

  # -------
  # WEBAPI
  # -------

  #
  # 問題作成＆編集API
  #
  post '/create_and_edit_question_api' do
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
      # 作成
      task = get_task_no(level)
      sql = %{
        INSERT INTO questions (task, level, input_type, parameter, file_name, file_data, outline, question, answer, cr_user, cr_date, up_user, up_date, del_flag)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), ?, NOW(), '0')
      }
      stmt = db.prepare(sql)
      res = stmt.execute(task, level, input_type, parameter, file_name, file_data, outline, question, answer, userid, userid)
    else
      # 修正
      no = params["no"].to_i
      task = params["task"]
      task_info = get_task_info(task)
      if task_info[2] != level
        task = get_task_no(level)   # 難易度(LEVEL)が変わっていたらTASK振り直し
    end
      sql = %{
        UPDATE questions SET task = ?, level = ?, input_type = ?, parameter = ?, file_name = ?, file_data = ?, outline = ?, question = ?, answer = ?, up_user = ?, up_date = NOW(), del_flag = '0' WHERE id = ?
      }
      stmt = db.prepare(sql)
      res = stmt.execute(task, level, input_type, parameter, file_name, file_data, outline, question, answer, userid, no)
    end

    ""
  end

  #
  # 問題削除処理
  #
  post '/delete_api' do
    redirect '/' unless session[:userid]
    params = JSON.parse(request.body.read)
    userid = session[:userid]
    no = params["no"]
    p [userid, no]
    sql = %{ DELETE FROM questions WHERE id = ? AND cr_user = ? }
    stmt = db.prepare(sql)
    res = stmt.execute(no, userid)
    p res
    ""
  end

  #
  # 問題取得API
  #
  get '/get_question_api' do
    redirect '/' unless session[:userid]
    @userid = session[:userid]
    no = @params['no']

    questions_dao = Questions.new(db)
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

  # -------
  # 共通処理
  # -------

  # レベル変換処理(D,C,B,A -> 1,2,3,4)
  def conv_level2no(level)
    "DCBA".index(level) + 1
  end
  
  # レベル変換処理(1,2,3,4 -> D,C,B,A)
  def conv_no2level(task_no)
    "DCBA"[task_no - 1]
  end

  def get_task_info(task)
    task =~ /(\d+)-(\d+)/ ? [$1, $2, conv_no2level($1.to_i)] : [nil, nil, nil]
  end
  
  def get_task_no(level)
    res = db.query("select substring_index(max(task), '-', -1) as level_max from questions where level = '#{level}'")
    no = res.first["level_max"].to_i + 1
    task = conv_level2no(level).to_s + "-" + no.to_s
  end

end