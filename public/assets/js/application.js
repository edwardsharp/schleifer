var scheme   = "ws://";
var uri      = scheme + window.document.location.host + "/";
var ws       = new WebSocket(uri);
var videoContainer = document.getElementById("videoContainer");
var channel = "lobby0";
var clients = 0;
var videoid = "";
var defaultVideoid = "MwlU824cS4s";
var videoList = [];

var myTimer;
var currTime = 0;
var actionEnum = 
  { 
   0: "onSubmit"
  ,1: "client_onPlayerStateChange_0" 
  ,2: "client_videoListItem_click"
  ,3: "client_onPlayerStateChange_1"
  };
var loggingEnabled = false;

// #PRAGMA MARK - WebSocket delegatez 
ws.onmessage = function(message) {
  var data;
  try{
    logStuff("message data,YO:"+message.data);

    data = JSON.parse(message.data);

    logStuff("data JSON parse'd,YO:"+data);

    
    // logStuff("JSON stringify,YO:"+JSON.stringify(message.data));

  //set channel-dropdown-menu li w/ data
  //  var iframeshit = "<iframe src='//www.youtube-nocookie.com/embed/v9AKH16--VE?rel=0' frameborder='0' allowfullscreen></iframe>";
  
    //increment the client count UI display (badge)

    logStuff("data.clients, YO:"+data.clients);

    if(data.clients && data.clients > 0){
      $("#currActive > .badge").html(data.clients);
      logStuff("data.clients,YO:"+data.clients);
    }

    if(data.playlist ){
      //$("#input-channel").val(data.chennel);
      logStuff("data.playlist,YO!:"+data.playlist);

      // for (var i=0; i<data.playlist.length; ++i) {
      //   logStuff("GOT PLAYLIST ID: "+ data.playlist[i]);
        
        
      // }

      for (var k in data.playlist){
        if (data.playlist.hasOwnProperty(k)) {
          logStuff("GOT PLAYLIST ID: "+k+" title:"+data.playlist[k]);
          appendToVideoList(k, data.playlist[k]);
        }
      }

    }

    logStuff("data.videoid, YO:"+data.videoid);
    //check if incoming message has a videoid parameter
    if(data.videoid && data.videoid.length < 25){
      //CHECK IF VIDEO IS ALREADY PLAING!
      logStuff("GOT data.videoid:"+data.videoid + "GONNA CHECK IF EXISTZ!");
      //is this videoid already the one that is now scheduled to be playing?
      if(videoid != data.videoid){
        //no? then update our reference. 
        videoid = data.videoid;
        showVideoByID(videoContainer, data.videoid);
        logStuff("GOT A NEW data.videoid, YO!:"+data.videoid);
      }
      
      
    }

    if(data.channel && data.channel.length > 0 && data.channel.length < 25){
      //$("#input-channel").val(data.chennel);
      logStuff("data.channel,YO!:"+data.channel);
    }

    if(data.currTime && data.currTime.length){
      //$("#input-channel").val(data.chennel);
      logStuff("data.currTime, YO!!:"+data.currTime);

    }

  }catch(e){

    logStuff("CAUGHT ERROR" + e);
  
  }
};



//# PRAGMA MARK - YouTube "mini library" starts here
var youTubeAPILoaded = false;

function loadYouTubeAPI (callBack) {
    if (!youTubeAPILoaded) {
        var tag = document.createElement('script');
        tag.src = "https://www.youtube.com/player_api";
        var firstScriptTag = document.getElementsByTagName('script')[0];
        firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
        
        window.onYouTubePlayerAPIReady = function () {
            youTubeAPILoaded = true;
            callBack();
        }
    } else {
        callBack();
    }
}

function showVideoByID (domElement, videoID) {
    if(videoID == ""){
      videoID = defaultVideoid 
    }

    if(videoid==""){
      //USING DEFAULT VIDEO ID. (nobody here?)
      videoid=defaultVideoid
    }
    

    myTimer = setInterval(setTimeTimeout, 1000);

    
    

    //push thumb
    //$("#videoL").append('<img src="http://img.youtube.com/vi/'+videoid+'/0.jpg" class="navbar-image" border="0" />');
    loadYouTubeAPI(function () {
        if (!domElement.player) {
            domElement.player = new YT.Player(domElement, {
     
                videoId     : videoid,
                playerVars: {
                    'rel'           : 0,
                    'autoplay'      : 1,
                    'loop'          : 1,
                    'playlist'      : videoid,
                    'controls'      : 0,
                    'showinfo'      : 0 ,
                    'modestbranding'  : 1,
                    'wmode'          : "opaque"
                },
                events: {
                  'onStateChange': onPlayerStateChange
                }
            });
        } else {
            //player.loadVideoById({videoId:String, startSeconds:Number, endSeconds:Number, suggestedQuality:String}):Void
            domElement.player.loadVideoById(videoid);
        }
        //nowPlaying = player;
       // currentPopup[0].previousLanguage = language
    });

    

}

