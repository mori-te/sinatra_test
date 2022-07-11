#
#
#
require_relative 'basedao'

# 問題データDAO
class Questions < BaseDao; end

# 進捗データDAO
class Progresses < BaseDao; end

# 言語マスタDAO
class Languages < BaseDao; end

# 先生マスタDAO
class Teachers < BaseDao; end



if __FILE__ == $0
  client = Mysql2::Client.new(
    :host => 'study-mysql', :username => 'root', :password => 'mysql', :encoding => 'utf8', :database => 'study')

  #dao = Progresses.new(client)
  dao = Teachers.new(client)
  res = dao.find_by("lang_id = ?", 2)
  res.each do |r|
    p r.userid
  end
end
