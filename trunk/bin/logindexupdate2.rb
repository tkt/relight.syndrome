$LOAD_PATH.unshift('./lib')
require 'ms'

db = DB::Villages.new
db.db.transaction {
	db.db['root'].each {|v|
		next unless v['state'] == 4
		size = nil
		fp = S[:vildb_path] + v['vid'].to_s + '.db'
		if File.exist?(fp)
			s = Store.new(fp)
			s.transaction(true) {|db|
				size = db['root'].players.size
			}
		end
		v['players'] = size
	}
}
