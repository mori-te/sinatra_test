#
# 超シンプルDAO
#
require 'mysql2'

class BaseDao
  def initialize(client, table_name = nil)
    @client = client
    @table = table_name || self.class.name.downcase
  end

  def query(sql, *param)
    if param.size == 0
      res = @client.query(sql)
    else
      stmt = @client.prepare(sql)
      res = stmt.execute(*param)
    end
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

  def find_by(where = "", *param)
    where = "where " + where if where != ""
    query("select * from #{@table.to_s} #{where}", *param)
  end
end
