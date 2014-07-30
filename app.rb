require 'sinatra/base'

module SockDemo
  class App < Sinatra::Base
    get "/" do
      erb :"index.html"
    end
  end
end
