# frozen_string_literal: true

require_relative 'base'
require 'net/imap'

#
# index
#
class FrontController < BaseController
  set :views, (proc { File.join(root, 'views/front') })
  enable :sessions

  get '/' do
    erb :home
  end

  get '/menu' do
    redirect '/' unless session[:userid] 
    erb :menu
  end

  post '/auth' do
    user, passwd = @params[:user], @params[:passwd]
    begin
      imap = Net::IMAP.new('mail.tsone.co.jp')
      imap.authenticate('PLAIN', user, passwd)
    rescue Net::IMAP::NoResponseError
      @error = "ユーザまたはパスワードが間違っています！"
    end

    if @error != nil
      erb :home
    else
      session[:userid] = user
      redirect '/menu'
    end
  end

  get '/logout' do
    session[:userid] = nil
    erb :logout
  end

end