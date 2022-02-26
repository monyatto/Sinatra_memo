# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'erb'
require 'pg'

connection = PG::Connection.new(host: 'localhost', dbname: 'memo')
connection.exec('CREATE TABLE IF NOT EXISTS memos (
  id serial primary key,
  title varchar(20),
  content varchar(200),
  timestamp timestamp)')

helpers do
  include ERB::Util

  def sanitize(text)
    escape_html(text)
  end
end

get '/new' do
  erb :new
end

get '/memos' do
  @memos = connection.exec('SELECT * FROM memos ORDER BY id DESC')
  erb :memos
end

post '/memos' do
  title = params[:title]
  content = params[:content]
  memos =
    connection.exec(
      'INSERT INTO memos (title, content, timestamp) VALUES ($1, $2, current_timestamp)RETURNING id', [title, content]
    )
  memos.each do |result|
    @id = result['id']
  end
  redirect to("/memos/#{@id}")
end

get '/memos/:id' do |id|
  @memos = connection.exec('SELECT * FROM memos WHERE id = $1', [id.to_i])
  if @memos.first.nil?
    erb :not_found
  else
    @title = sanitize(@memos.first['title'])
    @content = sanitize(@memos.first['content'])
    erb :memo
  end
end

delete '/memos/:id' do |id|
  connection.exec('DELETE FROM memos WHERE id = $1', [id])
  redirect to('/memos')
end

get '/memos/:id/edit' do |id|
  @memos = connection.exec('SELECT * FROM memos WHERE id = $1', [id.to_i])
  if @memos.first.nil?
    erb :not_found
  else
    @title = sanitize(@memos.first['title'])
    @content = sanitize(@memos.first['content'])
    erb :edit
  end
end

patch '/memos/:id' do |id|
  title = params[:title]
  content = params[:content]
  connection.exec('UPDATE memos SET title = $1, content = $2 WHERE id = $3', [title, content, id])
  redirect to("/memos/#{id}")
end

not_found do
  erb :not_found
end
