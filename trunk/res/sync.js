function init(village_id) {
	load(village_id);
	setTimeout('showUpdateTimer();', 1000);
}

////////////// Comet & Ajax

function post(vid, pid, atype) {
	var content = $F(atype);
	if (content == '') { return; }
	var mtype = 'say';
	if (atype != 'action') { mtype = atype; }

	var url = './';
	var params = {
		method: 'post',
		requestHeaders: Util.createHeaders(),
		postBody: $H({
			cmd: 'post',
			vid: vid,
			pid: pid,
			mtype: mtype,
			message: content
		}).toQueryString(),
		onSuccess: success,
		onFailure: failure
	};
	Util.debug('POST request.');
	if ($('whisper')) {
		$('whisperbutton').disabled = true;
	}
	if ($('action') || $('night')) {
		Element.show('loadicon');
		$('stdsaybutton').disabled = true;
	}
	var ajax = new Ajax.Request(url, params);
}

function success(res, json) {
	Util.debug('POST success.');
	if ($('action') || $('night')) {
		Element.hide('loadicon');
		$('stdsaybutton').disabled = false;
		if ($('night')) {
			Field.clear('night');
			Field.focus('night');
		} else if ($('action')) {
			Field.clear('action');
			Field.focus('action');
		}
	}
	if ($('whisper')) {
		Field.clear('whisper');
		$('whisperbutton').disabled = false;
		Field.focus('whisper');
	}
	if ($('postfail')) { Element.hide('postfail'); }
}

function failure(res, json) {
	Util.debug('Request failure, reload this page please.');
	if ($('action') || $('night')) {
		Element.hide('loadicon');
		$('stdsaybutton').disabled = false;
		if ($('night')) {
			Field.focus('night');
		} else if ($('action')) {
			Field.focus('action');
		}
	}
	if ($('whisperbutton')) {
		$('whisperbutton').disabled = false;
	}
	if ($('postfail')) { Element.show('postfail'); }
}

function vote(vid, atype) {
	var target = $F($(atype + 'target'));
	var cmd = atype;
	if (target == '') { return; }
	if (atype == 'room') { cmd = 'vote'; }

	var url = './';
	var params = {
		method: 'post',
		requestHeaders: Util.createHeaders(),
		postBody: $H({
			cmd: cmd,
			vid: vid,
			pid: target
		}).toQueryString(),
		onSuccess: vote_success,
		onFailure: vote_failure
	};
	Util.debug(atype + ' request.');
	Element.show('loadicon');
	$(atype + 'button').disabled = true;
	var ajax = new Ajax.Request(url, params);
}

function vote_success(res, json) {
	Util.debug('POST success.');
	Element.hide('loadicon');
	if ($('postfail')) { Element.hide('postfail'); }
	var atypes = new Array('vote', 'prevote', 'room');
	for (var i=0; i < atypes.length; i++) {
		if ($(atypes[i] + 'button')) {
			$(atypes[i] + 'button').disabled = false;
		}
	}
}

function vote_failure(res, json) {
	Util.debug('Request failure, reload this page please.');
	Element.hide('loadicon');
	var atypes = new Array('vote', 'prevote', 'room');
	for (var i=0; i < atypes.length; i++) {
		if ($(atypes[i] + 'button')) {
			$(atypes[i] + 'button').disabled = false;
		}
	}
	if ($('postfail')) { Element.show('postfail'); }
}

function skill(vid) {
	if ($('skilltarget')) {
		var target = $F($('skilltarget'));
	}else{
		var target = 0;
	}

	var url = './';
	var params = {
		method: 'post',
		requestHeaders: Util.createHeaders(),
		postBody: $H({
			cmd: 'skill',
			vid: vid,
			pid: target
		}).toQueryString(),
		onSuccess: skill_success,
		onFailure: skill_failure
	};
	Element.show('skillloadicon');
	$('skillbutton').disabled = true;
	var ajax = new Ajax.Request(url, params);
}

function skill_success(res, json) {
	Element.hide('skillloadicon');
	if ($('skillfail')) { Element.hide('skillfail'); }
	if ($('skillwolf')) { Element.hide('skillwolf'); }
	$('skillbutton').disabled = false;
}

function skill_failure(res, json) {
	Element.hide('skillloadicon');
	if ($('skillfail')) { Element.show('skillfail'); }
	$('skillbutton').disabled = false;
}

function load(village_id) {
	Util.debug('loading start...');
	vid = village_id;  // set_global

	var url = './';
	var params = {
		method: 'get',
		requestHeaders: Util.createHeaders(),
		parameters: $H({
			cmd: 'sync',
			vid: vid,
			mid: $('dis_size').innerHTML,
			ast: $('actstate').innerHTML,
			lst: $('livestate').innerHTML
		}).toQueryString(),
		onSuccess: rcv_sucess,
		onFailure: rcv_failure
	};
	var ajax = new Ajax.Request(url, params);
	loadstate('now');
}

