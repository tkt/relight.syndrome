$KCODE = 'u'
$DEBUG = false
$LOAD_PATH.unshift('./lib')

require 'ms'
require 'pp'

def winner(vid)
	db = Store.new(S[:vildb_path] + vid + '.db')
	db.transaction(true) { db['root'].winner }
end

vils = []
Dir.glob(S[:vildb_path] + '*.db') {|fp|
	vid = File.basename(fp).split('.')[0]
	vils << winner(vid)
	vils.shift if vils.size > 100
	fwins = vils.select {|v| v == '村人' }.size.to_f
	wwins = vils.select {|v| v == '人狼' }.size.to_f

	all = vils.size.to_f
	fper = (fwins == 0) ? 0 : (fwins / all) * 100
	wper = (wwins == 0) ? 0 : (wwins / all) * 100

	puts [fper, wper].collect {|n| n.to_i }.join(', ')
}
