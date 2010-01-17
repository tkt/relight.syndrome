GERT       = 'ソフィー'
GERT_ENTRY = 'まだみんな集まってないみたい……。'
GERT_FIRST = 'それでは、私は隣村にガードを呼びに行ってきます。大急ぎで往復しますが、今日から%1日後の%2日目に到着するかどうか……。それまでは皆さん夜に見張りをたてて安全を確保して下さい。'

OPENING = <<END
昼間は人の姿をとり、夜になると人を喰い殺すという人狼。その人狼がこの村にも紛れ込んでいるという噂が広がっていた。<br>事態を憂慮した村人達は人狼に関する話合いの場を設けることにした。
END

START = <<END
昨夜遅く、隣村への林に生えている樹木に爪跡が発見されたとの連絡があった。本当に人狼がいるのだろうか……。不安にかられた村人は隣村に駐留しているガードに助けを求めることにした。
END

FIRST_WHISPER = 'わおーん！！'
FIRST_WHISPER_LW = 'わおーん！！<br><br>……と吠えても仲間はいない♪<br>そんなわたしゃロンリーウルフ♪'


# 投票
ANN_VOTING = '%1 の投票です。'

# 投票
VOTING = '%1 は %2 に投票した。'

# 部屋割り投票
ANN_ROOM_VOTING = '%1 の指名です。'

# 部屋割り投票
ROOM_VOTING = '%1 は %2 を指名した。'

# 部屋割り野宿組
BUSH_ROOM = '残った%1は同室です。'

# 部屋割り決定(ADV)
ROOM_RESULT_ADV = '%1は同室です。'

# 部屋割り決定
ROOM_RESULT = '今夜は以下の部屋割りで見張りを行うことになった。<br><br>'

# 前日部屋割り
ROOM_YESTERDAY = '昨夜は以下の部屋割りで見張りを行いました。<br><br>'

# 弁明
APOLOGY_START = '%1の弁明です。'

# 昼フェイズ
SUN_PHASE = 'ガードが到着するまで後%1日、村人たちは不安な面持ちのまま会議をはじめた。'

# 昼終わり
SUNSET_PHASE = '既に日が沈みかけている……。'

# 採決フェイズ
PREVOTE_PHASE = '村人たちは処刑を行うかどうかの採決を取ることにした。<br>投票順序は %1 。'

# 投票フェイズ
VOTE_PHASE = '投票フェイズです。<br>投票順序は %1 。'

# 弁明フェイズ
APOLOGY_PHASE = '票が同数となった。自らの潔白を証明するために弁明を行うのは %1 。<br>弁明順序は %2 。'

# 決戦投票フェイズ
FINALVOTE_PHASE = 'そして決選投票が行われる。処刑候補者は、%1 。<br>投票順序は %2 。'

# 部屋割りフェイズ
ROOM_PHASE = '夜の見張り小屋の部屋割りを決めることになった。<br>指名順序は %1 。'

# 部屋割り終了
AFTERROOM_PHASE = '部屋割りが終わり、村人達は各々見張りの準備を始めた……。'

# 夜フェイズ
NIGHT_PHASE = '日が沈み、人狼たちの支配する夜がはじまる。'

# 朝フェイズ
MORNING_PHASE = '夜が終わり、朝日が昇る。村人達はお互いの顔を伺いながら、会議の準備を始めた……。'

# 見張り小屋ログ
ROOM_HEAD = '%1 の見張り小屋では……'

# 墓下ログ
GROAN_HEAD = '死者たちを埋葬した墓地に植えられた樹木がざわめいている。'

# 無記名投票
ANON_VOTING = '%2 に、%1人が投票した。'

# 処刑
EXECUTION = '%1 は村人達に処刑された。'

# 処刑保留
STOP_EXECUTION = '同数のため、本日の処刑は保留になった。'

# 死亡
DIE = '%1 は死亡した。'

# ブロック
BLOCKING = '不浄なる %1 よ！ 神の御加護を知れ！'

# カウンター
COUNTERING = '不浄なる %1 に、天空より神の裁きを！'

# 襲撃
ATTACKING = '%1！ 我らが血肉となれ！'

SUDDEN_DEATH = '%1 は、突然死した。'

KILLED = '次の日の朝、%1 が無残な姿で発見された。'

KILLMISS = '犠牲者はいないようだ。一見すると、昨晩は何事もなかったかのように見える。'

YOKO_WIN = '全てが終わったかのように見えた。<br>しかし、奴が生き残っていた！<br>'
# 村勝利時妖魔勝利
YOKO_WIN_F = YOKO_WIN
# 狼勝利時妖魔勝利
YOKO_WIN_W = YOKO_WIN

GUARD_WIN = 'ガードが村に到着し、人狼は全て退治された……人狼に怯える日々は去ったのだ！<br>'

FOLK_WIN = '全ての人狼を退治した……人狼に怯える日々は去ったのだ！<br>'

WOLF_WIN = 'もう人狼に抵抗できるほどの村人は残っていない……村の中には人狼の遠吠えが響きわたっている。<br>'

SYSTEM_EXIT = 'この村は廃村されることになりました。<br>'

# 参加
JOINING = '%1 が参加しました。'

# 離脱
PARTING = '%1 は去りました。'

AUTO_PARTING = '%1 は去ったようです。'

# 1=村娘パメラ 2=she 3=生存 4=村人
TRUTH = '%1 （%2）、%3。%4だった。'

LIVES = '現在の生存者は、%1の %2名'

NAMES = [
	'？？？',
	'村長の娘 ソフィー',
	'楽天家 ルネ',
	'青年 アルフレド',
	'村娘 アネット',
	'資産家 マルク', 
	'牧場長 ガストン',
	'遊牧民 モニカ',
	'ならず者 レオン',
	'少年 ジャン',
	'少女 エリーズ',
	'行商人 エドワール',
	'召使い アリス',
	'老人 セルジュ',
	'冒険家 クロード',
	'料理人 カテリーナ',
	'農夫 ラシェル',
	'旅人 ビクトル',
	'花屋 ジジ',
	'医師 ジロラモ',
	'修道女 シルヴィ',
	'鍛冶屋 ロレンツォ',
	'旅芸人 ダリオ',
	'占い師 エヴァ',
	'棟梁 ガリレオ',
	'貴族 ラヴィーナ',
	'御者 バジリオ',
	'詩人見習い レベッカ',
	'金貸し マルティーノ',
	'仕立て屋 ミカエラ',
]
