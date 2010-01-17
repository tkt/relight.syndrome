$LOAD_PATH.unshift('./lib')

require 'ms'

checker = {}

db = Store.new('db/user.db')
db.transaction(true) {
	db.roots.sort.each {|key|
		rec = db[key]
		rec['id'] = key
		if checker.has_key?(rec['sig'])
			checker[rec['sig']] << rec
		else
			checker[rec['sig']] = [rec]
		end

		if checker.has_key?(rec['addr'])
			checker[rec['addr']] << rec
		else
			checker[rec['addr']] = [rec]
		end
	}
}

checker.each {|k, v|
	if v.size > 1
		puts k
		checker[k].each {|vv| p vv}
		puts
	end
}
