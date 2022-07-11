require 'sinatra/base'
require 'sinatra/reloader'
require 'mysql2'

# MySQL2がスレッドセーフでないのでロック掛ける。。
class Mysql2::Client
  @@semaphore = Mutex.new

  def query_with_lock(*args)
    @@semaphore.synchronize { query_without_lock(*args) }
  end
  alias_method :query_without_lock, :query
  alias_method :query, :query_with_lock
end

class BaseController < Sinatra::Base
  set :root, File.join(File.dirname(__FILE__), '..')
  set :views, (proc { File.join(root, 'views') })
  enable :sessions

  configure do
  end

 
end