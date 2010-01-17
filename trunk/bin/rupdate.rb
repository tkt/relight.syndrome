$LOAD_PATH.unshift('./lib')
require 'ms'

class Vil
	def rupdate
		@update_time -= @period * 60
	end
end

def usage
	puts 'usage'
end

vid = ARGV.shift

unless (vid)
	usage()
	exit
end

vildb = Store.new("db/vil/#{vid}.db")
vildb.transaction {
	vil = vildb['root']
	vil.rupdate()
}
