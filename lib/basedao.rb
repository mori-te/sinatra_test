#
# 超シンプルDAO
#
require 'mysql2'
require 'json'

module STUDY
  #
  # Recodeクラス
  #
  class Recode
    def initialize(row)
      @row = row
    end

    # ハッシュ化
    def to_h
      @row.to_h
    end

    # カラム値の取得
    def method_missing(method, *args)
      super if !@row.keys.include?(method.to_s)
      @row[method.to_s]
    end
  end

  #
  # 基本DAOクラス
  #
  class BaseDao
    def initialize(client, table_name = nil)
      @client = client
      @table = table_name || self.class.name.downcase
    end

    # 検索
    def query_base(sql, *param)
      if param.size == 0
        res = @client.query(sql)
      else
        stmt = @client.prepare(sql)
        res = stmt.execute(*param)
      end
      res
    end

    # 検索
    def query(sql, *param)
      res = query_base(sql, *param)
      res.map do |rec|
        Recode.new(rec)
      end
    end

    # 検索
    def find_by(where = "", *param)
      where = "where " + where if where != ""
      query("select * from #{@table.to_s} #{where}", *param)
    end

    # 登録
    def insert(data)
      res = query("describe #{@table}")
      data[:cr_date] = data[:cr_date] || Time.new if res.one? {|r| r.Field == "cr_date"}
      columns = data.keys.join(',')
      binds = Array.new(data.keys.size, '?').join(',')
      values = data.values
      sql = "INSERT INTO #{@table} (#{columns}) VALUES (#{binds})"
      stmt = @client.prepare(sql)
      stmt.execute(*values)
    end

    # 更新
    def update(data, where, *param)
      res = query("describe #{@table}")
      data[:up_date] = data[:up_date] || Time.new if res.one? {|r| r.Field == "up_date"}
      binds = data.keys.map {|k| "#{k} = ?"}.join(",")
      values = data.values.push(*param)
      sql = "UPDATE #{@table} SET #{binds} WHERE #{where}"
      stmt = @client.prepare(sql)
      stmt.execute(*values)
    end

    # 削除
    def delete(where, *param)
      sql = "DELETE FROM #{@table} WHERE #{where}"
      stmt = @client.prepare(sql)
      stmt.execute(*param)
    end
  end
end

if __FILE__ == $0
  client = Mysql2::Client.new(
    :host => 'study-mysql', :username => 'root', :password => 'mysql', :encoding => 'utf8', :database => 'study')
  
  class Teachers < STUDY::BaseDao; end
  dao = Teachers.new(client)
  data = { id: 100, lang_id: 100, userid: 'test2', del_flag: '0' }
  #dao.insert(data)
  #dao.update(data, "id = ?", 100)
  #dao.delete("id = ?", 100)
  pp dao.find_by
end