class Skill
	
	Skills = [\
		{'id' => :Random, 'name' => 'おまかせ', 'position' => '村人', 'sname' => '任', 'action' => false },
		{'id' => :Folk, 'name' => '村人', 'position' => '村人', 'sname' => '村', 'action' => false },
		{'id' => :Wolf, 'name' => '人狼', 'position' => '人狼', 'sname' => '狼', 'action' => true },
		{'id' => :Pastor, 'name' => '牧師', 'position' => '村人', 'sname' => '牧', 'action' => false },
		{'id' => :Exorcist, 'name' => '祈祷師', 'position' => '村人', 'sname' => '祈', 'action' => false },
		{'id' => :Mad, 'name' => '狂人', 'position' => '人狼', 'sname' => '狂', 'action' => true },
		{'id' => :Fox, 'name' => '妖狐', 'position' => '妖魔', 'sname' => '狐', 'action' => false },
	]

	def self.find(skill_str)
		s = Skills.find {|s| s['id'] == skill_str.intern }
		eval(skill_str) if s
	end

	class BaseSkill
		def self.name
			klass = self.to_s.gsub(/.*::/, '').intern
			Skills.find {|x| x['id'] == klass }['name']
		end

		attr_reader :sid, :name, :position, :sname, :has_action
		
		def initialize
			klass = self.class.to_s.gsub(/.*::/, '').intern
			skill = Skills.find {|s| s['id'] == klass }
			@sid = skill['id'].id2name.downcase
			@name = skill['name']
			@position = skill['position']
			@sname = skill['sname']
			@has_action = skill['action']
		end

		def init(players)
			''
		end

		def action(village, player, target)
		end
	end


	class Random < BaseSkill; end
	class Folk < BaseSkill; end
	class Fox < BaseSkill; end

	class SpecialSkill < BaseSkill
		attr_reader :pass

		def initialize
			super
			@pass = true
		end

		def passed
			@pass = false
		end

		def pass_s
			if @pass
				'後1回能力が使えます。'
			else
				'能力を使い果たしました。'
			end
		end
	end

	class Pastor < SpecialSkill; end
	class Exorcist < SpecialSkill; end

	class Wolf < SpecialSkill
		attr_reader :do_action

		def initialize
			super
			@do_action = false
		end

		def action(village, player, target)
			room_number = village.rooms.number(village.date, player.pid)

			if target
				t = village.players.player(target)
				if t.live?
					_room_number = village.rooms.number(village.date, t.pid)

					return nil if (@do_action || room_number != _room_number)
					_action(village, player, t, room_number)
				end
			else
				_pass_action(village, player)
			end
		end

		def _action(vil, pl, tr, number)
			@do_action = true
			vil.record('whisper', pl, c(ATTACKING, tr.name))

			if (tr.skill.sid == 'pastor' && tr.skill.pass)  # 牧
				tr.skill.passed
				vil.record('god', tr, c(BLOCKING, pl.name))
			elsif (tr.skill.sid == 'exorcist' && tr.skill.pass) \
				&& (vil.rule != Vil::Rule::Advance || vil.date != 1) # 祈

				tr.skill.passed
				vil.record('god', tr, c(COUNTERING, pl.name))
				pl.kill(vil.date)
				vil.addlog(nextra(number, c(DIE, pl.name)))
			elsif tr.skill.sid == 'wolf'  # 狼
				false
			else
				tr.kill(vil.date)
				vil.addlog(nextra(number, c(DIE, tr.name)))
			end
		end

		def _pass_action(vil, player)
			if @pass
				@do_action = 'passed'
			else
				end_action(vil, player)
				@do_action = true
			end
		end

		def end_action(vil, player)
			if (!@do_action || @do_action == 'passed')
				mates = vil.rooms.room(vil.date, player).collect {|pid|
					vil.players.player(pid)
				}
				mates.delete(player)
				mates.each {|pl|
					unless (pl.skill.sid == 'wolf' || pl.dead?)
						if @pass
							passed()
						else
							player.cide(vil.date)
							number = vil.rooms.number(vil.date, player.pid)
							vil.addlog(nextra(number, c(DIE, player.name)))
						end

						break
					end
				}
			end

			@do_action = false
		end

		def pass_s
			if @pass
				'後1回襲撃をパスできます。'
			else
				'襲撃をパスできません。'
			end
		end
	end

	class Mad < BaseSkill
		def action(village, player, target)
			if player.live?
				player.cide(village.date)
				room_number = village.rooms.number(village.date, player.pid)
				village.addlog(nextra(room_number, c(DIE, player.name)))
			end
		end
	end


	Mapper = {}
	Skills.each_with_index {|h, i| Mapper[i] = eval(h['id'].id2name) }
	DeMapper = Mapper.invert

end
