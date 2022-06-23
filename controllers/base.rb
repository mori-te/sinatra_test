require 'sinatra/base'

class BaseController < Sinatra::Base
  set :root, File.join(File.dirname(__FILE__), '..')
  set :views, (proc { File.join(root, 'views') })
end