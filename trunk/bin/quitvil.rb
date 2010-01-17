$LOAD_PATH.unshift('./lib')
require 'ms'

def usage
	puts 'usage'
end

class Vil
	public :do_quit
end

vid = ARGV.shift

begin
	vildb = Store.new("db/vil/#{vid}.db")
	vil = vildb.transaction {
		vil = vildb['root']
		vil.do_quit()
		vil.change_state_sync(4)
		vil
	}
end
