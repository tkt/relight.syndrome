$LOAD_PATH.unshift('./lib')
require 'ms'

def usage
	puts 'usage'
end

userdb = Store.new('db/user.db')
userdb.transaction {
	userdb['master'] = {'sig' => '0'}
	20.times {|i|
		x = two(i+1)
		userdb['test' + x] = {'sig' => '0'}
	}
}
