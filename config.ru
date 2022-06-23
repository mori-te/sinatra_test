#!/bin/env
# 起動方法: bundle exec rackup
#
require './controllers/home'
require './controllers/admin'

run Rack::URLMap.new({
  '/' => RootController,
  '/admin' => AdminController
})
