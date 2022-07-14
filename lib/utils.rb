#
# ユーティリティクラス
#
module STUDY
  class Utils
    # ソースコードサーバ出力
    def self.write_source_file(body, suffix)
      json = JSON.parse(body)
      user = json['user']
      source_file = "/home/#{user}/#{user}.#{suffix}"
      File.open(source_file, 'w') do |io|
        io.print(json['source'])
      end
      FileUtils.chown(user, user, [source_file])
      self.setup_parameter(user, body)
      [source_file, user]
    end

    # ソースコード実行処理
    def self.exec_source_file(user, cmd)
      result = nil
      begin
        IO.popen(['su', '-', user, '-c', "#{cmd}", :err => [:child, :out]], 'r+') do |io|
          # 標準入力データ
          File.open("/home/#{user}/.input.txt", "r").each do |buf|
            io.print(buf)
          end
          io.close_write
          result = io.read
        end
      rescue
        result = $!
      end
      result
    end

    # 入力データサーバ出力処理
    def self.set_input_file(user, file_name, data)
      input_data_file = "/home/#{user}/#{file_name}"
      File.open(input_data_file, "w") do |io|
          io.print(data)
      end
      FileUtils.chown(user, user, [input_data_file])
    end

    # パラメータセットアップ
    def self.setup_parameter(user, body)
      params = JSON.parse(body)
      data = params['input_data']
      input_type = params['input_type']
      p [input_type, data]
      if input_type != nil
        file_name = nil
        if input_type == "1"
          file_name = ".input.txt"
        elsif input_type == "2"
          file_name = params['input_file']
        end
        p [user, file_name]
        self.set_input_file(user, file_name, data)
      end
    end
  
  end

end