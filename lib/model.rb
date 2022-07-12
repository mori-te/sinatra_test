#
#
#
require_relative 'basedao'
require "json/add/core"

# 問題データDAO
class Questions < BaseDao; end

# 進捗データDAO
class Progresses < BaseDao; end

# 言語マスタDAO
class Languages < BaseDao; end

# 先生マスタDAO
class Teachers < BaseDao; end

# ユーザDAO
class Users < BaseDao; end



if __FILE__ == $0
  client = Mysql2::Client.new(
    :host => 'study-mysql', :username => 'root', :password => 'mysql', :encoding => 'utf8', :database => 'study')

  #dao = Progresses.new(client)
  dao = Users.new(client)
  res = dao.find_by("userid = ?", "mori-te").first
  p res.to_h.to_json
end
