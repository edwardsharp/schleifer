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

            @clients.each {|ws| ws.send(msg) }

            p "done sending to all clients msg:#{msg.to_json}"
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
            @redis.publish(CHANNEL, mJSON)
            p [:OPENmJSONafterPub, mJSON]
          rescue
            p "RESCUE CLIENT COUNT PUBLISH!!"
          end

        end

        ws.on :message do |event|
          p [:message, event.data]

          if event.data["videoid"]
            p "GOT VIDEOID: #{event.data["videoid"]}"
          end
          @redis.publish(CHANNEL, event.data)
          p "DONE WITH REDIS PUBLISH IN ws.on :message CB!"
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

          

        end

        ws.on :close do |event|
          p [:close, ws.object_id, event.code, event.reason]

          begin
            if(@clients.count > 0)
              mJSON = {}
              mJSON["clients"] = (@clients.count-1).to_s
              @redis.publish(CHANNEL, mJSON)
              p [:mJSONafterPub, mJSON]
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
