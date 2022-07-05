#
# 簡易メールライブラリ
#
require 'mail'

module STUDY
  class SimpleMail
    attr_accessor :subject
    def initialize(smtp, port)
      @smtp = smtp
      @port = port
      @subject = '[言語学習サイト] ソースコード提出'
    end

    def send(from, to, body, attach_files)
      subject = @subject
      @mail = Mail.new do
        from from
        to   to
        subject subject
        html_part do
          content_type 'text/plain; charset=UTF-8'
          body body
        end
      end

      attach_files.each do |attach_file|
        @mail.add_file attach_file
      end
      
      @mail.delivery_method :smtp, {
        address: @smtp,
        port: @port,
        openssl_verify_mode: OpenSSL::SSL::VERIFY_NONE
      }
      @mail.deliver!
    end
  end
end

if __FILE__ == $0
  mail = STUDY::SimpleMail.new('smtp.tsone.co.jp', 25)
  from = 'mori-te@tsone.co.jp'
  to = 'mori-te@tsone.co.jp'
  body = "ほげほげ"
  attach_files = ['test.rb', 'master.yaml']
  mail.send(from, to, body, attach_files)
end