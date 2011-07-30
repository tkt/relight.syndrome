$LOAD_PATH.unshift('./lib')
require 'ms'

def usage
	puts 'usage'
end

vid = ARGV.shift
phase = ARGV.shift

unless (vid)
	usage()
	exit
end


def update(vil, phase)

	if phase == 'd'
		addmsg(vil)
		vil.update()
	elsif phase == 'v'
		vil.players.each {|uid, pl|
			vil.update()
		}
	elsif phase == 'o'
		
		if (vil.players.size) > 4
			p vil.players.size
			size = ((vil.players.size - 1) / 2) - 1
			p size
			size = size + 1 if (vil.date == 1) && [9, 11, 12, 13].index(vil.players.size.to_i) != nil
			size = size + 1 if (vil.date == 1) && [12].index(vil.players.size.to_i) != nil
			#size = size + 1 if (vil.date == 1) && [13].index(vil.players.size.to_i) != nil
			p size
			
			for i in 1..size
				vil.update()
			end
		end 
		
	elsif phase == 'n'
		vil.update()
		vil.update()
		vil.update()
	else
		vil.update()
	end
end

def addmsg(vil)
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
end


vildb = Store.new("db/vil/#{vid}.db")
vildb.transaction {
	vil = vildb['root']
	update(vil, phase)
	Duet::Server.dispatch(S[:ajaxdb_path] + ".#{vil.vid}")
}