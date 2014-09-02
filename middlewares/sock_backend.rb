require 'faye/websocket'
require 'thread'
require 'redis'
require 'json'
require 'erb'

module Schleifer
  class SockBackend
    # globalz!
    $localvideolist       = []
    $nowPlaying           = ""
    $currentTime          = "0" 
    $currentClientCount   = 0
    $DEFAULTNOWPLAYING    = "SNWVvZi3HX8"
    $LOCALVIDEOLISTTAG    = "localvideolist"
    $NOWPLAYINGTAG        = "nowPlaying"
    $DEFAULTVIDEOLIST     = ["SNWVvZi3HX8", "s4ole_bRTdw", "_EjBtH2JFjw", "6ZG_GYNhgyI", "E5Fk32OwdbM", "KIIpRzUsIrU", "Gw0JKbnXeCM", "81SM6UFEMo4", "MwlU824cS4s"];

    KEEPALIVE_TIME    = 15 # in seconds
    CHANNEL           = "burgers-in-atlanta"
    LOCALCHANNEL      = "lobby0"
    
    

    def initialize(app)
      @app      = app
      @clients  = []
      uri       = URI.parse(ENV["REDISTOGO_URL"])
      @redis    = Redis.new(host: uri.host, port: uri.port, password: uri.password)

      #TODO: multichannel
      Thread.new do
        redis_sub = Redis.new(host: uri.host, port: uri.port, password: uri.password)
        redis_sub.subscribe(CHANNEL) do |on|
          on.message do |channel, msg|
            puts "INIT Thread.new!!! on.message! will send msg: #{msg}"
            #hmm, does the default videoid need to be injected here? can be handled on client side easily enough...  
            @clients.each {|ws| ws.send(msg) }
          end #end on.message
        end #end redis.sub
      end #end Thread.new
    end #end init

    def call(env)
      if Faye::WebSocket.websocket?(env)
        ws = Faye::WebSocket.new(env, nil, {ping: KEEPALIVE_TIME })
        ws.on :open do |event|
          p [:open, ws.object_id]
          
          # begin
          $currentClientCount = @clients.count
          mJSON = {}
          mJSON["clients"] = $currentClientCount.to_s
          mJSON["videoid"] = getNowPlayingOrDefaultVideoId
          #TODO: inject the list
          @redis.publish(CHANNEL, mJSON.to_json)
          puts "JUST @redis.publish'd!!!!!"
          p [:mJSON, mJSON]
          # rescue
          #   p "RESCUE CLIENT AND setNowPlayingOrDefaultVideoID COUNT!!"
          # end
          @clients << ws
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
          p [:doneOpen, "done with open event!!"]
        end #end ws.on

        ws.on :message do |event|
          p [:event_data, event.data]
          # shouldPub = false
          # check if the videoid in the message from the client is the same as the one in REDIS
          #TODO: use a standard enum of tagz for event data keyz... 


          # mClientCount = event.data["clients"]
          # if( mClients != $currentClientCount )
          #   #some other client has con/dis-connected, publish the message to all
          #   
          # end

          @redis.publish(CHANNEL, sanitize(event.data))

        end #end ws.on :message

        ws.on :close do |event|
          p [:close, ws.object_id, event.code, event.reason]

          # begin
          $currentClientCount =  @clients.count
          if($currentClientCount > 0)
            mClients = {}
            mClients["clients"] = ($currentClientCount-1).to_s
            #TODO: also send out an updated playlist without the users video ids??

            p [:close_message, mClients]
            @redis.publish(CHANNEL, sanitize(mClients.to_json))
          else 
            nobodySeemsHere
          end
          # rescue
          #   p "RESCUE CLIENT CLOSE COUNT"
          # end

          @clients.delete(ws)
          ws = nil
        end #end ws.on :close

        # Return async Rack response
        ws.rack_response

      else
        @app.call(env)
        


      end #end if Faye::WebSocket.websocket?(env) // else
    end #end call

    private
    def sanitize(message)
      json = JSON.parse(message)
      json.each {|key, value| json[key] = ERB::Util.html_escape(value) }
      JSON.generate(json)
    end

    def nobodySeemshere
      $nowPlaying = ""
      #$localvideolist = []
      $currentClientCount = 0
    end #end nobodySeemshere

  end #end class 
end #end module
