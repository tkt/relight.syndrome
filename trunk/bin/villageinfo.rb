$KCODE = 'u'
$DEBUG = false
$LOAD_PATH.unshift('./lib')

require 'ms'
require 'pp'

def vilinfo(vid)
	fp = S[:vildb_path] + vid + '.db'
	vil = {'vid' => vid, 'name' => false}

	db = Store.new(fp)
	db.transaction(true) {
		if db['root'].state == Vil::State::End
			vil['state'] = true
			vil['name'] = db['root'].name
			vil['date'] = db['root'].date
			begin
				vil['guard'] = db['root'].guard
			rescue
				vil['guard'] = 0
			end
			vil['rule'] = db['root'].rule
			vil['winner'] = db['root'].winner
			vil['rolls'] = []
			db['root'].players.each {|uid, pl|
				if pl.skill
					vil['rolls'] << pl.skill.sname
				else
					vil['rolls'] << '未'
				end
			}
		else
			vil['state'] = false
		end
	}

	vil
end

vils = {}
Dir.glob(S[:vildb_path] + '*.db') {|fp|
	vid = File.basename(fp).split('.')[0]
	vil = vilinfo(vid)
	vils[vil['vid'].to_i] = vil if vil['state']
}
db = Store.new(S[:vilsdb_path])
db.transaction(true) {
	db['root'].each {|v|
		if vils.has_key?(v['vid'])
			vils[v['vid']]['start'] = v['start']
			vils[v['vid']]['end'] = v['end']
		end
	}
}

File.open('vilsinfo.db', 'w') {|fh|
	fh.write(Marshal.dump(vils))
}
