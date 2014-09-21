require 'bundler/setup'
require 'sinatra/base'
require 'sinatra/flash'
require 'digest/md5'
require 'rack/recaptcha'
require 'mail'
require 'pg'
require './database'
require './app'
require './editor'


THE_DB = Cruby::Database.new

realms = THE_DB.get_system_config 'REALM'
realm = realms.count > 0 ? realms[0]['config_string'] : nil

opaques = THE_DB.get_system_config 'OPAQUE'
opaque = opaques.count > 0 ? opaques[0]['config_string'] : nil

the_editor = Rack::Auth::Digest::MD5.new(Cruby::Editor, realm, opaque) do |name|
    users = THE_DB.get_user(name)
    pwh = users.count > 0 ? users[0]['password_hash'] : nil
end
the_editor.passwords_hashed = true

the_app = Cruby::App.new

map '/editor' do
    run the_editor
end

map '/' do
    run the_app
end
