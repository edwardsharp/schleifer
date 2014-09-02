require 'faye/websocket'
require 'thread'
require 'redis'
require 'json'

module Schleifer
  class SockBackend
    KEEPALIVE_TIME = 15 # in seconds
    CHANNEL        = "chimmy-jimmy"
    LOCALCHANNEL = "lobby0"
    LOCALVIDEOLIST = ["SNWVvZi3HX8", "s4ole_bRTdw", "_EjBtH2JFjw", "6ZG_GYNhgyI", "E5Fk32OwdbM", "KIIpRzUsIrU", "Gw0JKbnXeCM", "81SM6UFEMo4", "MwlU824cS4s"];
    NOWPLAYINGTAG = "nowPlaying"
    
    #LOCALVIDEOLISTTAG = "localVideoList" 
    #CURRENTTIMETAG = "currentTime"
    #CLIENTCLOUNTTAG = "clientCount"

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
            msg["clientCount"] = @clients.count.to_s
            mNowPlaying = redis_sub.get NOWPLAYINGTAG
            if mNowPlaying != nil and mNowPlaying != ""
              msg["videoid"] = mNowPlaying
            else
              redis_sub.set NOWPLAYINGTAG, LOCALVIDEOLIST[0]
              msg["videoid"] = LOCALVIDEOLIST[0]
            end

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
            mJSON = {}
            mJSON["clients"] = @clients.count.to_s
            mJSON["videoid"] = @redis.get NOWPLAYINGTAG
            p [:mJSON, mJSON]
            @redis.publish(CHANNEL, mJSON.to_json)
          rescue
            p "RESCUE CLIENT COUNT PUBLISH!!"
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

          #NOWPLAYING & CURRENTTIMETAG

        end

        ws.on :message do |event|
          p [:message, event.data]


          # begin #LOCALCHANNEL
          #   if(event.data["videoid"])
          #     LOCALVIDEOLIST.push(event.data.videoid) unless LOCALVIDEOLIST.include?(event.data.videoid)
              
          #     @redis.set LOCALCHANNEL, LOCALVIDEOLIST
          #     # mPlaylist = {}
          #     # mPlaylist[LOCALCHANNEL] = LOCALVIDEOLIST
          #     # @redis.publish(CHANNEL, mPlaylist)
          #   end
          # rescue
          #   p "RESCUE REDIS SET TO LOCALCHANNEL: #{LOCALCHANNEL} & LOCALVIDEOLIST: #{LOCALVIDEOLIST} !!!"
          # end #LOCALCHANNEL

          @redis.publish(CHANNEL, event.data)

        end

        ws.on :close do |event|
          p [:close, ws.object_id, event.code, event.reason]

          begin
            if(@clients.count > 0)
              mJSON = {}
              mJSON["clients"] = (@clients.count-1).to_s
              p [:message, mJSON]
              @redis.publish(CHANNEL, mJSON.to_json)
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
