require 'bundler/setup'
require 'sinatra/base'
require 'sinatra/flash'
require 'rack/recaptcha'
require 'mail'
require 'pg'
require './database'
require './app'


THE_DB = Cruby::Database.new

the_app = Cruby::App.new

run the_app
