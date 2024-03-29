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
        timeout_sec = 30
        IO.popen(['su', '-', user, '-c', "#{cmd}", :err => [:child, :out]], 'r+') do |io|
          # 無限ループ対応
          Thread.start do 
            sleep timeout_sec
            system "kill #{io.pid}" if not io.closed? 
          end
          # 標準入力データ
          begin
            input_file_name = "/home/#{user}/.input.txt"
            File.open(input_file_name, "r").each do |buf|
              io.print(buf)
            end
            FileUtils.rm(input_file_name)
          rescue; end
          io.close_write
          result = io.read
          if result == "\nSession terminated, killing shell... ...killed.\n"
            result = "#{timeout_sec}秒応答がないためプログラムを停止しました。"
          end
        end
      rescue => e
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
      if input_type != nil and input_type != "0"
        file_name = nil
        if input_type == "1"
          file_name = ".input.txt"
        elsif input_type == "2"
          file_name = params['input_file']
        end
        p [user, file_name, data]
        self.set_input_file(user, file_name, data)
      end
    end

    def self.set_parameter(userid, question)
      input_type = question.input_type
      input_name = nil
      input_data = nil
      readonly = true;
      if input_type == '1'
        input_name, input_data = '標準入力データ', question.parameter
        self.set_input_file(userid, '.input.txt', question.parameter)
        readonly = false;
      elsif input_type == '2'
        input_name, input_data = "入力ファイル（#{question.file_name}）", question.file_data
        self.set_input_file(userid, question.file_name, question.file_data)
        readonly = false;
      else
        input_name, input_data = '入力データなし', '-'
      end
      [input_type, input_name, input_data, readonly]
    end
  
  end

end