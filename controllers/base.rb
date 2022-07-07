require 'sinatra/base'
require 'sinatra/reloader'
require 'mysql2'

class BaseController < Sinatra::Base
  set :root, File.join(File.dirname(__FILE__), '..')
  set :views, (proc { File.join(root, 'views') })
  enable :sessions

  configure do
    @@client = Mysql2::Client.new(
      :host => '172.18.0.2', :username => 'root', :password => 'mysql', :encoding => 'utf8', :database => 'study')
  end

 
end