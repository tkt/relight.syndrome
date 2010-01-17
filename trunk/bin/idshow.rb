$LOAD_PATH.unshift('./lib')

require 'ms'

db = Store.new('db/user.db')
db.transaction(true) {
	db.roots.sort.each {|key|
		print key + ' '
		p db[key]
	}
}
