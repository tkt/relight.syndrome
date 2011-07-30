$LOAD_PATH.unshift('./lib')
require 'ms'

def usage
	puts 'usage'
end

vid = ARGV.shift
num = ARGV.shift

unless (vid)
	usage()
	exit
end

names = NAMES.dup
names.shift
names.shift
names.collect! {|x| names.index(x) + 2 }

vildb = Store.new("db/vil/#{vid}.db")
vildb.transaction {
	vil = vildb['root']

	('01'..num).step {|i|
		pid = names[rand(names.size)]
		names.delete(pid)

		uid = 'test' + i
		player = Player.new(pid, uid, -1)
		vil.add_player(player, Time.now.to_s)
	}
}
