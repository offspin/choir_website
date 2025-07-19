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


THE_DB = Cruby::Database.new

the_editor = Cruby::Editor.new

the_app = Cruby::App.new

map '/editor' do
    run the_editor
end

map '/' do
    run the_app
end
