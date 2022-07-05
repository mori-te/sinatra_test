# frozen_string_literal: true

require_relative 'base'
require 'net/imap'

#
# admin 
#
class AdminController < BaseController
  set :views, (proc { File.join(root, 'views/admin') })

  get '/' do
    erb :admin
  end

  # 認証
  post '/auth' do
    user, passwd = @params[:user], @params[:passwd]
    @error = nil
    begin
      #user = 'mori-te'
      imap = Net::IMAP.new('mail.tsone.co.jp')
      imap.authenticate('PLAIN', user, passwd)
    rescue Net::IMAP::NoResponseError
      @error = "ユーザまたはパスワードが間違っています！"
    end

    if @error != nil
      erb :admin
    else
      session[:userid] = user
      redirect '/admin/menu'
    end
  end

  get '/menu' do
    'admin users'
  end
end