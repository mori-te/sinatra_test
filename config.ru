#!/bin/env
# 起動方法: bundle exec rackup -p 4567 -o 0.0.0.0
#
require './controllers/front'
require './controllers/admin'

run Rack::URLMap.new({
  '/' => FrontController,
  '/admin' => AdminController
})