function rcv_display(res, json) {
	try{
		eval("var ret="+res.responseText);
		Util.debug('response eval OK.')
	} catch(e) {
		Util.debug('response eval Failed.')
		alert("Error, missing response. Please, reload.");
	}
	if (ret[1] && ret[1] != '' ) {
		if ($('livestate').innerHTML == 'live') {
			pattern = /name="?cmd"?/i

			Util.debug($('player').innerHTML.match(pattern));
			Util.debug(ret[1].match(pattern));

			if ($('player').innerHTML.match(pattern) != ret[1].match(pattern)) {
				Util.debug('search pattern matched');
				if ($('whisper')) { var content = $F('whisper'); }
				$('player').innerHTML = ret[1];
				if (content) { $('whisper').value = content; }
			}
		}
		if (ret[5] && ret[5] != '') {
			document.body.style.backgroundImage = 'url(' + ret[5] + ')';
		}
	}
	if (ret[4] && ret[4] != '') { $('order').innerHTML = ret[4]; }
	if (ret[1] && $('livestate').innerHTML != 'live' && ret[6] && ret[6] != '') {
		$('timeline').innerHTML = ret[6];
	}

	if (ret[2] && ret[2] != '') {
		var discuss = $('discuss');
		if (ret[6] && ret[6] != '') {
			$('timeline').innerHTML = ret[6];
			if (ret[1] && $('livestate').innerHTML != 'live') {
				$('player').innerHTML = ret[1];
			}
			if (ret[7]) { $('whisper_box-wrap').innerHTML = ret[7]; }
			discuss.innerHTML = ret[2];
		}else{
			var div = document.createElement('div');
			div.innerHTML = ret[2];
			discuss.insertBefore(div, discuss.firstChild);

			var chatmode = $('chatmode');
			if (chatmode && chatmode.checked) {
				var limit = 50;

				if (discuss.childNodes.length > limit) {
					var cnt = discuss.childNodes.length - limit;
					for (var i=0; i < cnt; i++) {
						discuss.removeChild(discuss.lastChild);
					}
				}
			}
		}
	}
	if (ret[3]) {
		if (ret[3] == 'reload') {
			location.reload(true);
			return;
		}else if (ret[3] != '') {
			$('dis_size').innerHTML = ret[3];
		}
	}
}

function rcv_sucess(res, json) {
	loadstate('ok');
	Util.debug(res.status);

	switch(res.status) {
		case 200:
			rcv_display(res, json);
			Util.debug('OK');
			break;
		case 204:
			Util.debug('Not modified');
			break;
		case 0:
			Util.debug('Not modified, Opera9'); // fix for Opera9.
			break;
		default:
			Util.debug('An Error, Retrying...');
	}

	load(vid);
}

function rcv_failure(res, json) {
	if (res.status == 1223) {
		Util.debug('Not modified, IE'); // fix for IE
		load(vid);
	}else{
		loadstate('fail');
		Util.debug('Receive failure, reload this page please.');
	}
}

////////////// Sync Time

function showUpdateTimer() {
  var resttimeSpan = document.getElementById("resttime");
  if (!resttimeSpan.innerHTML.match(/(-*[0-9]+)分(-*[0-9]+)秒/)) {
    return;
  }
  var min = parseInt(RegExp.$1);
  var sec = parseInt(RegExp.$2);
  if (min > 59) {
    location.reload(true);
    return;
  }
  sec -= 1;
  var s = '';
  if (sec < 0) {
    if (min == 0) {
	 	s = '(更新準備中)';
    }else{
		sec = 59;
		min -= 1;
	 }
  }
  if (s && s != '') {
	  resttimeSpan.innerHTML = '0分0秒' + s + 'です';
  }else{
	  resttimeSpan.innerHTML = min + '分' + sec + '秒' + s + 'です';
  }
  setTimeout('showUpdateTimer();', 1000);
}


////////////////////////////////

function loadstate(image) {
	if ($('loadstatus')) {
		$('loadstatus').src = 'http://wtl.rdy.jp/share/load.' + image + '.gif';
	}
}


////////////////////////////////////// Util

function Util() {};

Util.createHeaders = function() {
	var headers = ['Pragma',
		'no-cache',
		'Cache-Control',
		'no-cache',
		'If-Modified-Since',
		'Thu, 01 Jun 1970 00:00:00 GMT'];

	return(headers);
}

Util.debug = function(string) {
	if ($('debug')) {
		var d = new Date();
		var current = d.getHours() + ':' + d.getMinutes() + ':' + d.getSeconds();

		var s = current + ' ' + string + "<br>" + $('debug').innerHTML;
		$('debug').innerHTML = s;
	}
}
