module ActivePage
	
	class Base
		def initialize
			klass = self.class.to_s.gsub(/.*::/ , '').downcase
			@suffix = '.rjhtml'
			@fp = 'skel/' + klass + @suffix

			@header, @footer = false, false
		end

		def header
			_ = HEAD1

			if @title
				_ << "<title>#{GAME_TITLE} #{@title}</title>\n"
			else
				_ << "<title>#{GAME_TITLE}</title>\n"
			end

			head =  (@vil.vid) ? HEAD2.gsub(/init\(\)/, "init(#{@vil.vid})") : HEAD2
			_ << head
			# _ << @login if @login
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

	class Day < Base
		def initialize(village, player)
			super()

			@vil = village
			@player = player
		end
	end

	class SyncDay < Day
		attr_reader :discussions

		def initialize(village, player, mid, livestate)
			super(village, player)
			@mid = mid.to_i
			@livestate = (livestate == 'live') ? 0 : 1

			@discussions = @vil.discussions(@vil.date, @player, true)
		end

		def modified?
			!(@mid == @discussions.size)
		end

		def nonmatch?
			@mid > @discussions.size
		end

		def livestate_unmatch?
			@player.dead != @livestate
		end

		def need_actbox_resync?
			ret = false
			dis = @discussions[0, @discussions.size - @mid].join.chomp
			%w(announce nextra system vote room apology).each {|sysword|
				if dis.index(sysword)
					ret = true
					break
				end
			}

			ret
		end

		def sync
			@discussions = @vil.discussions(@vil.date, @player, true)
		end

		def not_modified
			"Status: 204 No Content\n\n"
		end

		def bgimage
			fn = \
				case @vil.phase
				when Vil::Phase::Sun then 'sun'
				when Vil::Phase::Morning then 'sun'
				when Vil::Phase::Night then 'night'
				else
					'prenight'
				end

			S[:image_dir] + "phase_#{fn}.png"
		end
	end

	class VilHeader < Base
		def initialize(village)
			super()
			@vil = village
			@header = true
			@title = "#{@vil.vid} #{@vil.name}"
		end

		def header
			_ = super
			_.sub(/^<body(.*)>/) {
				%Q(<body#{$1} class="phase#{@vil.phase}">)
			}
		end
	end

	class TimeLine < Base
		def initialize(village)
			super()
			@vil = village
		end
	end

	class ActionBalloon < Base
		attr_reader :state

		def initialize(login, player, village)
			super()

			@login = login
			@player = player
			@vil = village
			klass = (@player.dead == 0) ? 'msg' : 'rip'
			@state = _state()

			@fp = 'skel/' + klass + @suffix
		end

		def result?(state)
			s = _state()
			#(%w(prevote vote room apology finalvote).index(s) || s != state) mod 2008/10/16 tkt
			(%w(prevote vote room apology finalvote night).index(s) || s != state)
		end

		def sync_result
			result().gsub(%r{<div id="player_wrap">\n<div id="player">(.*)</div>}m, '\1')
		end

		private

		def _state
			@state = __state()
			@state
		end

		def __state
			case @vil.phase
			when Vil::Phase::PreVote then 'prevote'
			when Vil::Phase::Vote then 'vote'
			when Vil::Phase::Room then 'room'
			when Vil::Phase::AfterRoom then 'afterroom'
			when Vil::Phase::Apology then 'apology'
			when Vil::Phase::FinalVote then 'finalvote'
			when Vil::Phase::Night then 'night'
			when Vil::Phase::Morning then 'morning'
			else
				'std'
			end
		end
	end

	class Order < Base
		def initialize(vil)
			super()

			@vil = vil
			@up = @vil.update_time

			dt = Time.at(@up - Time.now)
			dm, ds = dt.strftime("%M %S").split(' ')
			h, m, s = @up.strftime("%H %M %S").split(' ')

			@orders = [c(SHOW_UPDATE, h.sub(/^0/, ''), m, s, dm.sub(/^0/, ''), ds.sub(/^0/, ''))]

			case vil.state 
			when Vil::State::Welcome
				#2009/01/25 mod tkt for min_entries by coretime|| min_entries = (@vil.first_restart) ? S[:min_entries] : S[:apply_advance_num]
				#2009/12/27 mod tkt for min_entries by configuration
				min_entries = (@vil.first_restart) ? min_entries_num(@up) : S[:apply_advance_num]
				@orders << c(SHOW_UPDATE_PR, @vil.players.size, min_entries)
				size = @vil.discussion_size(0)
				if size > S[:log_max] - 50
					@orders << c(SHOW_WASTE, size)
				end
			when Vil::State::Party
				@orders << c(SHOW_WINNER, @vil.winner)
			end
		end

		def sync_result
			result().gsub(%r{<div id="order">(.*)</div>}m, '\1')
		end
	end

	class SkillWhisper < Base
		def initialize(village, player)
			super()

			@vil = village
			@player = player
		end

		def sync_result
			result().gsub(%r{<div id="whisper_box-wrap">(.*)</div>}m, '\1')
		end
	end

end
