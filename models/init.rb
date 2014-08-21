# encoding: utf-8
# require 'active_record'
# require 'bson'
require 'mongoid'
require 'protected_attributes'
require 'moped'
require 'icalendar'
require 'open-uri'
require 'nokogiri'
require 'bcrypt'

# dir_config = Pathname.getwd
# puts dir_config

# ActiveRecord::Base.establish_connection(YAML::load(File.read(File.dirname(__FILE__) + '/../config/activerecord.yaml'))
Mongoid.load!(File.dirname(__FILE__) + '/../config/mongoid.yaml')

require_relative 'mongoid'
# require_relative 'activerecord'


