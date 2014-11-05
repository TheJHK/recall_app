require 'sinatra'
require 'datamapper'

Datamapper::setup(:default, "sqlite3://#{Dir.pwd}/recall.db")