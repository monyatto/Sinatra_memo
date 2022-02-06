# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'erb'
require 'json'

helpers do
  include ERB::Util

  def sanitize(text)
    escape_html(text)
  end

  def parse_json
    json_files = []
    Dir.glob('*', base: './data').each do |file_name|
      File.open("./data/#{file_name}") do |file|
        json_files << JSON.parse(file.read)
      end
    end
    json_files = json_files.sort do |a, b|
      [a['time']] <=> [b['time']]
    end
    json_files.reverse!
  end
end

get '/new' do
  erb :new
end

get '/memos' do
  json_files = parse_json

  @title_list = []
  @id_list = []

  json_files.each do |file|
    @title_list << file['title']
    @id_list << file['id']
  end
  erb :memos
end

post '/memos' do
  @id = SecureRandom.uuid
  @title = params[:title]
  @content = params[:content]
  hash = { 'id' => @id, 'time' => Time.new, 'title' => @title, 'content' => @content }
  File.open("./data/#{hash['id']}", 'w') do |file|
    JSON.dump(hash, file)
  end
  redirect to("/memos/#{@id}")
end

get '/result' do
  json_files = parse_json
  @title_list = []
  @content_list = []

  json_files.each do |file|
    @title_list << file['title']
    @content_list << file['content']
  end

  @title = @title_list[0]
  @content = @content_list[0]
  erb :result
end

get '/memos/:id' do |id|
  @title = sanitize(JSON.parse(File.open("./data/#{id}").read)['title'])
  @content = sanitize(JSON.parse(File.open("./data/#{id}").read)['content'])
  erb :memo
end

delete '/memos/:id' do
  File.delete("data/#{params['id']}")
  redirect to('/memos')
end

get '/edit/:id' do |id|
  @title = sanitize(JSON.parse(File.open("./data/#{id}").read)['title'])
  @content = sanitize(JSON.parse(File.open("./data/#{id}").read)['content'])
  erb :edit
end

patch '/edit/:id' do |id|
  @time = JSON.parse(File.open("./data/#{id}"))['time']
  @title = params[:title]
  @content = params[:content]
  hash = { 'id' => params['id'], 'time' => @time, 'title' => @title, 'content' => @content }
  File.open("./data/#{params['id']}", 'w') do |file|
    JSON.dump(hash, file)
  end
  redirect to("/memos/#{id}")
end

not_found do
  erb :not_found
end

def memo
  Memo.new
end
