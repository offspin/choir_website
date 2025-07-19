require 'bundler/setup'
require 'sinatra/base'
require 'sinatra/flash'
require 'recaptcha'
require 'mail'
require 'pg'
require 'bcrypt'
require './database'
require './app'
require './editor'


THE_DB = Choirweb::Database.new

the_editor = Choirweb::Editor.new

the_app = Choirweb::App.new

map '/editor' do
    run the_editor
end

map '/' do
    run the_app
end
