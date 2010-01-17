$KCODE = 'u'
$LOAD_PATH.unshift('./lib')
require 'ms'

def players(vid)
	db = Store.new(S[:vildb_path] + vid + '.db')
	db.transaction(true) { db['root'].players.keys }
end

arg = ARGV.shift
pls = {}
files = Dir.glob(S[:vildb_path] + '*.db')
files.sort! {|a, b| \
	File.basename(a).delete('.db').to_i <=> \
	File.basename(b).delete('.db').to_i
}
files.each {|fp|
	vid = File.basename(fp).split('.')[0]
	players(vid).each {|uid|
		unless pls.has_key?(uid)
			pls[uid] = 0
			puts "added: #{uid}" if arg
		end
	}
	puts pls.keys.size
}
