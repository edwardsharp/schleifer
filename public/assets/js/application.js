var scheme   = "ws://";
var uri      = scheme + window.document.location.host + "/";
var ws       = new WebSocket(uri);
var videoContainer = document.getElementById("videoContainer");
var channel = "lobby0";
var clients = 0;
var videoid = "MwlU824cS4s";
var videoList = ["SNWVvZi3HX8", "s4ole_bRTdw", "_EjBtH2JFjw", "6ZG_GYNhgyI", "E5Fk32OwdbM", "KIIpRzUsIrU", "Gw0JKbnXeCM", "81SM6UFEMo4", "MwlU824cS4s"];
var myTimer;
var currTime = 0;

ws.onmessage = function(message) {
  var data;
  try{
    data = JSON.parse(message.data);

  //console.log("message,YO:"+message);

  //set channel-dropdown-menu li w/ data
//  var iframeshit = "<iframe src='//www.youtube-nocookie.com/embed/v9AKH16--VE?rel=0' frameborder='0' allowfullscreen></iframe>";
  
    if(data.clients && data.clients > 0){
      $("#currActive > .badge").html(data.clients);
      console.log("data.clients,YO:"+data.clients);
    }

    if(data.videoid && data.videoid.length < 25){
      //CHECK IF VIDEO IS ALREADY PLAING!
      if(videoid != data.videoid){
        videoid = data.videoid;
        showVideoByID(videoContainer, data.videoid);
        console.log("GOT A NEW data.videoid, YO!:"+data.videoid);
      }
      
      
    }

    if(data.channel && data.channel.length > 0 && data.channel.length < 25){
      //$("#input-channel").val(data.chennel);
      console.log("data.channel,YO!:"+data.channel);
    }

    if(data.playlist && data.playlist.length > 0 && data.playlist.length < 25){
      //$("#input-channel").val(data.chennel);
      console.log("data.playlist,YO!:"+data.playlist);

    }

    if(data.currTime && data.currTime.length){
      //$("#input-channel").val(data.chennel);
      console.log("data.currTime, YO!!:"+data.currTime);

    }

  }catch(e){

    console.log("CAUGHT ERROR" + e);
  
  }
};

$("#input-form").on("submit", function(event) {
  event.preventDefault();
  videoid   = $("#input-videoid")[0].value;
  //channel = $("#input-channel")[0].value;

  //note the double bang to coerce a boolean, then invert. clever.
  if(!!$.trim($("#input-videoid").val()).length){
    //ws.send(JSON.stringify({ handle: handle, text: text }));
    ws.send(JSON.stringify({ channel: channel, videoid: videoid}));
    //$("#input-videoid")[0].value = "";
    // showVideoByID(videoContainer, videoid);
  }

  
});

// $("#dropdown").on("change", function(event) {
//   //event.preventDefault();
//   console.log($("dropdown")[0].value);
//   //var videoid   = $("#input-videoid")[0].value;
//   //

//   //note the double bang to coerce a boolean, then invert. clever.
//   // if(!!$.trim($("#input-videoid").val()).length){
//   //   //ws.send(JSON.stringify({ handle: handle, text: text }));
//   //   ws.send(JSON.stringify({ videoid: videoid, channel: channel }));
//   //   $("#input-videoid")[0].value = "";
//   // }
// });

// "mini library" starts here
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
    videoid = videoID;

    //push onto the playlist stack

    var mElem = $('\
        <div class="videoListItem" id="'+videoID+'" data-value="'+videoID+'"> \
          <div class="videoListThumb"><img src="http://img.youtube.com/vi/'+videoID+'/0.jpg" title="'+videoID+'"></div> \
          <div class="desc">'+videoID+'</div> \
        </div> \
      ');

    var myID = '#' + videoID;
    try {
      if ( $( myID ).length ) {
        console.log("IT ALREADY EXISTZ!"); 
      }else{
        mElem.appendTo(".videoList");
      }
    }catch(e) {
      console.log("CAUGHT LENGTH ERROR!!!"); 
    }
    

    //push thumb
    //$("#videoL").append('<img src="http://img.youtube.com/vi/'+videoid+'/0.jpg" class="navbar-image" border="0" />');
    loadYouTubeAPI(function () {
        if (!domElement.player) {
            domElement.player = new YT.Player(domElement, {
     
                videoId     : videoID,
                playerVars: {
                    'rel'           : 0,
                    'autoplay'      : 1,
                    'loop'          : 1,
                    'playlist'      : videoID,
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
            domElement.player.loadVideoById(videoID);
        }
        //nowPlaying = player;
       // currentPopup[0].previousLanguage = language
    });

    

}

function setTimeTimeout() {

  // if (!sessionStorage['currentVideoTime']) {
  //   //get time!?
  //   sessionStorage['currentVideoTime'] = 0;
  // } else {
  //   sessionStorage['currentVideoId']++;
  // }

  // document.querySelector('#videoListContent').innerHTML = 
  //     '<p>' + sessionStorage.getItem('currentVideoId') + ' times</p>';
  
  currTime = videoContainer.player.getCurrentTime();
  
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

myTimer = setInterval(setTimeTimeout, 1000);

function stopTimeTimeout(){
    if (myTimer){
      console.log("GONNA stopTimeTimeout, myTimer:"+myTimer);
      clearInterval(myTimer);
      //myTimer = null;
    }
  
}

function startTimeTimeout(){
  console.log("GONNA startTimeTimeout, myTimer:"+myTimer);
  myTimer = setInterval(setTimeTimeout, 1000);
}
// end of "mini library"


showVideoByID(videoContainer , videoid);
// when video ends
function onPlayerStateChange(event) {        
    if(event.data === 0) {    
      console.log("WOULD PLAY... WS SENDING!!!");        
      ws.send(JSON.stringify({ channel: channel, videoid: videoid}));   
    }
    
}



$(".videoListItem").click( function(event) {
  event.preventDefault();
  $("#input-videoid")[0].value = $(this).data('value');
  //channel = $("#input-channel")[0].value;
  ws.send(JSON.stringify({ channel: channel, videoid: $(this).data('value')}));
  //showVideoByID(videoContainer , value);
});

        
    // when video ends
    function onPlayerStateChange(event) { 
      console.log("GOT onPlayerStateChange event.data:"+event.data);  
      //TODO: CANCEL INTERVAL IF VIDEO IS PAUSED!   
      if(event.data === 0) {            
        event.target.playVideo();
      }
      if(event.data === 1) {  
        startTimeTimeout() ;       
      }
      if(event.data === 2) {    
        stopTimeTimeout();
      }
    }


    