require 'bundler/setup'
require 'sinatra/base'
require 'sinatra/flash'
require 'recaptcha'
require 'mail'
require 'pg'
require 'bcrypt'
require './database'
require './site'
require './editor'


THE_DB = Choirweb::Database.new

the_editor = Choirweb::Editor.new

the_site = Choirweb::Site.new

map '/editor' do
    run the_editor
end

map '/' do
    run the_site
end
