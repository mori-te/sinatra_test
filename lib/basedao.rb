#
# 超シンプルDAO
#
require 'mysql2'

class BaseDao
  def initialize(client)
    @client = client
    @clazz = self.class.name.downcase
  end

  def query(sql, *param)
    if param.size == 0
      res = @client.query(sql)
    else
      stmt = @client.prepare(sql)
      res = stmt.execute(*param)
    end
    res
  end

  def find_by(where = "", *param)
    where = "where " + where if where != ""
    res = query("select * from #{@clazz} #{where}", *param)
    fields = []
    res.fields.each do |field_name|
      fields << field_name.intern
    end
    recodes = []
    dao = Struct.new(self.class.name, *fields)
    res.each do |rec|
      recode = dao.new(*rec.values)
      recodes << recode
    end
    recodes
  end
end
