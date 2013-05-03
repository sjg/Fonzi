var ws = null;
var host = "127.0.0.1";
var port = 8888;
var socket = "p5websocket";

var statsShowing = 1;
var debounce = 0;
var authcode = "";
var image_array = new Array();

$(document).keyup(function(e) {
    if (e.keyCode == 27 || e.keyCode == 83 ) { 
        toggleStats();
    } 
});


function ready() {
	console.log("Trying to connect...");
	ws = new WebSocket("ws://" + host + ":" + port + "/" + socket);

	ws.onopen = function () {
	  console.log("Connected");
	};

	ws.onmessage = function (e) {
		var msg = JSON.parse(e.data);
		if(msg.hasOwnProperty('swipe-left')){
			if(!debounce){
	            console.log("Swipe-Left");
			    debounce = 1;
	            $(".scrollable").data("scrollable").next();
	            setTimeout(function() { debounce = 0 }, 800);
	        }
		}else if(msg.hasOwnProperty('swipe-right')){ 
	        if(!debounce){
			    console.log("Swipe-Right");
	            debounce = 1;
	            $(".scrollable").data("scrollable").prev();
	            setTimeout(function() { debounce = 0 }, 800);
	        }       
		}else if(msg.hasOwnProperty('thumbs-up')){
			if(!debounce){
				console.log("thumbs-up");
				debounce = 1;
				$('#like').fadeIn(function(){  
					var song = $('#fonz');
					song.get(0).play();
				}).delay(1200).fadeOut(function(){
					debounce = 0; 
				});
			}
		}else if(msg.hasOwnProperty('rgb_image')){
	        //RGB Camera Image
	        $("#rgbimage").attr('src', 'data:image/jpg;base64,' + msg.rgb_image);
	    }else if(msg.hasOwnProperty('blob_image')){
	        //Depth Cam Image
	        $("#blobimage").attr('src', 'data:image/jpg;base64,' + msg.blob_image);
	    }
	}
}

window.fbAsyncInit = function () {
    FB.init({
        appId: '166776013394164', 
        status: true, 
        cookie: true, 
        xfbml: true 
    });

    FB.Event.subscribe('auth.statusChange', function(response) {
        if (response.status === 'connected') {
            $('#spinner').fadeIn();
            $('#like').hide();

            authcode =  response.authResponse.accessToken;

            getPhotos();
        } else if (response.status === 'not_authorized') {
            $('#spinner').fadeOut();
            $('#like').show();
            $('#status p').html("Log in to Facebook");
        } else if(response.status === 'unknown'){
            $('#status p').html("Log in to Facebook");
            $('#spinner').hide();
            $('#status').fadeIn();
            $('#like').show();
            $('.items').html("<div style=''></div>");
        }
    });

};

(function (d) {
    var js, id = 'facebook-jssdk', ref = d.getElementsByTagName('script')[0];
    if (d.getElementById(id)) { return; }
    js = d.createElement('script'); js.id = id; js.async = true;
    js.src = "//connect.facebook.net/en_US/all.js";
    ref.parentNode.insertBefore(js, ref);
} (document));

function getPhotos(){
        FB.api('/me', function(response) {
            var fid = FB.Data.query('select target_id from connection where source_id == ' + response.id);
            $('#status p').html("Getting Friends");
            fid.wait(function(fid_rows) {
                var friends_id = "(";
                $.each(fid_rows, function(key, value){ 
                    friends_id += value.target_id + ",";
                });

                friends_id = friends_id.substr(0,friends_id.length-1);
                friends_id += ")";

                var stream_rows_query = 'select actor_id, message, type, attachment from stream where source_id in ' + friends_id + ' and type=247 LIMIT 500';

                $('#status p').html("Getting Photos");
                var mystream_photos = FB.Data.query(stream_rows_query);
                    mystream_photos.wait(function(stream_rows) {
                    writePhotos(stream_rows);
                });        
            });
        });
}

function writePhotos(streamArray){
    $('#status p').html("");
    $('#spinner').hide();
    
    $.each(streamArray, function(key, value){ 
        var image = value.attachment.media[0].src.replace('_s', '_n');
        var text = value.message;
        text = replaceURLs(text);

        if(text.length >= 115){
            text = text.substr(0, 113) + " ...";
        }

        if(text == ""){
            text = "No message";
        }

        $(".scrollable").data("scrollable").addItem("<div style=''><img src='" + image + "' /> <div id='profile' style='width: 37%; line-height: 45px; background-color: #000000; overflow: hidden; font-size: 30px; color: white; font-weight: 100; height: 360px; margin-top:23px; padding: 20px;'>" + text + "</div></div>");
    	image_array.push(image);
    });
}

function replaceURLs(text) {
    var exp = /(\b(https?|ftp|file|http):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/ig;
    return text.replace(exp,""); 
}

function checkFacebookLogin() {
    FB.getLoginStatus(function (response) {
        if (response.status === 'connected') {
            $('#spinner').show();
            $('#status p').html("Contacting Facebook");
            $('#like').hide();
            getPhotos();
        } else {
            $('#spinner').hide();
            $('#like').show();
            $('#status p').html("Login to Facebook");
        }
    });
}

function toggleStats(){
    if(!statsShowing){    
        $('#cam1').fadeIn();
        $('#cam2').fadeIn();
        statsShowing = 1;
    }else{
        $('#cam1').fadeOut();
        $('#cam2').fadeOut();
        statsShowing = 0;
    }
}

function likePost(url){
	//Like the current image by passing the image location into Open Graph
	$.post("https://graph.facebook.com/me/og.likes", { 
    	access_token: authcode, 
    	object: url
	});
}

function getCurrentImage(){
	var index = $(".scrollable").data("scrollable").getIndex();
	return(image_array[index]);
	//var s = $('.items').children()[index];
	//return($(s).find('img').attr('src'));
	
}
