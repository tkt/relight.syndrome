SHOW_UPDATE = '%1時%2分%3秒に更新されます。残り時間は<span id="resttime">%4分%5秒です</span>。'
SHOW_UPDATE_STATIC = '%1時%2分%3秒に更新されます。'

SHOW_UPDATE_PR = "%1人が参加しています。%2人以上の参加があれば1日目に進み、それ以下の参加人数なら#{S[:restart_minute]}分延長されます。"
SHOW_UPDATE_PR_STATIC = "%1時%2分%3秒に更新されます。<br>それまでに%4人以上の参加があれば1日目に進み、それ以下の参加人数なら#{S[:restart_minute]}分延長されます。"

SHOW_WINNER = '%1陣営の勝利です！<br>全てのログとユーザー名を公開します。今回の感想などをどうぞ。'
SHOW_WINNER_STATIC = '%1陣営の勝利です！<br>全てのログとユーザー名を公開します。%2時%3分まで自由に書き込めますので、今回の感想などをどうぞ。'

SHOW_WASTE = "現在%1発言です。#{S[:log_max]}発言に達した状態で参加人数が揃わない場合、更新時に廃村されます。"
PLEASE_LOGIN = '参加者はログインして下さい。'
ID_LOCKED = "ID: <strong>%1</strong> はロックされているため、エントリーできません。<hr>%2"
ID_WARN = 'このIDはロック警告中です。自重して下さい。ロックされる覚えがない方は掲示板か電子メールでお問い合わせ下さい。'

#tkt@mod:2011/03/17 for bug fix(dead man eating) start
HEAD1 = <<END
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html lang="ja">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta http-equiv="Content-Script-Type" content="text/javascript">
<meta http-equiv="Content-Style-Type" content="text/css">
<meta name="robots" content="nofollow">
<link rel="stylesheet" type="text/css" href="#{S[:css_dir]}default.css">
<script type="text/javascript" src="#{S[:script_dir]}prototype.js"></script>
<script type="text/javascript" src="#{S[:script_dir]}jquery.js"></script>
<script type="text/javascript" src="#{S[:script_dir]}sync.js"></script>
<script type="text/javascript" src="#{S[:script_dir]}addon.js"></script>
END
#tkt@mod:2011/03/17 for bug fix(dead man eating) end

HEAD2 = <<END
</head>
<body onLoad="init();">
<div class="content" id="content">
<table border=0 cellpadding=0 cellspacing=0 width="100%">
<tr><td align="center" valign="top">
END

HEAD3 = <<END
<table class="main" border=0 cellpadding=0 cellspacing=0>
<tr><td align="center" valign="top">
<a name="top" href="./"><img src="#{S[:image_dir]}title.jpg" alt="title"></a>
</td></tr>
<tr><td align="left" valign="top">
<div class="main">
END

FOOT = <<END
<br>
<div class="return">
<a href="#top">↑</a> 
<a name="bottom" href=".">トップページに戻る</a>
</div>

</div>

</td></tr></tbody></table>
</td></tr></tbody></table>

</div>
END

STATES = [
	'参加者募集中です。',
	'開始待ちです。',
	'進行中です。',
	'勝敗が決定しました。'
]
