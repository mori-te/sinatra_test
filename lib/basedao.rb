#
# 超シンプルDAO
#
require 'mysql2'
require 'json'

module STUDY
  class Recode
    def initialize(row)
      @row = row
    end
    def to_h
      @row.to_h
    end
    def method_missing(method, *args)
      super if !@row.keys.include?(method.to_s)
      @row[method.to_s]
    end
  end

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
      res.map do |rec|
        Recode.new(rec)
      end
    end

    def find_by(where = "", *param)
      where = "where " + where if where != ""
      query("select * from #{@table.to_s} #{where}", *param)
    end
  end
end

if __FILE__ == $0
  client = Mysql2::Client.new(
    :host => 'study-mysql', :username => 'root', :password => 'mysql', :encoding => 'utf8', :database => 'study')
  dao = STUDY::BaseDao.new(client, :questions)
  p dao.find_by
end