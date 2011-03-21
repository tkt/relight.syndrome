module Page
	
	class Base
		def initialize
			klass = self.class.to_s.gsub(/.*::/ , '').downcase
			@suffix = '.rhtml'
			@fp = 'skel/' + klass + @suffix

			@header, @footer = true, true
		end

		def header
			_ = HEAD1

			if @title
				_ << "<title>#{GAME_TITLE} #{@title}</title>\n"
			else
				_ << "<title>#{GAME_TITLE}</title>\n"
			end

			_ << HEAD2.sub(/<body.*/, '<body>')
			_ << HEAD3
			_ << @login if @login
			_
		end

		def footer
			FOOT + "</div></body></html>"
		end

		def result
			erb = Erubis::Eruby.load_file(@fp)
			# erb = ERB.new(File.read(@fp))
			erb.filename = @fp
			_ = ''
			_ << header() if @header
			_ << erb.result(binding)
			_ << footer() if @footer
			_
		end
	end

	class Index < Base
		#mod@tkt 2009/12/30 :def initialize(login, changes, villages)
		def initialize(login, changes, villages, addr)
			super()
			@footer = false

			@login = login
			changes = changes.sort {|x, y| y[0] <=> x[0]}
			@changes = changes[0, S[:index_info]]
			@villages = villages.reverse.each {|v|
				np = (v['state'] == 0) ? DB::Village.players(v['vid']).size : ''
				v['state_str'] = STATES[v['state']]
				if v['state'] < Vil::State::Ready
					v['state_str'] += "<br>（#{np.to_s}/#{S[:max_entries]}）"
				end
				v['start_str'] = v['start'].strftime("%H時%M分")
			}
			#add@tkt 2009/12/30 for access check start
			require 'ms/access'
			@access_num = Access::Check.new(addr).result()
			#add@tkt 2009/12/30 for access check end
		end
	end

	class LogIndex < Base
		#mod@tkt 2009/12/29 def initialize(login)
		def initialize(login, logindex)
			require 'cache'
			super()
			
			ckey = File.mtime(S[:vilsdb_path]).to_i.to_s
			cache = Cache::FileCache.new(:root_dir => S[:cache_dir] + 'log/')

			begin
				@villages = cache.get_object(ckey)
			rescue Cache::CacheMiss
				cache.clear()
				@villages = DB::Villages.select {|v| v['state'] == 4 }
				cache.set_object(ckey, @villages)
			end

			#add@tkt 2009/12/29:for log seperate start
			if S[:log_separate]
				log(logindex)
			else
				reverse()
			end
       		#add@tkt 2009/12/29:for log seperate end
			@login = login
			@title = '終了した村の記録'
		end
		
		#add@tkt 2009/12/29:for log separate start
		def log(logindex)
			initilize_log(logindex)
			separates()
			if @logindex == ''
				recently()
			elsif @logindex == 0
			
			else
				order_logindex()
			end
		end
		
		def initilize_log(logindex)
			@logindex = (logindex == '') ? logindex : logindex.to_i
			@logsize = S[:log_size]
			@last_vid = get_recently_index() - 1
		end
		
		def separates()
			@separates = []
			separate = @villages.size / @logsize
			if @villages.size % @logsize == 0 
				separate -= 1
			end
			
			index = 0
			while index <= separate
				@separates[index] = index * @logsize + 1
				index += 1
			end
		end
		
	    def recently()
			max = @villages.size + 1
			min = get_min_index(max)
			limit(min, max)
			reverse()
	    end
	    
	    def order_logindex()
			min = @logindex.to_i
	    	max = get_max_index(min)
			limit(min, max)
	    end

	    def get_min_index(max)
	      min = 1
	      if max >= @logsize
	        min = max - @logsize
	      end
	      min
	    end
	    def get_max_index(min)
	      max = min + @logsize
	      if max > @villages.size
	      	max = @villages.size + 1
	      end
	      max
	    end
	    
	    def get_recently_index()
			recent = 1
			vldb = Store.new('db/vil.db')
			vldb.transaction do
				recent = vldb['recent_vid'].to_i
			end
			recent
	    end
	    
	    def limit(startIndex, endIndex)
			@villages.delete_if{|v|
				(startIndex > v['vid'].to_i || v['vid'].to_i >= endIndex)
			}
	    end
	    
	    def reverse()
			@villages.reverse!
	    end
	    #add@tkt 2009/12/29:for log separate end
	end

	class History < Base
		def initialize(login, history)
			super()

			@login = login
			@title = '開発履歴'
			@history = history
		end
	end

	class Info < Base
		def initialize(login, changes)
			super()

			@login = login
			@title = 'お知らせ'
			@changes = changes
		end
	end

	class MakeVillage < Base
		def initialize(login)
			super()

			@login = login
			@title = '村を作成する'
		end
	end

	class CharList < Base
		def initialize(login, chars)
			super()

			@login = login
			@title = 'キャラクター一覧'
			@chars = chars
		end
	end

	class Document < Base
		def initialize(login)
			super()

			@login = login
			@title = 'しおり'
		end
	end

	#tkt@add:2011/03/20 for custom rule page start
	class DocumentCustom < Base
		def initialize(login)
			super()

			@login = login
			@title = '追加ルール'
		end
	end
	#tkt@add:2011/03/20 for custom rule page end
	
	class Regulation < Base
		def initialize(login)
			require 'cache'
			super()

			ckey = File.mtime(S[:reg_file]).to_i.to_s
			cache = Cache::FileCache.new(:root_dir => S[:cache_dir] + 'reg/')

			begin
				@table = cache.get_object(ckey)
			rescue Cache::CacheMiss
				cache.clear()
				@table = {}
				Vil::Regulation::Table.keys().sort.each {|num|
					@table[num] = Vil::Regulation.to_str(num)
				}
				cache.set_object(ckey, @table)
			end

			@login = login
			@title = '役職配分一覧'
		end
	end

	class Day < Base
		def initialize(login, village, date, player)
			super()
			@footer = false

			@login = login
			@vil = village
			@date = date
			@player = player
			@title = "#{@vil.vid} #{@vil.name}"
		end
	end

	class ActionBalloon < Base
		def initialize(player, login, village)
			super()

			@header, @footer = false, false
			@player = player
			@login = login
			@vil = village
			@lockid = LockID.new

			klass = 'entry'

			@fp = 'skel/' + klass + @suffix
		end
	end

	class Order < Base
		def initialize(login, vil)
			super()
			@header, @footer = false, false

			@login = login
			@vil = vil
			@up = @vil.update_time
			@orders = (vil.state == 3) ? show_winner() : show_update()
			@orders << PLEASE_LOGIN unless @login.login
		end


		private

		def show_winner
			[c(SHOW_WINNER_STATIC, @vil.winner, @up.hour, @up.min)]
		end

		def show_update
			_ = []

			if @vil.state == Vil::State::Welcome
				#2009/01/25 mod tkt for min_entries by coretime|| min_entries = (@vil.first_restart) ? S[:min_entries] : S[:apply_advance_num]
				#2009/12/27 mod tkt for min_entries by configuration
				min_entries = (@vil.first_restart) ? min_entries_num(@up) : S[:apply_advance_num]
				_ << c(SHOW_UPDATE_PR_STATIC, @up.hour, @up.min, @up.sec, min_entries)
			else
				_ << c(SHOW_UPDATE_STATIC, @up.hour, @up.min, @up.sec)
			end
			_
		end
	end

end
