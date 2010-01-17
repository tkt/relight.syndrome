$KCODE = 'u'
$LOAD_PATH.unshift('./lib')
require 'ms'

def pltable(vid)
	fp = S[:vildb_path] + vid + '.db'
	vil = {'vid' => vid , 'uids' => []}

	db = Store.new(fp)
	db.transaction(true) {
		db['root'].players.each {|uid, pl| vil['uids'] << uid }
	}

	vil['ctime'] = File.ctime(S[:vildb_path] + vid + '_0.html')
	vil
end

arg = ARGV.shift

pls = {}
Dir.glob(S[:vildb_path] + '*.db') {|fp|
	vid = File.basename(fp).split('.')[0]
	vil = pltable(vid)
	unless arg
		puts ''
		puts [vil['vid'], vil['ctime'].strftime("%m/%d %H:%M:%S")].join(' ')
	end
	uids = []
	vil['uids'].each {|uid|
		next if uid == 'master'

		if pls.has_key?(uid)
			pls[uid] += 1
		else
			pls[uid] = 0
		end
		uids << "#{uid} (#{pls[uid]})"
	}
	unless arg
		uids.sort.each_with_index {|uid, n|
			print uid + ' '
			print "\n" if (n + 1) % 4 == 0
		}
		puts ''

		pls.each {|uid, n| pls[uid] = -1 unless vil['uids'].index(uid) }
	end
}
if arg
	total = 0
	pls.values.uniq.sort.reverse.each {|v|
		puts v + 1
		ary = []
		pls.each {|k ,vv| ary << k if vv == v}
		puts ' ' + ary.size.to_s + ': ' + ary.join(', ')
		total += ary.size
	}
	puts ['total: ', total.to_s].join
end
