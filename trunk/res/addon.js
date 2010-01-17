// from 9sus.skr.jp. Thanks.
function imgChange() {
  var i = document.entryForm.pid.selectedIndex;
  var s = document.entryForm.pid.options[i].value;
  if (s.length == 1) {
	s = "0"+s;
  }
  $('charaimg').src = "http://wtl.rdy.jp/share/body"+s+".jpg";
}
