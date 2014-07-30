require 'sinatra/base'

module Schleifer
  class App < Sinatra::Base
    get "/" do
      erb :"index.html"
    end
  end
end
