# frozen_string_literal: true

require_relative 'base'
require 'net/imap'

#
# index
#
class RootController < BaseController
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
      imap.authenticate('LOGIN', user, passwd)
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

end