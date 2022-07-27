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
    @@mu = Mutex.new
    
    def initialize(client, table_name = nil)
      @client = client
      @table = table_name || pascal_to_snake(self.class.name)
    end

    # パスカル－スネーク簡易変換
    def pascal_to_snake(str)
      str.scan(/([A-Z][a-z]*)/).map {|x| x[0].downcase}.join("_")
    end

    # 検索
    def query_base(sql, *param)
      res = nil

      p [sql, param]
      if param.size == 0
       res = @client.query(sql)
      else
        res = @client.prepare(sql).execute(*param)
      end
      res
    end

    # 検索
    def query(sql, *param)
      @@mu.synchronize {
        res = query_base(sql, *param)
        res.map do |rec|
          Recode.new(rec)
        end
      }
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
      query_base(sql, *values)
    end

    # 更新
    def update(data, where, *param)
      res = query("describe #{@table}")
      data[:up_date] = data[:up_date] || Time.new if res.one? {|r| r.Field == "up_date"}
      binds = data.keys.map {|k| "#{k} = ?"}.join(",")
      values = data.values.push(*param)
      sql = "UPDATE #{@table} SET #{binds} WHERE #{where}"
      query_base(sql, *values)
    end

    # 削除
    def delete(where, *param)
      sql = "DELETE FROM #{@table} WHERE #{where}"
      query_base(sql, *param)
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