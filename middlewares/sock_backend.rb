require 'faye/websocket'
require 'thread'
require 'redis'
require 'json'

# globalz!
$localvideolist       = []
$nowPlaying           = ""
$currentTime          = "0" 
$currentClientCount   = 0

module Schleifer
  class SockBackend
    KEEPALIVE_TIME    = 15 # in seconds
    CHANNEL           = "burgers-in-atlanta"
    LOCALCHANNEL      = "lobby0"
    DEFAULTNOWPLAYING = "SNWVvZi3HX8"
    LOCALVIDEOLISTTAG = "localvideolist"
    NOWPLAYINGTAG     = "nowPlaying"
    DEFAULTVIDEOLIST  = ["SNWVvZi3HX8", "s4ole_bRTdw", "_EjBtH2JFjw", "6ZG_GYNhgyI", "E5Fk32OwdbM", "KIIpRzUsIrU", "Gw0JKbnXeCM", "81SM6UFEMo4", "MwlU824cS4s"];


    def initialize(app)
      @app      = app
      @clients  = []
      uri       = URI.parse(ENV["REDISTOGO_URL"])
      @redis    = Redis.new(host: uri.host, port: uri.port, password: uri.password)
      
      #TODO: handle init of localplaylist via redis?
      #@redis.set LOCALVIDEOLISTTAG, localvideolist

      if @redis.get(NOWPLAYINGTAG).nil?
        $nowPlaying = DEFAULTNOWPLAYING
        @redis.set NOWPLAYINGTAG, DEFAULTNOWPLAYING
      end
      

      #TODO: multichannel
      Thread.new do
        redis_sub = Redis.new(host: uri.host, port: uri.port, password: uri.password)
        redis_sub.subscribe(CHANNEL) do |on|
          on.message do |channel, msg|
            puts "INIT!!! on.message msg: #{msg}"
            
            #hmm, does the default videoid need to be injected here? can be handled on client side easily enough...
            @clients.each {|ws| ws.send(msg) }
            

          end
        end
      end
    end

    def getNowPlayingOrDefaultVideoID
      #@redis.set LOCALVIDEOLISTTAG, localvideolist
      mNowPlaying = @redis.get NOWPLAYINGTAG
      if mNowPlaying.nil?
        $nowPlaying = DEFAULTNOWPLAYING
        @redis.set NOWPLAYINGTAG, DEFAULTNOWPLAYING
      end
      return $nowPlaying
    end

    def setNowPlaying(vidId)
      if vidId == ""
        vidId = DEFAULTNOWPLAYING
      end
      @redis.set NOWPLAYINGTAG, vidId 
      $nowPlaying = vidId
    end

    def call(env)
      if Faye::WebSocket.websocket?(env)
        ws = Faye::WebSocket.new(env, nil, {ping: KEEPALIVE_TIME })
        ws.on :open do |event|
          p [:open, ws.object_id]
          @clients << ws

          begin
            $currentClientCount = @clients.count
            mJSON = {}
            mJSON["clients"] = $currentClientCount.to_s
            
            #inject the currently set video id. 
            mJSON["videoid"] = getNowPlayingOrDefaultVideoID

            #TODO: inject the list
            p [:message, mJSON]

            @redis.publish(CHANNEL, mJSON.to_json)
          rescue
            p "RESCUE CLIENT AND getNowPlayingOrDefaultVideoID COUNT!!"
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
          shouldPub = false
          # check if the videoid in the message from the client is the same as the one in REDIS
          #TODO: use a standard enum of tagz for event data keyz... 
          mNowPlaying = event.data["videoid"]
          if( mNowPlaying != getNowPlayingOrDefaultVideoID )
            #if it is not the same set it so it gets passed onto current & future clients
            setNowPlaying mNowPlaying
            event.data["videoid"] = mNowPlaying
            shouldPub = true
          end


          mClientCount = event.data["clients"]
          if( mClients != $currentClientCount )
            #some other client has con/dis-connected, publish the message to all
            shouldPub = true
          end

          if shouldPub
            @redis.publish(CHANNEL, event.data)
          end
          
          

          # begin #LOCALCHANNEL
          #   if(event.data["videoid"])
          #     localvideolist.push(event.data.videoid) unless localvideolist.include?(event.data.videoid)
              
          #     @redis.set 
          #     # mPlaylist = {}
          #     # mPlaylist[LOCALCHANNEL] = localvideolist
          #     # @redis.publish(CHANNEL, mPlaylist)
          #   end
          # rescue
          #   p "RESCUE REDIS SET TO LOCALCHANNEL: #{LOCALCHANNEL} & localvideolist: #{localvideolist} !!!"
          # end #LOCALCHANNEL

          #@redis.set LOCALVIDEOLISTTAG, localvideolist
          #@redis.set NOWPLAYINGTAG, nowPlaying


          #COPY OF A COPY (of a copy)
          # a_new_hash = my_hash.inject({}) { |h, (k, v)| h[k] = v.upcase; h }

          

        end

        ws.on :close do |event|
          p [:close, ws.object_id, event.code, event.reason]

          begin
            $currentClientCount =  @clients.count
            if($currentClientCount > 0)
              mClients = {}
              mClients["clients"] = ($currentClientCount-1).to_s
              #TODO: also send out an updated playlist without the users video ids??

              p [:message, mClients]
              @redis.publish(CHANNEL, mClients.to_json)
            else 
              nobodySeemsHere
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

    def nobodySeemshere
      $nowPlaying = ""
      #$localvideolist = []
      $currentClientCount = 0
    end

  end
end
