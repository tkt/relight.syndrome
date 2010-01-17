$LOAD_PATH.unshift('./lib')
require 'ms'

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
	vil.update()
}
