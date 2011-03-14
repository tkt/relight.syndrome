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
		def initialize(login, changes, villages)
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
		end
	end

	class LogIndex < Base
		def initialize(login)
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

			@login = login
			@title = '終了した村の記録'
		end
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
				min_entries = (@vil.first_restart) ? min_entries_num(@up, true) : S[:apply_advance_num]
				_ << c(SHOW_UPDATE_PR_STATIC, @up.hour, @up.min, @up.sec, min_entries)
			else
				_ << c(SHOW_UPDATE_STATIC, @up.hour, @up.min, @up.sec)
			end
			_
		end
	end

end
