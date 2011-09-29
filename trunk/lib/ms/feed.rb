#2010/01/15:add module:tkt for out entries data
module Feed
	require 'ms'
	require 'cache'
	require 'fileutils'
	DIR_FEED = 'feed'

	class Base
		attr_reader :active_villages
		
		#sate指定
		def initialize(outfile, active_vils = nil, timeformat = '%%', state = '', header = 'application/xml')
			klass = self.class.to_s.gsub(/.*::/ , '').downcase
			@encoding = 'utf-8'
			@suffix = '.rxml'
			@fp = 'skel/' + klass + @suffix
			@server = 'http://' + SET_SERV + SET_PATH
			@outfile = outfile
			@active_villages = {}
			@header = header
			@timeformat = timeformat
			
			Dir.mkdir(DIR_FEED) unless File.exist?(DIR_FEED)
			
			if active_vils != nil
				get_actived_villages(active_vils)
			elsif vil_update?
				if state =~ /\d+/
					get_state_villages(state.to_i)
				else
					get_active_villages()
				end
			end
		end
		
		def write()
			#if @active_villages.size > 0
				path = DIR_FEED + '/' + @outfile
				File.delete(path) if File.exist?(path)
				File.open(path, "w").write(build())
			#end
		end
		
		def get()
			print CGI.new.header({'type'=> @header, 'charset'=> @encoding })
			print build()
		end
		
		def get_xml()
			build()
		end
		
		def build()
			erb = Erubis::Eruby.load_file(@fp)
			erb.filename = @fp
			_ = ''
			_ << erb.result(binding)
			_
		end

		def get_active_villages()
			@active_villages = get_villages().select{|v| v['state'] != 4}.reverse
			set_vil_detail()
		end
		
		def get_state_villages(state)
			@active_villages = get_villages().select {|v| v['state'] == state}.reverse
			set_vil_detail()
		end

		def get_actived_villages(vils)
			@active_villages = vils
			set_vil_detail()
		end
		
		def get_villages()
			table = nil
			ckey = File.mtime(S[:vilsdb_path]).to_i.to_s
			cache = Cache::FileCache.new(:root_dir => S[:cache_dir] + 'feed/vildb')
			
			begin
				table = cache.get_object(ckey)
			rescue Cache::CacheMiss
				#2010/03/10:mod:tkt for copy vil db
				table = get_copy(S[:vilsdb_path], ckey, cache)
				#2010/03/10:mod:tkt for copy vil db
			end
			
			table
		end
		
		def set_vil_detail()
			@active_villages.each{|vil|
				vid = vil['vid']

				vildetail = get_vil_detail(vid)
				vil['state'] = vildetail.state
				vil['status'] = STATES[vil['state'].to_i]
				vil['players'] = vildetail.players.size
				vil['start'] = get_update_time(vildetail.update_time, vil['state'])
				
			}
		end
		
		def get_vil_detail(vid)
			vildetail = nil
			path = "db/vil/#{vid}.db"
			ckey = File.mtime(path).to_i.to_s
			cache = Cache::FileCache.new(:root_dir => S[:cache_dir] + "feed/#{vid}/")
			
			begin
				vildetail = cache.get_object(ckey)
			rescue Cache::CacheMiss
				#2010/03/10:mod:tkt for copy vil db
				vildetail = get_copy(path, ckey, cache)
				#2010/03/10:mod:tkt for copy vil db
			end
			
			vildetail
		end
		
		def get_update_time(time, state)
			update_time = time
			while ((state == Vil::State::Welcome) && update_time && update_time.to_i < Time.now.to_i) do
				update_time += S[:restart_minute].to_i * 60
			end
			
			update_time
		end
		
		#キャッシュを利用するため、DBの更新は確認しない。
		def vil_update?
			#File.exist?(@outfile) == false || timediff(File.mtime(@outfile), File.mtime(S[:vilsdb_path])) <= 0
			true
		end
		
		def timediff(time1, time2)
			(time1 - time2)
		end
		
		#2010/03/10:add:tkt for copy vil db
		def get_copy(path, ckey, cache)
			cache.clear()
			copyvil = copy_path(path)
			FileUtils.copy(path, copyvil)
			vildb = Store.new(copyvil)
			
			table = vildb.transaction(true) {  vildb['root'] }
			cache.set_object(ckey, table)
			FileUtils.rm(copyvil, {:force => true}) 
			
			table
		end
		
		def copy_path(path)
			path + (Time.now().to_i + rand(100)).to_s
		end
		#2010/03/10:mod:tkt for copy vil db
	end

	class VilsInfo < Base
		def initialize(state = '')
			super('vilsinfo.xml', nil, '%Y/%m/%d %H:%M:%S', state)
		end
		
	end

	class ActiveVils < Base
		def initialize()
			#super('active_vils.xml', '%Y/%m/%d %H:%M:%S')
			super('vilsinfo.xml', nil, '%Y/%m/%d %H:%M:%S')
			@fp = 'skel/vilsinfo' + @suffix
		end
		
	end

	class RSS20 < Base
		def initialize(state = '', active_vils = nil)
			super('villages.rss2.xml', active_vils, '%a, %d %b %Y %H:%M:%S %Z', state, 'application/rss+xml')
		end
	end

end
