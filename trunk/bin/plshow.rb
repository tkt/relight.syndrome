$KCODE = 'u'
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

fp = S[:vildb_path] + vid + '.db'

unless File.exist?(fp)
	puts 'No such village: ' + vid
	exit
end

dd = {0 => 'Live', 1 => 'Dead'}
prv = {true => 'Y', false => 'N', nil => 'N'}

db = Store.new(fp)
db.transaction(true) {
	a = []
	db['root'].players.each {|uid, pl|
		s = ''
		skill = (pl.skill.respond_to?(:name)) ? pl.skill.name : ''
		[\
			uid,
			skill
		].each {|value|
			s << value
			s << ' '
		}
		s << dd[pl.dead]
		s << ' '
		s << prv[pl.prevote]
		s << ' '
		s << NAMES[pl.pid].sub(/.* /, '')
		s << "\n"
		a << s
	}
	print a.sort.join
}
