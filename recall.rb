require 'sinatra'
require 'data_mapper'
require 'sinatra/flash'
require 'sinatra/redirect_with_flash'

SITE_TITLE = "Recall"
SITE_DESCRIPTION = "'cause you're too busy to remember"

enable :sessions

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/recall.db")

# describes the schema of the DB
class Note
	include DataMapper::Resource
	property :id, Serial
	property :content, Text, :required => true
	property :complete, Boolean, :required => true, :default => false
	property :created_at, DateTime
	property :updated_at, DateTime
end

# update schema when we change the schema above
DataMapper.finalize.auto_upgrade!

helpers do
	include Rack::Utils
	alias_method :h, :escape_html
end

get '/rss.xml' do
	@notes = Note.all :order => :id.desc
	builder :rss
end

get '/' do
	@notes = Note.all :order => :id.desc
	@title = 'All Notes'
	if @notes.empty?
		flash[:error] = 'No notes found. Add your first below.'
	end
	erb :home
end

post '/' do
	n = Note.new
	n.content = params[:content]
	n.created_at = Time.now
	n.updated_at = Time.now
	if n.save
		redirect '/', :notice => 'Note created successfully.'
	else 
		redirect '/', :error => 'Failed to save note.'
	end
end

get '/:id' do
	@note = Note.get params[:id]
	@title = "Edit note ##{params[:id]}"
	if @note 
		erb :edit
	else 
		redirect '/', :error => "Can't find that note."
	end
end

put '/:id' do
	n = Note.get params[:id]
	unless n 
		redirect '/', :error => "Can't find that note."
	end
	n.content = params[:content]
	# set n.complete to 1 if params[:complete] exists, else 0
	# basically checks for the existence of a check mark
	n.complete = params[:complete] ? 1 : 0
	n.updated_at = Time.now
	if n.save
		redirect '/', :notice => 'Note updated successfully.'
	else
		redirect '/', :error => 'Error updating note.'
	end
end

get '/:id/delete' do
	@note = Note.get params[:id]
	@title = "Confirm deletion of note ##{params[:id]}"
	if @note
		erb :delete
	else
		redirect '/', :error => "Can't find that note."
	end
end

delete '/:id' do
	n = Note.get params[:id]
	if n.destroy
		redirect '/', :notice => 'Note deleted successfully.'
	else
		redirect '/', :notice => 'Error deleting note.'
	end
end

get '/:id/complete' do
	n = Note.get params[:id]
	unless n
		redirect '/', :error => "Can't find that note."
	end
	n.complete = n.complete ? 0:1 
	n.updated_at = Time.now
	if n.save
		redirect '/', :notice => 'Note marked as complete.'
	else
		redirect '/', :error => 'Error marking note as complete.'
	end
end

