LW_NAME = '月光症候群'
LW_VERSION = '0.92β'

HISTORY = [
	['2008-06-**',
	 '終了した村一覧・役職配分一覧の出力キャッシュ、複数村稼動の設定項目を実装しました。出力HTMLの一部をCSSへ移しより軽くなるように、負荷監視をほぼ全てのPOSTから投稿時のみのチェックに変更しました。今までApacheが吸収していたエラー表示のバグを修正しました。',
	],
	['2008-05-30',
	 '別ブランチで作業していたオープンレギュレーション実装をマージしました。',
	 '終了した村一覧の人数表示、お知らせページを実装しました。採決投票、処刑投票、部屋割り指名、スキル発動(襲撃、自殺)を非同期に、自動退村時にメッセージを出力するように、襲撃デフォルトをパスor餓死から襲撃先がいる場合は襲撃先に変更しました。狼が「パス」をした後に襲撃対象者がいなくなった場合でもパスを消費してしまうバグ、内部的に狂人の自殺が襲撃死と同様に扱われているバグを修正しました。',
	],
	['2008-04-05',
	 '試験的に(JavaScriptのみの実装で)50発言限定モードを、コアタイム(21:00～24:00)中の連戦警告、IDロックを実装しました。<br>ガードの到着日数をほぼ完全なランダムに、初回更新時のみアドバンス以上の人数が必要になるように、デバッグログを村ごとに出力するように、終了した村ログをHTMLで表示するように、終了ログ一覧に時刻を表示するように変更しました。<br>ランダム同室指名時に前日の同室者を指名できてしまうバグ、自殺・襲撃で2回死ぬ(殺す)ことができるバグ、同じ人間が投票→同室指名となる際に一定条件下で死者を同室指名できてしまうバグ、投稿失敗時でも発言欄の文字が消えてしまうバグ、狼の弁明時にささやきがあると投稿欄の文字が消えてしまうバグ、狼の投票時にささやきがあると投票がリセットされてしまうバグを修正しました。',
	],
	['2008-03-05',
	 '0.9βリリース。<br>人狼達の黄昏::夜明しとして運用開始しました。',
	],
	['2007-08-23 (import)',
	 '黄昏症候群からブランチ開始。ブランチ元は\'1.2β1\'でした。',
	],
]
