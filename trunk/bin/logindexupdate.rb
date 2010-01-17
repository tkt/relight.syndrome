$LOAD_PATH.unshift('./lib')
require 'ms'

db = DB::Villages.new
db.db.transaction {
	db.db['root'].each {|v|
		v['end'] = File.mtime(S[:vildb_path] + v['vid'].to_s + '.db')
	}
}
DB::Villages.each {|v|
	p v
}
