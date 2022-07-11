#
# 超シンプルDAO
#
require 'mysql2'
require 'json'

class BaseDao
  def initialize(client, table_name = nil)
    @client = client
    @table = table_name || self.class.name.downcase
  end

  def query_base(sql, *param)
    if param.size == 0
      res = @client.query(sql)
    else
      stmt = @client.prepare(sql)
      res = stmt.execute(*param)
    end
    res
  end

  def query(sql, *param)
    res = query_base(sql, *param)
    fields = []
    res.fields.each do |field_name|
      fields << field_name.intern
    end
    recodes = []
    question = Struct.new(self.class.name, *fields)
    res.each do |rec|
      recode = question.new(*rec.values)
      recodes << recode
    end
    recodes
  end

  def query_hash(sql, *param)
    res = query_base(sql, *param)
    recodes = []
    res.each do |rec|
      recodes << rec
    end
    recodes
  end


  def find_by(where = "", *param)
    where = "where " + where if where != ""
    query("select * from #{@table.to_s} #{where}", *param)
  end
end

if __FILE__ == $0
  client = Mysql2::Client.new(
    :host => 'study-mysql', :username => 'root', :password => 'mysql', :encoding => 'utf8', :database => 'study')
  dao = BaseDao.new(client)
  puts dao.query_hash("select * from teachers")
end