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
	vil.players.each {|uid, pl|
		type = 'say'
		type = 'groan' if (pl.dead? && type == 'say')
		type = 'say' if (pl.live? && type == 'groan')
		type = 'say' if (vil.state == 4 && type != 'say')

		vil.record(type, pl, Time.now.to_s)

		if pl.can_whisper
			vil.record('whisper', pl, Time.now.to_s)
		end
	}
	Duet::Server.dispatch(S[:ajaxdb_path] + ".#{vil.vid}")
}
