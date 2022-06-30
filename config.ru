#!/bin/env
# 起動方法: bundle exec rackup
#
require './controllers/front'
require './controllers/admin'

run Rack::URLMap.new({
  '/' => FrontController,
  '/admin' => AdminController
})
