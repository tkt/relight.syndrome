class Vil
	MesRegex = /^<div class="message"><div class="([a-z]+)(\d+)">/
	ExtRegex = /^<div class="message"><!--([a-z]+)(\d+)-->/

	attr_reader :name, :date, :vid, :state, :players, :rule
	attr_reader :userid, :winner, :phase, :rooms, :voting
	#2011/07/29 mod:tkt for lost start
	attr_reader :first_restart, :guard, :lost_guard
	#2011/07/29 mod:tkt for lost end
	
	attr_accessor :update_time

	def initialize(name, vid, userid, update_time)
		@name, @vid, @date, @state = name, vid, 0, 0
		@userid, @update_time = userid, update_time
		@first_restart = false

		@players = Players.new
		@rooms = Rooms.new
		@period = S[:std_period] # minute
		# night_period = @period / 2
		@phase = Phase::Sun
		@prevote = true
		@voting = []
		
		#2011/07/29 mod:tkt for lost start
		@lost_guard = false
		#2011/07/29 mod:tkt for lost end
	end

	def start
		addlog(announce(OPENING))

		player = Player.new(1, MASTER, 0)
		#2011/02/23 mod:tkt for anniversary start
		add_player(player, specified_start_message('GERT_ENTRY'))
		#2011/02/23 mod:tkt for anniversary end
	end

	def restart
		return if @state >= State::Progress

		if discussions(@date, @players.player(1)).size > S[:log_max]
			do_quit()
			change_state_sync(State::End)
		else
			pl_dels = []
			@players.all.each {|p|
				next if p.pid == 1

				if (p.lastmsg_time && \
					 p.lastmsg_time < Time.now() - (S[:restart_minute] * 60))

					pl_dels << p.name
					@players.exit(p)
				end
				change_state_sync(State::Welcome)
			}

			#addlog(wsystem(c(AUTO_PARTING, pl_dels.join('、')))) if pl_dels != [] mod 2009/01/17
			addlog(wsystem(c(AUTO_PARTING, pl_dels.join('、'),Time.now.strftime(PARTING_TIME)))) if pl_dels != []
			
			while @update_time < Time.now do
				@update_time += S[:restart_minute] * 60
			end

			DB::Villages.restart(@vid, @update_time)
		end
	end

	def add_player(player, message)
		@players.add(player)
		change_state_sync(State::Ready) if @players.size == @players.max

		addlog(wsystem(c(JOINING, player.name)))
		record("say", player, message)
	end

	def delete_player(player)
		#addlog(wsystem(c(PARTING, player.name))) mod 2009/01/17 tkt
		addlog(wsystem(c(PARTING, player.name,Time.now.strftime(PARTING_TIME))))

		@players.exit(player)
		change_state_sync(State::Welcome)
	end

	def change_state_sync(st)
		@state = st
		DB::Villages.change_state(@vid, st)
	end

	def need_sync?
		(@state < State::End && @update_time.to_i < Time.now.to_i)
	end

	def sync
		if (@state == State::Welcome && !@players.adv_ready?)
			if (@first_restart && @players.ready?)
				update()
			else
				@first_restart = true
				restart()
			end
		else
			update()
		end
	end

	def timeline
		(0..@date).collect {|i| datestr(i) }
	end

	def discussion_size(date)  # use this, prologue only.
		IO.readlines("db/vil/#{@vid}_#{date}.html").size
	end

	def discussions(date, player, reverse = false)
		ary = IO.readlines("db/vil/#{@vid}_#{date}.html")
		ary.reverse! if reverse

		ary.collect {|line|
			if (@state < State::Party && (line =~ MesRegex || line =~ ExtRegex))
				next if (!player && $1 != 'say')

				if (player && !player.admin?)
					pid = $2.to_i
					# night pid is room-number
					case $1
					when 'whisper' then next unless player.can_whisper
					when 'god'     then next unless (player.pid == pid || player.can_whisper)
					when 'groan'   then next unless player.dead?
					when 'night'   then next unless @rooms.in?(date, pid, player.pid)
					when 'nextra'  then next unless @rooms.in?(date, pid, player.pid)
					end
				end
			end
			line.chomp + "\n"
		}.compact
	end

	def now_voting?
		!@voting.empty? && @phase != Phase::Apology
	end
	private :now_voting?

	def record(type, player, msg, face = nil)
		face = "face#{player.color}" if !face
		player.cnt[@date] += 1 if (@phase == Phase::Sun && type == 'say')
		player.lastmsg_time = Time.now() if @state < State::Progress

		# PreVote || Vote || FinalVote || Room || AfterRoom || Morning
		if (player.live? && (type == 'say' || type == 'night') && [1, 2, 4, 5, 6, 8].index(@phase))
			raise ErrorMsg.new('フェイズと発言種類が合致しません')
		end

		type = 'night' if (@phase == Phase::Night && type == 'say')
		type = 'groan' if (player.dead? && (type == 'say' || type =='night'))
		type = 'say' if (player.live? && type == 'groan')
		type = 'say' if (@state >= State::Party && type != 'say')

		c = player.pid
		if type == 'night'
			@rooms.last.each_with_index {|ary, i|
				c  = i if ary.index(player.pid)
			}
		end
		typec = type + c.to_s

		# don't insert \n in message, cause this line in convert to JSON.
		s = \
		%Q(<div class="#{typec}">) + \
		%Q(<div class="#{type}">#{player.name}) + \
		%Q(<table class="message_box"><tr>) + \
		%Q(<td width="40"><img src="#{S[:char_image_dir]}#{face}.jpg"></td>) + \
		%Q(<td width="16"><img src="#{S[:image_dir]}#{type}00.jpg"></td>) + \
		%Q(<td><div class="mes_#{type}_body0">) + \
		%Q(<div class="mes_#{type}_body1">#{msg}</div>) + \
		%Q(</div></td>) + \
		%Q(</tr></table></div></div>\n)

		raise ErrorMsg.new('夜ではありません') if (@phase != Phase::Night && type == 'night')

		addlog(message(s))
	end

	def vtargets
		@_targets || @players.lives()
	end


	private

	# End or Quit
	#######################################################

	def do_quit
		addlog(announce(SYSTEM_EXIT))
		a = Array.new

		@players.all().each {|p|
			alive = (p.dead == 0) ? '生存' : '死亡'
			sk = (@date == 0) ? '役職決定前' : p.skill.name

			a.push(c(TRUTH, p.name, p.userid, alive, sk))
		}

		addlog(announce(a.join('<br>')))
		do_end()
	end

	def do_end
		@date += 1
		addlog(announce('終了しました'))
		DB::Villages.finish(@vid, @players.keys.size)
		DB::Users.registlast(@vid, @players.keys)
		Sweeper.sweep(self)
	end


	# Internal periodic work methods
	#######################################################

	def up_sudden_death
		@players.silents().each {|p|
			p.sudden_death(@date)
			addlog(announce(c(SUDDEN_DEATH, p.name)))
		}
	end

	def up_vote()
		s, votes = [], {}
		max = 0
		@players.votes.each {|ary|
			p, t = ary
			s << [p.name, t.name].join(' &raquo; ')
			votes[t] = votes[t].to_i + 1
			max = votes[t] if (votes[t] > max)
		}

		s << ''
		result = votes.select {|k, v| v == max }
		result.collect! {|ary| ary[0] }
		votes.each_pair {|p, n| s << c(ANON_VOTING, n, p.name) }
		addlog(announce(s.join('<br>')))

		result
	end

	def up_gameover
		do_end = false

		wcnt = @players.wolves().size
		vcnt = @players.villagers().size

		if (wcnt == 0 || vcnt == 0)
			if (@players.select_skill(7).size > 0)
				w = (wcnt == 0) ? YOKO_WIN_F : YOKO_WIN_W
				@winner = '妖魔'
				addlog(announce(w))
			elsif (wcnt == 0)
				@winner = '村人'
				addlog(announce(FOLK_WIN))
			else
				@winner = '人狼'
				addlog(announce(WOLF_WIN))
			end
			do_end = true
		elsif @date == @guard
			@winner = '村人'
			addlog(announce(GUARD_WIN))
			do_end = true
		elsif @players.lives().size < 3
			exe = @players.select_skill(Skill::Exorcist)
			pas = @players.select_skill(Skill::Pastor)

			if ((exe.empty? || exe.first.skill.pass == false) && \
				((pas.empty? || pas.first.skill.pass == false) || \
				 (pas.first.skill.pass && @date + 1 != @guard)))

				@winner = '人狼'
				addlog(announce(WOLF_WIN))
			else
				@winner = '村人'
				addlog(announce(FOLK_WIN))
			end
			do_end = true
		end
		
		if do_end
			change_state_sync(State::Party)

			a = Array.new
			@players.all().each {|p|
				alive = (p.dead == 0) ? '生存' : '死亡'
				a.push(c(TRUTH, p.name, p.userid, alive, p.skill.name))
			}
			addlog(announce(a.join('<br>')))

			@players.open_party()
		
			#2011/02/23 add:tkt for anniversary start
			if @lost_guard
				addlog(wsystem(c(specified_message('GUARD_DATE'), @guard - 1, @guard)))
			end
			#2011/02/23 add:tkt for anniversary end
		end
	end

	def up_showlives(include_gert = true)
		# Players@show_lives(), wtls
		pls = @players.lives()
		pls.delete(@players.player(1)) unless include_gert
		s = c(LIVES, pls.collect {|p| p.name }.join('、'), pls.size)
		addlog(announce(s))
	end

	def up_uptime(period = @period)
		$logger.debug('from: ' + @update_time.inspect)
		if @update_time > Time.now
			@update_time = Time.now + (period * 60)
		else
			@update_time += period * 60
		end
		while (@update_time && @update_time.to_i < Time.now.to_i) do
			@update_time += period * 60
		end
		$logger.debug('to: ' + @update_time.inspect)
	end


	# Update methods
	#######################################################

	def update(nocnt = nil)
		return if (@state == State::End)

		if (@state == State::Party || nocnt)
			change_state_sync(State::End)
			(nocnt) ? do_quit() : do_end()
			up_uptime()
			return
		end

		(@date == 0) ? first_update() : _update()
	end
	public :update

	def _update
		case @phase
		when Phase::Sun
			end_sun()
			if @date == 1
				start_room()
			elsif @prevote
				start_prevote()
			else
				start_vote()
			end
		when Phase::PreVote
			do_prevote()
			if @voting.empty?
				end_prevote()
				(@prevote) ? start_room() : start_vote()
			end
		when Phase::Vote
			do_vote()
			if @voting.empty?
				picked = end_vote()

				if picked.size > 1
					if picked.size == @players.lives().size
						addlog(announce(STOP_EXECUTION))
						start_room()
					else
						@_targets = picked.dup
						if ((@players.lives().size - picked.size) % 2) == 0
							start_apology(picked)
						else
							start_finalvote()
						end
					end
				else
					start_room()
				end
			end
		when Phase::Apology
			do_apology()
			if @voting.empty?
				end_apology()
				start_finalvote()
			end
		when Phase::FinalVote
			do_finalvote()
			if @voting.empty?
				end_finalvote()
				start_room()
			end
		when Phase::Room
			if @voting.empty?
				end_room()
				start_afterroom()
			else
				do_room()

				if @voting.size <= 3
					finalize_room()
					end_room()
					start_afterroom()
				end
			end
		when Phase::AfterRoom
			end_afterroom()
			start_night()
		when Phase::Night
			end_night()
			if @state == State::Party
				start_sun()
			elsif @players.lives().size > 2
				start_morning()
			else
				start_sun()
			end
		when Phase::Morning
			end_morning()
			start_sun()
		end
	end

	def first_update
		up_uptime()
		@date += 1
		@players.reset_count(@date)
		#2011/07/29 mod:tkt for lost start
		@rule = Regulation.rule(@players.size)
		@lost_guard = lost?
		#2011/07/29 mod:tkt for lost end
		
		@players.skill_mapping()
		#2011/02/23 mod:tkt for anniversary start
		@guard = guard_date()
		#2011/02/23 mod:tkt for anniversary end
		change_state_sync(State::Progress)

		#2011/02/23 mod:tkt for anniversary start
		addlog(announce(specified_message('START')))
		#2011/02/23 mod:tkt for anniversary end
		up_showlives(false)
		
		#2011/02/23 mod:tkt for anniversary start
		$logger.debug("specified?(#{specified?}) @lost_guard(#{@lost_guard}) guard(#{@guard})  date(#{@date}) limit(#{(@guard - @date)}->#{(@guard - @date + 1)})")
		record('say', @players.player(1), c(specified_message('GERT_FIRST'), @guard - @date, @guard - @date + 1))
		#2011/02/23 mod:tkt for anniversary end
		@players.player(1).dead = 1  # die, not use Player#kill()

		wolves = @players.wolves()
		whisper = (wolves.size == 1) ? FIRST_WHISPER_LW : FIRST_WHISPER
		wolves.each {|w| record('whisper', w, whisper) }
	end


	# Phase methods
	#######################################################

	def start_sun
		#mod 2008/11/08 tkt : for epilogue time change, yes, i know this code is not good...
		#to-do attached plyaers.size and period time
		#period = (@state == State::Party) ? S[:epilogue_period] : @period
		period = @period
		if @state == State::Party
			period = 1 * @players.size * (@date - 1)
			$logger.debug("epilogue_period#{period}  plaersize#{@players.size} date#{(@date - 1)}")
			if period < S[:epilogue_period_min]
				period = S[:epilogue_period_min]
			elsif (@players.size >= 8 || (period > S[:epilogue_period]))
				period = S[:epilogue_period]
			end
			#period = (@state == State::Party) ? period_epi : @period		
		end
		
		#mod 2008/11/08 end
		
		up_uptime(period)
		# up_uptime(@period)
		@phase = Phase::Sun
		unless @state == State::Party
			limit = @guard - @date
			#2011/02/23 mod:tkt for anniversary start
			addlog(wsystem(c(specified_message('SUN_PHASE'), limit)))
			#2011/02/23 mod:tkt for anniversary end
		end
	end

	def end_sun
		up_sudden_death() unless $DEBUG
		addlog(wsystem(SUNSET_PHASE))
	end

	def start_prevote
		up_uptime(S[:vote_period])
		@phase = Phase::PreVote
		@voting = @players.lives().shuffle
		addlog(wsystem(c(PREVOTE_PHASE, @voting.collect {|p| p.sname }.join(' &raquo; '))))
		addlog(vote(c(ANN_VOTING, @voting.first.name)))
	end

	def do_prevote
		up_uptime(S[:vote_period])
		pl = @voting.shift
		res = (pl.prevote) ? '賛成' : '反対'
		@players.vote_map([pl, res])
		addlog(vote_res(c(VOTING, pl.name, res)))
		addlog(vote(c(ANN_VOTING, @voting.first.name))) unless @voting.empty?
	end

	def end_prevote
		result = @players.collect_prevote()
		vote = result.pop
		@prevote = (vote['result']) ? false : true

		s = ''
		@players.votes.each {|pl, |
			t = (pl.prevote) ? '賛成した' : '反対した'
			s << %Q(#{pl.name}は、投票に#{t}<br />)
		}
		s << "<br />賛成に#{vote['approve']}票、反対に#{vote['object']}票、"
		t = (vote['result']) ? '処刑を実施することになった。' : '処刑は保留された。'
		s << t + '<br />'

		addlog(announce(s))
	end

	def start_vote
		up_uptime(S[:vote_period])
		@players.reset_cmd()
		@phase = Phase::Vote
		@voting = @players.lives().shuffle
		addlog(wsystem(c(VOTE_PHASE, @voting.collect {|p| p.sname }.join(' &raquo; '))))
		addlog(vote(c(ANN_VOTING, @voting.first.name)))
	end

	def do_vote
		up_uptime(S[:vote_period])
		pl = @voting.shift
		pl.vote_suffle(@players.lives()) unless pl.vote
		target = @players.player(pl.vote)
		@players.vote_map([pl, target])
		addlog(vote_res(c(VOTING, pl.name, target.name)))
		addlog(vote(c(ANN_VOTING, @voting.first.name))) unless @voting.empty?
	end

	def end_vote
		picked = up_vote()

		if picked.size == 1
			addlog(announce(c(EXECUTION, picked.first.name)))
			picked.first.execute(@date)
		end

		picked
	end

	def start_apology(targets)
		up_uptime(@period / 3.0)
		@phase = Phase::Apology
		@voting = @_targets.shuffle
		x = targets.collect {|t| t.name}.join('と、')
		addlog(wsystem(c(APOLOGY_PHASE, x, @voting.collect {|p| p.sname }.join(' &raquo; '))))
		addlog(apology(c(APOLOGY_START, @voting.first.name)))
	end

	def do_apology
		up_uptime(@period / 3.0)
		@voting.shift
		addlog(apology(c(APOLOGY_START, @voting.first.name))) unless @voting.empty?
	end

	def end_apology
	end

	def start_finalvote
		up_uptime(S[:vote_period])
		@players.reset_cmd()
		@phase = Phase::FinalVote
		@voting = @players.lives().shuffle - @_targets
		x = @_targets.collect {|t| t.name}.join('と、')
		addlog(wsystem(c(FINALVOTE_PHASE, x, @voting.collect {|p| p.sname }.join(' &raquo; '))))
		addlog(vote(c(ANN_VOTING, @voting.first.name)))
	end

	def do_finalvote
		up_uptime(S[:vote_period])
		pl = @voting.shift
		pl.vote_suffle(vtargets()) unless pl.vote
		target = @players.player(pl.vote)
		@players.vote_map([pl, target])
		addlog(vote_res(c(VOTING, pl.name, target.name)))
		addlog(vote(c(ANN_VOTING, @voting.first.name))) unless @voting.empty?
	end

	def end_finalvote
		picked = up_vote()

		if picked.size == 1
			addlog(announce(c(EXECUTION, picked.first.name)))
			picked.first.execute(@date)
		else
			addlog(announce(STOP_EXECUTION))
		end

		@_targets = nil
	end

	def start_room
		@phase = Phase::Room
		@players.reset_cmd()
		@voting = @players.lives().shuffle
		addlog(wsystem(c(ROOM_PHASE, @voting.collect {|p| p.sname }.join(' &raquo; '))))
		if @voting.size <= 3
			finalize_room()
			end_room()
			start_afterroom()
		else
			up_uptime(S[:vote_period])
			addlog(room(c(ANN_ROOM_VOTING, @voting.first.name)))
		end
	end

	def do_room
		pl = @voting.shift
		if (!pl.vote || pl.vote == pl.pid)
			targets = @voting.select {|t| !pl.yesterday_mate.index(t.pid) }
			pl.vote_suffle(targets)
		end
		mate = @players.player(pl.vote)
		addlog(room_res(c(ROOM_VOTING, pl.name, mate.name)))

		@voting.delete(mate)
		#if (@rule == Rule::Standard || @date != 1) mod 2008/11/08 tkt:change rule for 3 members room
		if (@date != 1 || (@rule == Rule::Standard && (@players.size % 2 == 0)))
			@players.room_map([pl, mate])
		else # Advance
			last_room = @players.mates.last
			if (last_room && last_room.size == 2)
				lr = last_room.dup
				lr.push(mate)
				names = lr.map {|pl| pl.name }
				addlog(room_res2(c(ROOM_RESULT_ADV, names.join('と、'))))
				@players.room_remap(lr)
				# last room mate added, go next
			else
				@players.room_map([pl, mate])
				@voting.unshift(mate) unless @voting.size < 3
				# not filled in the room
			end
		end

		unless (@voting.empty? || @voting.size <= 3)
			up_uptime(S[:vote_period])
			addlog(room(c(ANN_ROOM_VOTING, @voting.first.name)))
		end
		@players.vote_suffle(@voting) unless @voting.empty? 
	end

	def finalize_room
		@players.room_map(@voting.dup)
		x = @voting.collect {|p| p.name}.join('と、')
		addlog(room_res(c(BUSH_ROOM, x)))
		last = nil

		until @voting.empty?
			if @voting.size == 1
				pl = @voting.shift
				pl.vote = last.pid
			else
				pl = @voting.shift
				mate = @voting.shift
				pl.vote = mate.pid
				mate.vote = pl.pid

				last = mate
			end
		end
	end

	def end_room
		@rooms.push([])
		result = @players.room_mapping()
		result.each {|room_mates| @rooms.last << room_mates.collect {|x| x.pid } }

		s = ROOM_RESULT
		last = result.pop
		result.each {|room_mates|
			s << room_mates.collect {|x| x.name }.join(' &raquo; ') + '<br />'
		}
		s << last.collect {|x| x.name }.join('、') + '<br />'

		addlog(announce(s))
	end

	def start_afterroom
		up_uptime(S[:vote_period])
		@phase = Phase::AfterRoom
		addlog(wsystem(AFTERROOM_PHASE))
	end

	def end_afterroom
	end

	def start_night
		up_uptime()
		@phase = Phase::Night
		addlog(wsystem(NIGHT_PHASE))
	end

	def end_night
		@players.end_action(self)
		logremap()

		@date += 1
		@players.reset_count(@date)
		@prevote = false if (@prevote && @players.deads().size > 1)

		s = ROOM_YESTERDAY
		yesterday_room = @rooms[@date - 2].dup
		last = yesterday_room.pop
		yesterday_room.each {|room_mates|
			s << room_mates.collect {|x| @players.player(x).name }.join(' &raquo; ') + '<br />'
		}
		s << last.collect {|x| @players.player(x).name }.join('、') + '<br />'

		addlog(wsystem(s))

		deads = @players.killed(@date-1)
		if deads.empty?
			addlog(announce(KILLMISS))
		else
			_ = deads.collect {|pl| pl.name }.join('と、')
			addlog(announce(c(KILLED, _)))
		end

		up_gameover()

		return if @state == 3

		up_showlives()
	end

	def start_morning
		up_uptime(S[:vote_period] + 0.2)
		@phase = Phase::Morning
		addlog(wsystem(MORNING_PHASE))
	end

	def end_morning
	end


	# Misc methods
	#######################################################

	def addlog(msg)
		File.open("db/vil/#{@vid}_#{@date}.html", 'a') {|of|
			of.flock(File::LOCK_EX)
			of.print(msg)
			of.flock(File::LOCK_UN)
		}
	end
	public :addlog  # FIXME! ==> sysrecord

	def logremap
		$logger.debug('restructuring log...')
		s = File.read("db/vil/#{@vid}_#{@date}.html")
		msgs = _logremap(s)

		File.open("db/vil/#{@vid}_#{@date}.html", 'w') {|of|
			of.flock(File::LOCK_EX)
			of.print(msgs)
			of.flock(File::LOCK_UN)
		}
	end
	
	def _logremap(str)
		_ = ''
		ary = str.split("\n")
		loop {
			line = ary.shift
			_ << line + "\n"

			break if line =~ /^<div class="message"><div class="system">#{NIGHT_PHASE}/o
		}

		night_hash = _logremap_night(ary)
		keys = night_hash.keys
		keys.delete('groan')
		keys.sort.each {|key|
			members = @rooms.members(@date, key).collect {|i| @players.player(i).name }
			_ << wsystem(c(ROOM_HEAD, members.join('、'))) + "\n"
			_ << night_hash[key].join("\n") + "\n"
		}
		_ << wsystem(GROAN_HEAD) + "\n"
		_ << night_hash['groan'].join("\n") + "\n"
		_
	end

	def _logremap_night(night_ary)
		h = {'groan' => []}
		night_ary.each {|line|
			if (line =~ MesRegex || line =~ ExtRegex)
				pid = $2.to_i
				case $1
				when /(night)|(nextra)/
					h[pid] = [] unless h.has_key?(pid)
					h[pid] << line
				when /(whisper)|(god)/
					num = @rooms.number(@date, pid)
					h[num] = [] unless h.has_key?(num)
					h[num] << line
				when 'groan'
					h['groan'] << line
				when 'say'
					$logger.debug('state lock bug?')
					$logger.debug(line)
					# raise 'Must not happen.'
				end
			else
				$logger.debug('multiple logremap bug?')
				$logger.debug(line)
				# raise 'Must not happen.'
			end
		}
		h
	end

	def datestr(date)
		if date == 0
			'プロローグ'
		elsif (@state == State::End && date + 1 >= @date)
			(date == @date) ? '終了' : 'エピローグ'
		elsif (@state == State::Party && date == @date)
			'エピローグ'
		else
			"#{date}日目"
		end
	end
	
	#2011/02/23 add:tkt for anniversary start
	#2011/07/29 mod:tkt for lost start
	def specified?
		S[:specified_vils].index(@vid.to_s) != nil
	end
	
	def lost?
		S[:specified_lost] && (@rule == Rule::Advance) && (specified? || (rand(2) == 1))
	end
	
	def specified_message(default)
		if @lost_guard
			specified_start_message(default)
		else
			eval(default)
		end
	end
	
	def specified_start_message(default)
		if @lost_guard
			eval(default + '_LOST')
		else
			eval(default)
		end
	end
	
	def guard_date
		date = Regulation.guard(@players.size, @players.wolves().size)
		if @lost_guard
			date += rand(3)
		end
		
		date
	end
	#2011/07/29 mod:tkt for lost end
	
	#2011/02/23 add:tkt for anniversary end

end
