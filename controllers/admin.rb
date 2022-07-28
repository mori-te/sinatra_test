# frozen_string_literal: true

require_relative 'base'
require './lib/utils'

#
# 管理機能コントローラ
#
class AdminController < BaseController
  set :views, (proc { File.join(root, 'views/admin') })
  
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
    redirect '/' unless session[:userid] and session[:authority] > 0

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
    redirect '/' unless session[:userid] and session[:authority] > 0
    @userid = session[:userid]
    erb :check
  end

  #
  # 提出回答確認画面表示
  #
  get '/check_answer' do 
    redirect '/' unless session[:userid] and session[:authority] > 0

    # パラメータ・セッション情報取得
    @pid = @params['pid']
    @userid = session[:userid]

    erb :check_answer
  end

  # -------
  # WEBAPI
  # -------

  #
  # 提出問題取得API
  #
  get '/check_progress_api' do
    redirect '/' unless session[:userid] and session[:authority] > 0

    # パラメータ・セッション情報取得
    pid = @params['pid']
    userid = session[:userid]
    
    # 問題取得
    sql = %{
      SELECT q.id, q.level, q.task, q.outline, q.question, p.code, l.shot_name, q.input_type, q.parameter, q.file_name, q.file_data, p.result, q.answer, p.userid, q.cr_user
        FROM (progresses p join questions q ON p.question_id = q.id) join languages l
          ON p.lang_id = l.id
      WHERE p.id = ?
    }
    dao = STUDY::BaseDao.new(@@client)
    question = dao.query(sql, pid).first

    # パラメータのセット
    input_type, input_name, input_data, readonly = STUDY::Utils.set_parameter(userid, question)

    {
      question: question.to_h,
      input_type: input_type,
      input_name: input_name,
      input_data: input_data,
      input_readonly: readonly
    }.to_json
  end

  #
  # 提出リスト取得API
  #
  get '/submmited_list_api' do
    redirect '/' unless session[:userid] and session[:authority] > 0

    userid = @params['user']
    sql = %{
      SELECT q.id, p.id as pid, q.task, p.userid, q.outline, l.name, q.cr_user, p.sb_date, '' as href
        FROM progresses p join questions q
          ON p.question_id = q.id join languages l
          ON p.lang_id = l.id
       WHERE p.userid = ? and p.status is null
    }
    dao = STUDY::BaseDao.new(@@client)
    res = dao.query(sql, userid)
    recodes = res.map do |r|
      r.href = "check_answer?pid=#{r.pid}"
      r.sb_date = r.sb_date && r.sb_date.strftime("%Y/%m/%d")
      r.to_h
    end

    {
      user: userid,
      list: recodes
    }.to_json
  end

  #
  # 提出済ユーザ取得API
  #
  get '/get_submmited_users_api' do
    redirect '/' unless session[:userid]

    res = @@client.query("select distinct userid from progresses where status is null")
    recodes = res.map {|r| r}
    {
      list: recodes
    }.to_json
  end

  #
  # OK/NGステータス更新API
  #
  post '/set_status_api' do
    redirect '/' unless session[:userid] and session[:authority] > 0
    userid = session[:userid]
    json = JSON.parse(request.body.read)
    no = json["id"]
    status = json["status"]
    p [no, status]

    dao = Progresses.new(@@client)
    data = {
      status: status,
      up_user: userid
    }
    dao.update(data, "id = ?", no)

    {}.to_json
  end

  #
  # 問題作成＆編集API
  #
  post '/create_and_edit_question_api' do
    redirect '/' unless session[:userid] and session[:authority] > 0
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

    dao = Questions.new(@@client)
    data = {
      level: level, input_type: input_type, parameter: parameter, file_name: file_name, file_data: file_data, outline: outline, question: question, answer: answer, del_flag: '0'
    }

    if params["no"] == "0"
      # 作成
      task = get_task_no(level)

      data.update({
        task: task, cr_user: userid, up_user: userid, up_date: Time.now
      })
      dao.insert(data)
    else
      # 修正
      no = params["no"].to_i
      task = params["task"]
      task_info = get_task_info(task)
      if task_info[2] != level
        task = get_task_no(level)   # 難易度(LEVEL)が変わっていたらTASK振り直し
      end

      data.update({
        task: task, up_user: userid
      })
      dao.update(data, "id = ?", no)
    end

    ""
  end

  #
  # 問題削除処理
  #
  post '/delete_api' do
    redirect '/' unless session[:userid] and session[:authority] > 0
    params = JSON.parse(request.body.read)
    userid = session[:userid]
    no = params["no"]
    p [userid, no]

    dao = Questions.new(@@client)
    res = dao.delete("id = ? AND cr_user = ?", no, userid)
    ""
  end

  #
  # 問題取得API
  #
  get '/get_question_api' do
    redirect '/' unless session[:userid] and session[:authority] > 0
    @userid = session[:userid]
    no = @params['no']

    dao = Questions.new(@@client)
    qa = dao.find_by("id = ?", no.to_i).first
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
    dao = Questions.new(@@client)
    res = dao.query("select substring_index(max(task), '-', -1) as level_max from questions where level = ?", level).first
    no = res.level_max.to_i + 1
    task = conv_level2no(level).to_s + "-" + no.to_s
  end

end