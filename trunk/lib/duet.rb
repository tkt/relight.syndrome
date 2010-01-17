module Duet

	class Server
		attr_reader :wakeup_bysignal

		class OS
			def self.ps
				# FIXME: Oops! hard wired!!
				r = `ps ax|grep index.cgi|grep -v grep|wc -l`.chomp
				r = (r =~ /\d+/) ? r.to_i : false

				return r
			end

			def self.killall
				$logger.debug('### over process limit, executing killall... ###')
				`killall -9 ruby`
			end
		end

		def initialize(userid, req, dbfile = 'duet.db')
			@req = req
			@userid = userid
			@db = DB.new(dbfile)
			@db.regist(@userid, @req)
			@wakeup_bysignal = false
		end

		def self.limitcheck(limit)
			$logger.debug('### limitchecking....')
			pscnt = OS.ps()
			if pscnt
				$logger.debug('### processes: ' + pscnt.to_s)
				OS.killall() if pscnt >= limit
			end
		end

		def wait(sec = 120)
			Signal.trap(:USR1) {
				if @wakeup_bysignal
					$logger.debug('duplicated wake up signal, ignore')
				else
					$logger.debug('wake up by signal')
					@wakeup_bysignal = true
					@db.delete(@userid, @req)
				end
			}

			sec.to_i.times {|i|
				sleep(1)
				break if @wakeup_bysignal
			}
			unless @wakeup_bysignal
				$logger.debug('wake up')
				@db.delete(@userid, @req)
			end
		end

		def self.dispatch_at(uid, req, dbfile = 'duet.db')
			pid = DB.new(dbfile).delete(uid, req)
			$logger.debug('dispatch_at: ' + pid.to_s)
			begin
				Process.kill(:USR1, pid)
			rescue
				$logger.debug('(AT) missing target to kill: ' + pid.to_s)
			end
		end

		def self.dispatch(dbfile = 'duet.db', processlimit = false)
			self.limitcheck(processlimit) if processlimit
			DB.new(dbfile).pids.each {|pid|
				begin
					$logger.debug('dispatch(kill): ' + pid.to_s)
					Process.kill(:USR1, pid)
				rescue
					$logger.debug('missing target to kill: ' + pid.to_s)
				end
			}
		end
	end

	class DB
		require 'pstore' unless PStore

		def initialize(dbfile)
			@fp = dbfile
		end

		def regist(userid, req)
			addr = req.remote_addr + ':'
			pid = Process.pid
			uid = CGI.escape(userid)

			store = PStore.new(@fp)
			need_dispatch = false
			store.transaction(true) {|db| need_dispatch = db.root?(addr + uid) }
			Server.dispatch_at(uid, req, @fp) if need_dispatch

			################################ write lock
			$logger.debug('***LOCK FOR REGIST***: ' + [addr + uid, pid].join(' '))
			store.transaction {|db| db[addr + uid] = pid }
			$logger.debug('regist: ' + [addr + uid, pid].join(' '))
		end

		def pids
			ids = []
			PStore.new(@fp).transaction(true) {|db|
				db.roots.each {|root| ids << db[root] }
			}
			ids
		end

		def delete(userid, req)
			pid = nil
			addr = req.remote_addr + ':'
			uid = CGI.escape(userid)

			################################ write lock
			$logger.debug('***LOCK FOR DELETE***: ' + addr + uid)
			PStore.new(@fp).transaction {|db|
				pid = db[addr + uid]
				db.delete(addr + uid) if pid == Process.pid
			}
			if pid == Process.pid
				$logger.debug('delete: ' + addr + uid + %Q( '#{pid.inspect}'))
			else
				$logger.debug('not delete: ' + addr + uid + %Q( '#{pid.inspect}'))
			end

			pid
		end
	end
end
