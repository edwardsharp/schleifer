require 'faye/websocket'
require 'thread'
require 'redis'
require 'json'

module Schleifer
  class SockBackend
    KEEPALIVE_TIME = 15 # in seconds
    CHANNEL        = "burgers-in-atlanta"
    LOCALCHANNEL = "lobby0"
 

    def initialize(app)
      @app     = app
      @clients = []
      uri = URI.parse(ENV["REDISTOGO_URL"])
      @redis = Redis.new(host: uri.host, port: uri.port, password: uri.password)
      Thread.new do
        redis_sub = Redis.new(host: uri.host, port: uri.port, password: uri.password)
        redis_sub.subscribe(CHANNEL) do |on|
          on.message do |channel, msg|
            puts "on.message msg: #{msg}"
            


            @clients.each {|ws| ws.send(msg) }

          end
        end
      end
    end

    def call(env)
      if Faye::WebSocket.websocket?(env)
        ws = Faye::WebSocket.new(env, nil, {ping: KEEPALIVE_TIME })
        ws.on :open do |event|
          p [:open, ws.object_id]
          @clients << ws

          begin
            mClients = {}
            mClients["clients"] = @clients.count.to_s
            p [:message, mClients]
            @redis.publish(CHANNEL, mClients.to_json)
          rescue
            p "RESCUE CLIENT COUNT"
          end

          begin
            mPlaylist = {}
            #JSON.parse() needed?
            mPlaylist[LOCALCHANNEL] = @redis.get LOCALCHANNEL
            @redis.publish CHANNEL, mPlaylist.to_json
          rescue
            p "RESCUE REDIS GET WITH: #{LOCALCHANNEL} !"
          end
          #LOCALCHANNEL

        end

        ws.on :message do |event|
          p [:message, event.data]


          begin #LOCALCHANNEL
            mPlaylist = {}
            mPlaylist[LOCALCHANNEL] = event.data
            @redis.set LOCALCHANNEL, mPlaylist
            @redis.publish(CHANNEL, mPlaylist)
          rescue
            p "RESCUE REDIS SET & PUB TO #{LOCALCHANNEL} & #{CHANNEL} !!!"
          end #LOCALCHANNEL

          @redis.publish(CHANNEL, event.data)

        end

        ws.on :close do |event|
          p [:close, ws.object_id, event.code, event.reason]

          begin
            if(@clients.count > 0)
              mClients = {}
              mClients["clients"] = (@clients.count-1).to_s
              p [:message, mClients]
              @redis.publish(CHANNEL, mClients.to_json)
            end
          rescue
            p "RESCUE CLIENT CLOSE COUNT"
          end

          @clients.delete(ws)
          ws = nil
        end

        # Return async Rack response
        ws.rack_response

      else
        @app.call(env)
        


      end
    end
  end
end
