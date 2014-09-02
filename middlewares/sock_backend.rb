require 'faye/websocket'
require 'thread'
require 'redis'
require 'json'

# globalz!
$localvideolist       = []
$nowPlaying           = ""
$currentTime          = "0" 
$currentClientCount   = 0
$DEFAULTNOWPLAYING    = "SNWVvZi3HX8"
$LOCALVIDEOLISTTAG    = "localvideolist"
$NOWPLAYINGTAG        = "nowPlaying"
$DEFAULTVIDEOLIST     = ["SNWVvZi3HX8", "s4ole_bRTdw", "_EjBtH2JFjw", "6ZG_GYNhgyI", "E5Fk32OwdbM", "KIIpRzUsIrU", "Gw0JKbnXeCM", "81SM6UFEMo4", "MwlU824cS4s"];


module Schleifer
  class SockBackend
    KEEPALIVE_TIME    = 15 # in seconds
    CHANNEL           = "burgers-in-atlanta"
    LOCALCHANNEL      = "lobby0"
    
    

    def initialize(app)
      @app      = app
      @clients  = []
      uri       = URI.parse(ENV["REDISTOGO_URL"])
      @redis    = Redis.new(host: uri.host, port: uri.port, password: uri.password)
      
      #TODO: handle init of localplaylist via redis?
      #@redis.set $LOCALVIDEOLISTTAG, localvideolist

      

      #TODO: multichannel
      Thread.new do
        @redis.subscribe(CHANNEL) do |on|
          on.message do |channel, msg|
            puts "INIT!!! on.message msg: #{msg}"
            
            # p "init about to setNowPlayingOrDefaultVideoID!!!"
            # setNowPlayingOrDefaultVideoID

            # parseAndSetNowPlaying(msg)

            # if msg == "videoid"
            #   msg = $DEFAULTNOWPLAYING
            # end
            
            #hmm, does the default videoid need to be injected here? can be handled on client side easily enough...  
            @clients.each {|ws| ws.send(msg) }
       
          end
        end
      end
    end

    def setNowPlayingOrDefaultVideoID
      mNowPlaying = @redis.get($NOWPLAYINGTAG)
      #accounding for weirdness with sometimes getting the literal string "videoid" set, oh ruby...
      if mNowPlaying.nil? or mNowPlaying.empty? or mNowPlaying == "" or mNowPlaying = "videoid"
        $nowPlaying = $DEFAULTNOWPLAYING
        p "___ REDIS IS GOING TO SET $NOWPLAYINGTAG:#{$NOWPLAYINGTAG} $DEFAULTNOWPLAYING:#{$DEFAULTNOWPLAYING}"
        @redis.set $NOWPLAYINGTAG, $DEFAULTNOWPLAYING
      elsif mNowPlaying != $nowPlaying
        $nowPlaying = mNowPlaying                
        p "___ ELSE REDIS IS GOING TO SET $NOWPLAYINGTAG:#{$NOWPLAYINGTAG} $nowPlaying:#{$nowPlaying}"
        @redis.set $NOWPLAYINGTAG, $nowPlaying 
      end
      p "setNowPlayingOrDefaultVideoID $nowPlaying: #{$nowPlaying}"
    end

    def parseAndSetNowPlaying(data)
      p "parseAndsetNowPlaying GOT data:#{data}"
      # if( JSON.parse(data)["videoid"] != $nowPlaying )
      #   #if it is not the same set it so it gets passed onto current & future clients
      #   $nowPlaying = JSON.parse(data)["videoid"]
      #   @redis.set $NOWPLAYINGTAG, $nowPlaying 
      #   # @redis.publish(CHANNEL, mNowPlaying)
      #   # & PUBLISHING!!
      #   p "DONE SETTING!"
      # else
      #   p "NOT GONNA SET NOW PLAYING (seems to be the same)"
      # end
    end

    def call(env)
      if Faye::WebSocket.websocket?(env)
        ws = Faye::WebSocket.new(env, nil, {ping: KEEPALIVE_TIME })
        ws.on :open do |event|
          p [:open, ws.object_id]
          @clients << ws

          # begin
            $currentClientCount = @clients.count
            mJSON = {}
            mJSON["clients"] = $currentClientCount.to_s
            
            
            p "about to setNowPlayingOrDefaultVideoID!!"
            # setNowPlayingOrDefaultVideoID

            #inject the currently set video id. 
            # setNowPlayingOrDefaultVideoID
            # mJSON["videoid"] = $nowPlaying


            #TODO: inject the list
            @redis.publish(CHANNEL, mJSON.to_json)
            
            puts "JUST @redis.publish'd!!!!!"
            p [:mJSON, mJSON]

          # rescue
          #   p "RESCUE CLIENT AND setNowPlayingOrDefaultVideoID COUNT!!"
          # end

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
          p [:event_data, event.data]
          # shouldPub = false
          # check if the videoid in the message from the client is the same as the one in REDIS
          #TODO: use a standard enum of tagz for event data keyz... 
          
          # try{

          #   }catch(){

          #   }
          # parseAndSetNowPlaying(event.data)


          # mClientCount = event.data["clients"]
          # if( mClients != $currentClientCount )
          #   #some other client has con/dis-connected, publish the message to all
          #   @redis.publish(CHANNEL, event.data)
          # end

     

        end

        ws.on :close do |event|
          p [:close, ws.object_id, event.code, event.reason]

          # begin
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
          # rescue
          #   p "RESCUE CLIENT CLOSE COUNT"
          # end

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