function appendToVideoList(videoid, vTitle){

  vTitle = typeof vTitle !== 'undefined' ? vTitle : '';

  var mElem = $('\
        <li class="videoListItem" id="'+videoid+'" data-value="'+videoid+'"> \
          <span class="videoListThumb"><img src="http://img.youtube.com/vi/'+videoid+'/0.jpg" title="'+vTitle+'"></span> \
          <span class="desc">'+videoid+'</span> \
        </li> \
      ');

    var myID = '#' + videoid;
    try {
      if ( $( myID ).length ) {
        logStuff("VIDEO ALREADY EXISTZ IN LIST!"); 
      }else{
        //these do not get .click .on or whatever handlerz!!! ahh! 
        //TODO FIX!
        mElem.appendTo(".videoList");
      }
    }catch(e) {
      logStuff("CAUGHT LENGTH ERROR!!!"); 
    }
}

//time tracking stuff
function setTimeTimeout() {

  // if (!sessionStorage['currentVideoTime']) {
  //   //get time!?
  //   sessionStorage['currentVideoTime'] = 0;
  // } else {
  //   sessionStorage['currentVideoId']++;
  // }

  // document.querySelector('#videoListContent').innerHTML = 
  //     '<p>' + sessionStorage.getItem('currentVideoId') + ' times</p>';
  try{
    currTime = videoContainer.player.getCurrentTime();
  }catch(onoz){
    stopTimeTimeout();
    return;
  }
  
  
  var time = currTime;
  var hours = Math.floor(time / 3600);
  time -= hours * 3600;
  var minutes = Math.floor(time / 60);
  time -= minutes * 60;
  var seconds = parseInt(time % 60, 10);
  time = (hours < 1 ? '' : (hours + ':')) + (minutes < 10 ? '0' + minutes : minutes) + ':' + (seconds < 10 ? '0' + seconds : seconds);
  $("#currTime").html(time);
  
  //not just yet... work up to a time sync..
  //ws.send(JSON.stringify({ currTime: currTime }));
}



function stopTimeTimeout(){
    if (myTimer){
      logStuff("GONNA stopTimeTimeout, myTimer:"+myTimer);
      clearInterval(myTimer);
      //myTimer = null;
    }
  
}

function startTimeTimeout(){
  logStuff("GONNA startTimeTimeout, myTimer:"+myTimer);
  myTimer = setInterval(setTimeTimeout, 1000);
}
// end of "mini library"



//playlist click handlers 
//#TODO: fix this up!!


$('#vidz').on('click', '.videoListItem', function(event) {
  logStuff("GOT PLAYLIST CLICK!");
  event.preventDefault();
  videoid = $(this).data('value');
  logStuff("VIDEOID: "+videoid);
  $("#input-videoid")[0].value = videoid;
  //channel = $("#input-channel")[0].value;
  showVideoByID(videoContainer , videoid);
  //ws.send(JSON.stringify({ channel: channel, videoid: videoid, action: actionEnum[2] }));
});

        
// when video ends
function onPlayerStateChange(event) { 
  logStuff("GOT onPlayerStateChange event.data:"+event.data);  
  /*
    -1 (unstarted)
    0 (ended)
    1 (playing)
    2 (paused)
    3 (buffering)
    5 (video cued). */
  videoTitle = videoContainer.player.getVideoData().title
  if(event.data === 0) {   
    //repeat!         
    event.target.playVideo();
  }
  if(event.data === 1) {  
    logStuff("WOULD PLAY... WS SENDING!!!");        
    ws.send(JSON.stringify({ channel: channel, videoid: videoid, videoTitle: videoTitle, action: actionEnum[3]}));   
    
    $("#input-videoid")[0].value = videoid;
    
    //push onto the playlist stack
    appendToVideoList(videoid, videoTitle);

    startTimeTimeout();       
  }
  if(event.data === 2 || event.data === 3) {    
    stopTimeTimeout();
  }

}

function logStuff(what2log){
  if(loggingEnabled){
    try{
      console.log(what2log);
    }catch(e){
      //o noz!!
    }
  }
}


$(function() {
  // Handler for .ready() called.
  //INIT!!! 

  //wait for the ws callback!
  //showVideoByID(videoContainer, defaultVideoid)


  //# PRAGMA MARK - form input actionz
  $("#input-form").on("submit", function(event) {
    event.preventDefault();
    videoid   = $("#input-videoid")[0].value;
    //channel = $("#input-channel")[0].value;

    //note the double bang to coerce a boolean, then invert. clever.
    if(!!$.trim($("#input-videoid").val()).length){
      //ws.send(JSON.stringify({ handle: handle, text: text }));
      ws.send(JSON.stringify({ channel: channel, videoid: videoid, action: actionEnum[0]}));
      //$("#input-videoid")[0].value = "";
      showVideoByID(videoContainer, videoid);
    }

    
  });

  // $("#dropdown").on("change", function(event) {
  //   //event.preventDefault();
  //   logStuff($("dropdown")[0].value);
  //   //var videoid   = $("#input-videoid")[0].value;
  //   //

  //   //note the double bang to coerce a boolean, then invert. clever.
  //   // if(!!$.trim($("#input-videoid").val()).length){
  //   //   //ws.send(JSON.stringify({ handle: handle, text: text }));
  //   //   ws.send(JSON.stringify({ videoid: videoid, channel: channel }));
  //   //   $("#input-videoid")[0].value = "";
  //   // }
  // });

});

    