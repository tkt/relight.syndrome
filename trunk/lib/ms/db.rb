module DB
	
	class Village
		attr_reader :db

		def initialize(vid)
			@fp = "db/vil/#{vid}.db"
			@db = Store.new(@fp)
		end

		def self.players(vid)
			db = new(vid)
			_ = Vil::Players.new
			db.db.transaction(true) {
				_ = db.db['root'].players if db.db['root']
			}
			_
		end
	end

	class Villages
		attr_reader :db

		def initialize
			@fp = S[:vilsdb_path]
			@db = Store.new(@fp)
		end
	
		def self.each(&block)
			db = new()
			db.db.transaction(true) { db.db['root'].each(&block) }
		end
	
		def self.select(&block)
			db = new()
			db.db.transaction(true) { db.db['root'].select(&block) }
		end

		def self.change_state(vid, state)
			db = new()
			db.db.transaction {
				v = db.db['root'].find() {|v|
					v['vid'] == vid
				}
				v['state'] = state
			}
		end

		def self.restart(vid, update_time)
			db = new()
			db.db.transaction {
				vil = db.db['root'].find() {|v| v['vid'] == vid }
				vil['start'] = update_time
				vil['state'] = 0
			}
		end
	
		def self.finish(vid, pl_num)
			db = new()
			db.db.transaction {
				vil = db.db['root'].find() {|v| v['vid'] == vid }
				vil['state'] = 4
				vil['end'] = Time.now
				vil['players'] = pl_num
			}
		end
	end

	class Users
		attr_reader :userdb

		def initialize
			@userdb = Store.new('db/user.db')
		end

		def self.registaddress(uid, addr)
			db = new()
			db.userdb.transaction {
				db.userdb.roots.each {|u|
					db.userdb[u]['addr'] = addr if u == uid
				}
			}
		end

		def self.registlast(vid, uids)
			db = new()
			db.userdb.transaction {
				db.userdb.roots.each {|uid|
					db.userdb[uid]['last'] = vid if uids.index(uid)
				}
			}
		end

		def self.continual?(vid, uid)
			_ = false
			db = new()
			db.userdb.transaction(true) {
				_ = (db.userdb[uid].has_key?('last') && db.userdb[uid]['last'] == vid - 1)
			}
			_
		end
	end

end
