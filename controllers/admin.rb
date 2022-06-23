# frozen_string_literal: true

require_relative 'base'

#
# admin 
#
class AdminController < BaseController
  set :views, (proc { File.join(root, 'views/admin') })

  get '/' do
    erb :admin
  end

  get '/users' do
    'admin users'
  end
end