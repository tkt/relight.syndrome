$KCODE = 'u'
$LOAD_PATH.unshift('./lib')

require 'ms'

$DEBUG = false

def pltable(vid)
	fp = S[:vildb_path] + vid + '.db'
	vil = {'vid' => vid, 'name' => false}

	db = Store.new(fp)
	db.transaction(true) {
		if db['root'].state == Vil::State::End
			vil['name'] = db['root'].name
			vil['date'] = db['root'].date
			vil['winner'] = db['root'].winner
			vil['players'] = {}
			db['root'].players.each {|uid, pl|
				_ = {}
				_['name'] = pl.name
				_['skill'] = (pl.skill) ? pl.skill.name : nil
				_['position'] = (pl.skill) ? pl.skill.position : nil
				_['dead'] = pl.dead
				_['death'] = pl.death
				_['cause'] = (pl.respond_to?('cause')) ? pl.cause : nil
				vil['players'][pl.userid] = _
			}
		end
	}

	vil
end

vils = {}
Dir.glob(S[:vildb_path] + '*.db') {|fp|
	vid = File.basename(fp).split('.')[0]
	vil = pltable(vid)
	vils[vil['vid']] = vil
}
File.open('usersinfo.db', 'w') {|fh|
	fh.write(Marshal.dump(vils))
}
