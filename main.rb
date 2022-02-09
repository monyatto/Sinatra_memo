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
    Dir.glob('*', base: './data').map do |file_name|
      File.open("./data/#{file_name}") do |file|
        JSON.parse(file.read, symbolize_names: true)
      end
    end
  end

  def sort_files(files)
    files.sort do |a, b|
      [a[:time]] <=> [b[:time]]
    end
    files.reverse
  end
end

get '/new' do
  erb :new
end

get '/memos' do
  @memos = sort_files(parse_json)
  erb :memos
end

post '/memos' do
  @id = SecureRandom.uuid
  @title = params[:title]
  @content = params[:content]
  hash = { id: @id, time: Time.new, title: @title, content: @content }
  File.open("./data/#{hash[:id]}", 'w') do |file|
    JSON.dump(hash, file)
  end
  redirect to("/memos/#{@id}")
end

get '/memos/:id' do |id|
  json_file = JSON.parse(File.open("./data/#{id}").read, symbolize_names: true)
  @title = sanitize(json_file[:title])
  @content = sanitize(json_file[:content])
  erb :memo
end

delete '/memos/:id' do
  File.delete("data/#{params[:id]}")
  redirect to('/memos')
end

get '/memos/:id/edit' do |id|
  json_file = JSON.parse(File.open("./data/#{id}").read, symbolize_names: true)
  @title = sanitize(json_file[:title])
  @content = sanitize(json_file[:content])
  erb :edit
end

patch '/memos/:id/edit' do |id|
  json_file = JSON.parse(File.open("./data/#{id}").read, symbolize_names: true)
  @time = json_file[:time]
  @title = params[:title]
  @content = params[:content]

  hash = { id: params[:id], time: @time, title: @title, content: @content }
  File.open("./data/#{params[:id]}", 'w') do |file|
    JSON.dump(hash, file)
  end
  redirect to("/memos/#{id}")
end

not_found do
  erb :not_found
end
