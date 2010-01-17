$KCODE = 'u'
require 'logger'
$logger = Logger.new('db/debug.log')
$logger.progname = "wtls"

class CWolf
	def get_ronly_vil(vid)
		@vildb.transaction(true) { @vildb['root'] }
	end

	def get_vil(vid)
		@vildb['root']
	end

	def initialize
		@req = CGI.new()
		if File.exist?('db/.dontdelete')
			@vid = @req['vid'].to_i
			@vildb = Store.new("db/vil/#{@vid}.db")
			$logger = Logger.new('db/debug.log.' + @vid.to_s)
			$logger.progname = "wtls"
			# $logger.level = Logger::INFO
		end
		@headered = false
		@head = "Content-Type: text/html; charset=utf-8\r\n"
	end

	def handle_make
		raise ErrorMsg.new('ログインして下さい') if !@login.login
		raise ErrorMsg.new('村の名前を指定して下さい') if (@req['name'].to_s == '')
		raise ErrorMsg.new('村の名前が長すぎます') if (@req['name'].to_s.size > 60)

		_build_village(CGI.escapeHTML(@req['name']))
	end

	def build_village
		names = IO.readlines(S[:vilnames_path])
		name = names[rand(names.size)].chomp

		_build_village(name)
	end

	def _build_village(vilname)
		now = Time.now
		update_time = Time.mktime(00, 00, now.hour,
			now.day, now.month, now.year, nil, nil, nil, nil)
		period = 1 * 60 * 20

		while update_time < now
			update_time += period
		end
		update_time += period / 2 if update_time - (period / 2) < now

		begin
			vldb = Store.new('db/vil.db')
			vid = vldb.transaction do
				vid = vldb['recent_vid'].to_i + 1
				vldb['recent_vid'] = vid

				vil = Hash.new
				vil['name'] = vilname
				vil['vid'] = vid
				vil['state'] = 0
				vil['start'] = update_time
				vldb['root'].push(vil)

				vid
			end

			@vildb = Store.new("db/vil/#{vid}.db")
			vil = @vildb.transaction {
				vil = Vil.new(vilname, vid, @login.userid, update_time)
				@vildb['root'] = vil
				vil.start()
				vil
			}
		end
	end

	def handle_post
		raise ErrorMsg.new("不正な村IDです") if (@vid == 0)

		pid = @req['pid']
		raise ErrorMsg.new("不正なキャラクターです") if (!pid)
		pid = pid.to_i

		msg = trunc(@req['message'])
		type = @req['mtype']

		return if (!msg || msg == '')

		msg = CGI.escapeHTML(msg).rstrip
		msg.gsub!(/\r\n/, '<br>')
		msg.gsub!(/[\r\n]/, '<br>')
		msg.gsub!(/\n/, '<br>')
		msg.gsub!(/[\n]/, '<br>')

		@vildb.transaction do
			vil = get_vil(@vid)

			raise ErrorMsg.new('終了しています') if (vil.state == 4)

			player = vil.players.player(@login)
			raise ErrorMsg.new("あなた(#{@login.userid})はこの村(#{vil.vid})に参加していません(#{@login.login.inspect})") if !player
			raise ErrorMsg.new("不正なキャラクターです") if (player.pid != pid)

			if (!player.can_whisper && type == 'whisper')
				raise ErrorMsg.new('あなたはささやけません')
			end
			if (vil.phase == Vil::Phase::Sun && type == 'night')
				raise ErrorMsg.new('既に夜が明けています')
			end

			$logger.debug('post by ' + @login.userid + "(#{pid})")
			vil.record(type, player, msg)
		end
	end

	def handle_entry
		raise ErrorMsg.new("不正な村IDです") if (@vid == 0)

		pid = @req['pid']
		raise ErrorMsg.new("不正なキャラクターです") if (!pid)
		pid = pid.to_i

		msg = trunc(@req['message'])
		raise ErrorMsg.new("発言が空です") if (!msg || msg == '')
		raise ErrorMsg.new("発言が長すぎます") if (msg.size > 400)

		@vildb.transaction {
			vil = get_vil(@vid)

			if vil.players.has_key?(@login.userid)
				raise ErrorMsg.new("エントリー済みです")
			elsif (vil.state != 0 && vil.state != 1)
				raise ErrorMsg.new('既に開始しています')
			elsif vil.players.max == vil.players.size
				raise ErrorMsg.new("定員に達しています")
			elsif vil.players.player(pid)
				raise ErrorMsg.new("既に使用されているキャラクターです")
			end

			@login.registaddress(@req)

			skill = -1
			player = Player.new(pid, @login.userid, skill)
			m = CGI::escapeHTML(msg).gsub(/\r\n/, '<br>').gsub(/[\r\n]/, '<br>')

			vil.add_player(player, m)
		}
	end

	def handle_exit
		raise ErrorMsg.new("不正な村IDです") if (@vid == 0)

		pid = @req['pid']
		raise ErrorMsg.new("不正なキャラクターです") if (!pid)
		pid = pid.to_i

		@vildb.transaction {
			vil = get_vil(@vid)
			if (!vil.players.key?(@login.userid))
				raise ErrorMsg.new("エントリーしていません")
			elsif (vil.date == 1)
				raise ErrorMsg.new("既に開始しています")
			end

			vil.delete_player(vil.players[@login.userid])
		}
	end

	def handle_update
		move = @vildb.transaction do
			vil = get_vil(@vid)
			vil.update()
			(vil.state == 4)
		end

		if (move)
			print "Status: 302 Moved Temporary\n"
			print "Location: log_#{@vid}_#{0}.html\n\n"
			exit(0)
		end
	end

	def handle_vote
		raise ErrorMsg.new('対象がセットされていません') if (!@req['pid'])
		@vildb.transaction {
			vil = get_vil(@vid)
			pl = vil.players.player(@login)
			if vil.voting.first() == pl
				if (vil.phase == Vil::Phase::Room && pl.yesterday_mate.index(@req['pid'].to_i))
					raise ErrorMsg.new('昨日同室した相手は指定できません')
				end
				pl.vote = @req['pid'].to_i
				target = vil.players.player(pl.vote)
				raise ErrorMsg.new('相手が既に死亡しています') if target.dead?
				$logger.debug(%Q(#{pl.name} % #{pl.vote}))
				vil.update()
			else
				raise ErrorMsg.new('あなたの順番ではありません')
			end
		}
	end

	def handle_prevote
		raise ErrorMsg.new('投票先がセットされていません') if (!@req['pid'])
		yesorno = @req['pid'] =='approve' ? true : false
		@vildb.transaction {
			vil = get_vil(@vid)
			pl = vil.players.player(@login)
			if vil.voting.first() == pl
				pl.prevote = yesorno
				vil.update()
			else
				raise ErrorMsg.new('あなたの順番ではありません')
			end
		}
	end

	def handle_skill
		target = (@req['pid'] != '') ? @req['pid'].to_i : nil

		@vildb.transaction {
			vil = get_vil(@vid)
			player = vil.players.player(@login)
			player.skill_set(vil, target)
		}
	end

	def handle_commit
		@vildb.transaction {
			vil = get_vil(@vid)
			player = vil.players.player(@login)
			if (vil.vtargets.index(player) && vil.voting.first == player)
				vil.update()
			end
		}
	end

	def handle_cmd
		cmd = @req['cmd']
		cmds = %w(make entry post update prevote vote skill exit commit)
		__send__('handle_' + cmd) if cmds.index(cmd)

		comet_cmds = %w(entry post update prevote vote skill exit commit)
		limitcheck_cmds = %w(post update exit commit)
		if comet_cmds.index(cmd)
			t = Time.now()
			limit = (limitcheck_cmds.index(cmd)) ? S[:processlimit] : false
			Duet::Server.dispatch(S[:ajaxdb_path] + ".#{@req['vid']}", limit)
			$logger.debug("total time(#{cmd}):" + (Time.now() - t).to_f.to_s)
		end
	end

	def handle_index
		changes = INFO.dup
		villages = DB::Villages.select {|v| v['state'] != 4 }
		active_villages = DB::Villages.select {|v| v['state'] != 4}
		if (S[:autobuildvillage] && active_villages.size < S[:autobuildlimit])
			build_village()
		end

		print Page::Index.new(@login.form, changes, villages).result()
	end

	def handle_mkvil
		print Page::MakeVillage.new(@login.form).result()
	end

	def handle_chars
		print Page::CharList.new(@login.form, NAMES.dup).result()
	end

	def handle_history
		print Page::History.new(@login.form, HISTORY.dup).result()
	end

	def handle_info
		print Page::Info.new(@login.form, INFO.dup).result()
	end

	def handle_reg
		print Page::Regulation.new(@login.form).result()
	end

	def handle_doc
		print Page::Document.new(@login.form).result()
	end

	def handle_log
		print Page::LogIndex.new(@login.form).result()
	end

	def handle_vid
		@vil = get_ronly_vil(@vid)

		if @vil.state == Vil::State::End
			# Vil::Sweeper.sweep(@vil)
			url = S[:log_dir] + @vil.vid.to_s + '/0.html'
			print '<html><head>'
			print %Q(<meta http-equiv="Refresh" content="0;URL=#{url}">)
			print '</head><body>'
			print %Q(Redirecting to <a href="#{url}">#{url}</a>)
			print '</body></html>'
			exit
		end

		if @vil.need_sync?
			@vildb.transaction {
				@vil = get_vil(@vid)
				@vil.sync() if @vil.need_sync?
			}
		end

		date = (@req.key?('date')) ? @req['date'].to_i : @vil.date

		@player = @vil.players.player(@login)
		if (@vil.state != Vil::State::End && @player && date == @vil.date)
		# OK I'm foolish, too long.
			if @req['cmd'] == 'sync'
				sleep(S[:syncsleeptime]) unless S[:highperformance]

				require 'json/lexer'

				head = "Content-Type: application/x-javascript; charset=utf-8\r\n"
				mid = @req['mid']
				actstate = @req['ast']
				livestate = @req['lst']
				page =  ActivePage::SyncDay.new(@vil, @player, mid, livestate)
				timeline = ''
				date_forward = false

				if page.modified?  # => not wait
					$logger.debug('page modified, not wait')
					if (page.nonmatch? || page.livestate_unmatch?)
						random_wait()
						date_forward = true
						mid = 0
					else
						sleep(S[:syncsleeptime]) unless S[:highperformance]
					end
					vil = get_ronly_vil(@vid)

					player = vil.players.player(@login)
					actbox = ActivePage::ActionBalloon.new(@login.form(vil.vid), player, vil)
					page =  ActivePage::SyncDay.new(vil, player, mid, livestate)
					if page.need_actbox_resync? && (actbox.result?(actstate) || date_forward)
						act = actbox.sync_result()
					else
						act = ''
					end
					timeline = ActivePage::TimeLine.new(@vil).result() if date_forward

					page_res = page.result()
					size = page.discussions.size
					order = ActivePage::Order.new(vil).sync_result()
					whis = ActivePage::SkillWhisper.new(vil, player).sync_result()

					print head + "\r\n" + \
						[actbox.state, act, page_res, size, order, page.bgimage, timeline, whis].to_json

				else  # => wait

					dbpath = S[:ajaxdb_path] + ".#{@vil.vid}"
					server = Duet::Server.new(@login.userid, @req, dbpath)
					wait_time = @vil.update_time - Time.now()
					if wait_time > S[:reconnect_sec]
						wait_time = S[:reconnect_sec]
					elsif wait_time < 0
						wait_time = 2 
					end
					server.wait(wait_time + 1)  # +1 is helper too wide band-width

					if server.wakeup_bysignal
						t = Time.now
						# village resync.
						vil = get_ronly_vil(@vid)
						player = vil.players.player(@login)
						page =  ActivePage::SyncDay.new(vil, player, mid, livestate)

						if (player && page.modified?)
							# undefined player when use opera && wakeup by handle_exit

							if (page.nonmatch? || page.livestate_unmatch?)
								random_wait()
								date_forward = true
								mid = 0
								page =  ActivePage::SyncDay.new(vil, player, mid, livestate)
							end

							actbox = ActivePage::ActionBalloon.new(@login.form(vil.vid), player, vil)
							if page.need_actbox_resync? && \
								(actbox.result?(actstate) || @player.dead != player.dead || date_forward)

								act = actbox.sync_result()
							else
								act = ''
							end
							timeline = ActivePage::TimeLine.new(@vil).result() if date_forward

							page_res = page.result()
							size = page.discussions.size
							order = ActivePage::Order.new(vil).sync_result()
							whis = ActivePage::SkillWhisper.new(vil, player).sync_result()

							print head + "\r\n" + \
								[actbox.state, act, page_res, size, order, page.bgimage, timeline, whis].to_json
							$logger.debug('total time(wakeup by signal):' + (Time.now - t).to_f.to_s)
						else
							print page.not_modified()
						end
					else
						print page.not_modified()
					end
				end

				exit
			else
				print ActivePage::VilHeader.new(@vil).result()
				print ActivePage::ActionBalloon.new(@login.form(@vil.vid), @player, @vil).result()
				print ActivePage::Order.new(@vil).result()
				print ActivePage::SkillWhisper.new(@vil, @player).result()
				print ActivePage::Day.new(@vil, @player).result()
			end
		elsif (@vil.state == Vil::State::End && @req['cmd'] && @req['cmd'] == 'sync')
			require 'json/lexer'

			head = "Content-Type: application/x-javascript; charset=utf-8\r\n"
			random_wait()
			print head + "\r\n" + \
				['', '', '', 'reload', '', '', ''].to_json
		else
			print Page::Day.new(@login.form(@vil.vid), @vil, date, @player).result()

			if (@vil.date == date && @vil.state != Vil::State::End)
				print Page::Order.new(@login, @vil).result()
			end
			print %Q(</div>\n)

			if (@login.login && @vil.state == Vil::State::Welcome && date == @vil.date)
				print Page::ActionBalloon.new(@player, @login, @vil).result()
			elsif date + 1 == @vil.date
				print "<a href=\"?vid=#{@vid}\">次の日へ</a>\n"
			elsif date != @vil.date
				print "<a href=\"?vid=#{@vid};date=#{date+1}\">次の日へ</a>\n"
			end

			print FOOT + "</div></body></html>"
		end
	end

	def run
		if File.exist?('db/.dontdelete')
			_run()
		else
			Dir.mkdir('db') unless File.exist?('db')
			Dir.mkdir('db/vil') unless File.exist?('db/vil')
			
			db = PStore.new('db/vil.db')
			db.transaction {
			  db['root'] = Array.new
			  db['recent_vid'] = 0
			}
			
			File.open('db/.dontdelete', 'w') {|fh| fh.write '' }

			redirect()
			exit
		end
	end

	def _run
		begin
			@login = Login.new(@req)
			@head += "Set-Cookie: #{@login.cookie}\r\n" if @login.cookie

			if (!@login.cookie && ENV['REQUEST_METHOD'] == 'POST')
				handle_cmd()
				
				if %w(skill post vote prevote).index(@req['cmd'])
					print "Status: 200 OK\n\n"
				else
					redirect()
				end

				return
			end

			if @req['cmd'] != 'sync'
				print @head + "\r\n"
				@headered = true
			end

			cmd = @req['cmd']
			if %w(mkvil log doc history info chars reg).index(cmd)
				__send__('handle_' + cmd)
			elsif (@vid != 0)
				handle_vid()
			else
				handle_index()
			end
		rescue
			unless @headered
				print "Status: 500 Internal Server Error\n"
				print @head + "\r\n"
			end
			handle_error($!)
		end
	end

	def random_wait
		sec = rand(3) + rand()
		$logger.debug([@login.userid, sec])
		sleep(sec)
	end

	def redirect
		location = (@vid && @vid != 0) ? "?vid=#{@vid}\n\n" : ".\n\n"

		print "Status: 302 Moved Temporary\n"
		print "Location: #{location}"
	end

	def handle_error(error)
		if error.class == ErrorMsg
			print error
			File.open(S[:fatallog_path], 'a') {|fh| fh.write "\n#{Time.now.to_s}\n#{error}\n" }
		else
			er  = CGI.escapeHTML("#{error.to_s}\n")
			er << CGI.escapeHTML("#{error.backtrace.join("\n")}\n")
			print "<pre>\n#{er}</pre>\n"
			File.open(S[:fatallog_path], 'a') {|fh| fh.write "\n#{Time.now.to_s}\n#{er}\n" }
		end
	end
end
