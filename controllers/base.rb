require 'sinatra/base'
require 'sinatra/reloader'
require 'yaml'
require 'mysql2'

# MySQL2がスレッドセーフでないのでロック掛ける。。
class Mysql2::Client
  @@semaphore = Mutex.new

  def query_with_lock(*args)
    @@semaphore.synchronize { query_without_lock(*args) }
  end
  alias_method :query_without_lock, :query
  alias_method :query, :query_with_lock

  # def prepare_with_lock(*args)
  #   @@semaphore.synchronize { prepare_without_lock(*args) }
  # end
  # alias_method :prepare_without_lock, :prepare
  # alias_method :prepare, :prepare_with_lock
end

class BaseController < Sinatra::Base
  set :root, File.join(File.dirname(__FILE__), '..')
  set :views, (proc { File.join(root, 'views') })
  enable :sessions
  use Rack::Session::Cookie, :expire_after => 3600, :secret => 'tsone'

  configure do
    @@client = nil
    $yaml = YAML.load_file('master.yaml')
    $auth = $yaml['AUTH']
  end

  # 権限チェック
  set(:auth) do |*roles|
    condition do
      unless session[:userid] && roles.any? {|role| session[:authority] == role }
        redirect "/", 303
      end
    end
  end
 
end