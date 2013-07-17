require "bundler"
Bundler.require(:default)
require 'celluloid/autostart'
require  "data_mapper"
require  "securerandom"
require  "timeout"
require_relative "lib/all"
require_relative "lib/app/royageur_web"
Typhoeus::USER_AGENT = "#{Royageur::USER_AGENT}/#{Royageur::VERSION}"

DataMapper.setup(:default, "sqlite://#{Dir.pwd}/db/royageur.db")
DataMapper.finalize
DataMapper.auto_upgrade!

Royageur::Web.run!