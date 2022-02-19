# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'erb'
require 'json'
require 'pg'

connection = PG::Connection.new(host: 'localhost', dbname: 'memo')
connection.exec('CREATE TABLE IF NOT EXISTS memos (
  id serial primary key,
  title varchar(20),
  content varchar(200),
  timestamp timestamp)')

helpers do
  include ERB::Util
end

get '/new' do
  erb :new
end

get '/memos' do
  @results = connection.exec('SELECT * FROM memos ORDER BY id DESC')
  erb :memos
end

post '/memos' do
  title = params[:title]
  content = params[:content]
  results =
    connection.exec(
      'INSERT INTO memos (title, content, timestamp) VALUES ($1, $2, current_timestamp)RETURNING id', [title, content]
    )
  results.each do |result|
    @id = result['id']
  end
  redirect to("/memos/#{@id}")
end

get '/memos/:id' do |id|
  @results = connection.exec("SELECT * FROM memos WHERE id=#{id}")
  @results.each do |result|
    @title = result['title']
    @content = result['content']
  end
  erb :memo
end

delete '/memos/:id' do |id|
  connection.exec("DELETE FROM memos WHERE id=#{id}")
  redirect to('/memos')
end

get '/memos/:id/edit' do |id|
  @results = connection.exec("SELECT * FROM memos WHERE id=#{id}")
  @results.each do |result|
    @title = result['title']
    @content = result['content']
  end
  erb :edit
end

patch '/memos/:id' do |id|
  title = params[:title]
  content = params[:content]
  connection.exec("UPDATE memos SET title = $1, content = $2 WHERE id = #{id}", [title, content])
  redirect to("/memos/#{id}")
end

not_found do
  erb :not_found
end
