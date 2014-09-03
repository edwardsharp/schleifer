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
    LOCALVIDEOLISTTITLE = ["Marvin Minsky on Consciousness"]
    NOWPLAYINGTAG = "nowPlaying"

    VIDEOLISTTAG = "videoList" 
    #CURRENTTIMETAG = "currentTime"
    #CLIENTCLOUNTTAG = "clientCount"

    def initialize(app)
      @app     = app
      @clients = []
      uri = URI.parse(ENV["REDISTOGO_URL"])
      @redis = Redis.new(host: uri.host, port: uri.port, password: uri.password)
      
      #check that redis has something in it...

      if @redis.get(VIDEOLISTTAG).nil?
        if @redis.get(NOWPLAYINGTAG).nil? or @redis.get(NOWPLAYINGTAG) == ""
          @redis.set(NOWPLAYINGTAG, LOCALVIDEOLIST[0])
          @redis.set(VIDEOLISTTAG, { LOCALVIDEOLIST[0] => LOCALVIDEOLISTTITLE[0] }.to_json )
        else
          @redis.set(VIDEOLISTTAG, { @redis.get(NOWPLAYINGTAG) => '' }.to_json )
        end

      end

      Thread.new do
        redis_sub = Redis.new(host: uri.host, port: uri.port, password: uri.password)
        redis_sub.subscribe(CHANNEL) do |on|
          on.message do |channel, msg|
            #puts "on.message msg: #{msg}"
            @clients.each {|ws| ws.send(msg) }
            #p "done sending to all clients msg:#{msg.to_json}"
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
            unless(@redis.get(VIDEOLISTTAG).empty?)
              mJSON["playlist"] = JSON.parse(@redis.get(VIDEOLISTTAG))
            end
            @redis.publish(CHANNEL, mJSON.to_json)
            p [:OPENmJSONafterPub, mJSON]
          rescue
            p "RESCUE CLIENT COUNT PUBLISH!!"
          end

        end

        ws.on :message do |event|
          p [:message, event.data]

          begin
            eventData = JSON.parse(event.data)
            mNowPlaying = eventData["videoid"]
            mVideoTitle = eventData["videoTitle"]
            if mNowPlaying and mNowPlaying != ""
              @redis.set NOWPLAYINGTAG, mNowPlaying
              p "GOT (AND @redis.set) VIDEOID: #{mNowPlaying}"

              if(eventData["action"] == "client_onPlayerStateChange_1")
                if(@redis.get(VIDEOLISTTAG).empty?)
                  mVideoList = { mNowPlaying => mVideoTitle }
                else
                  mVideoList = JSON.parse(@redis.get(VIDEOLISTTAG))
                  if(mVideoList.count > 10)
                    #keep list from getting too long...
                    mVideoList.delete(mVideoList.first[0])
                  end
                  unless mVideoList.include? mNowPlaying
                    mVideoList[mNowPlaying] = mVideoTitle
                  end 
                end
      
                @redis.set VIDEOLISTTAG, mVideoList.to_json
                p "DONE SETTING VIDEOLISTTAG:#{VIDEOLISTTAG} mVideoList.to_json: #{mVideoList.to_json}"
              end
            end
          rescue 
            p "CAUGHT EXCEPTION ws.on :message!! (probably JSON.parse error"
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
              @redis.publish(CHANNEL, mJSON.to_json)
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
