require 'faye/websocket'
require 'thread'
require 'redis'
require 'json'

module Schleifer
  class SockBackend
    KEEPALIVE_TIME = 15 # in seconds
    CHANNEL        = "burgers-in-atlanta"
    LOCALCHANNEL = "lobby0"
    localvideolist = ["SNWVvZi3HX8", "s4ole_bRTdw", "_EjBtH2JFjw", "6ZG_GYNhgyI", "E5Fk32OwdbM", "KIIpRzUsIrU", "Gw0JKbnXeCM", "81SM6UFEMo4", "MwlU824cS4s"];
    nowPlaying = "MwlU824cS4s"
    currentTime = "0"

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

          # begin
          #   mPlaylist = {}
          #   #JSON.parse() needed?
          #   mPlaylist[LOCALCHANNEL] = @redis.get LOCALCHANNEL
          #   @redis.publish CHANNEL, mPlaylist.to_json
          # rescue
          #   p "RESCUE REDIS GET WITH: #{LOCALCHANNEL} !"
          # end
          #LOCALCHANNEL

          #nowPlaying & currentTime

        end

        ws.on :message do |event|
          p [:message, event.data]


          # begin #LOCALCHANNEL
          #   if(event.data["videoid"])
          #     localvideolist.push(event.data.videoid) unless localvideolist.include?(event.data.videoid)
              
          #     @redis.set LOCALCHANNEL, localvideolist
          #     # mPlaylist = {}
          #     # mPlaylist[LOCALCHANNEL] = localvideolist
          #     # @redis.publish(CHANNEL, mPlaylist)
          #   end
          # rescue
          #   p "RESCUE REDIS SET TO LOCALCHANNEL: #{LOCALCHANNEL} & localvideolist: #{localvideolist} !!!"
          # end #LOCALCHANNEL

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
