#add@tkt 2009/12/30 for access check
module Access
	require 'cache'
	require 'pstore'
	class Check
		def initialize(addr)
			@addr = addr
			@accessdb = PStore.new(S[:access_check_dbpath])
			@access_datas = []
			
			if File.exist?(S[:access_check_dbpath]) == false
				@accessdb.transaction {
				  @accessdb['root'] = Array.new
				}
			end
		end
		
		def result()
			access()
			
			if @addr != nil && @addr != ''
				regist()
			end
			
			get_num()
		end
		
		def access()
			ckey = File.mtime(S[:access_check_dbpath]).to_i.to_s
			cache = Cache::FileCache.new(:root_dir => S[:cache_dir] + 'access')
			
			begin
				@access_datas = cache.get_object(ckey)
				narrow()
			rescue Cache::CacheMiss
				cache.clear()
				get_fromdb()
				cache.set_object(ckey, @access_datas)
			end
		end
		
		def get_fromdb()
			@access_datas = select{|a| timediff(Time.now, a['time']) <= 60 * S[:access_check_time] }
		end
				
		def narrow()
			@access_datas.delete_if{|a| timediff(Time.now, a['time']) > 60 * S[:access_check_time] }
		end
		
		def get_num()
			result = []
			@access_datas.each{|a|
  				result << a['addr']
  			}
			result.uniq!
			result.size
		end
		
		def regist()
			if access_recent? == false
				regist_addr()
			end
		end
		
		def access_recent?()
			accesses = @access_datas
			accesses = accesses.select{|a| a['addr'] == @addr && timediff(Time.now, a['time']) <= 60 * S[:access_same_time] }
			accesses.size > 0
		end
		
		def regist_addr()
			time = Time.now()
			@accessdb.transaction do
				accessdata = Hash.new
				accessdata['time'] = time
				accessdata['addr'] = @addr
				@accessdb['root'].push(accessdata)
			end
		end
		
		def timediff(time1, time2)
			(time1 - time2)
		end
		
		def select(&block)
			@accessdb.transaction(true) { @accessdb['root'].select(&block) }
		end
		
		def selectAll()
			@accessdb.transaction(true) { @accessdb['root'] }
		end
	end
end