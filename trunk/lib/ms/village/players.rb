class Vil

	class Players < Hash
		attr_reader :mates, :votes

		def initialize
			super()
			@mates = []
			@votes = []
		end
	
		def add(pl)
			self[pl.userid] = pl
		end

		def exit(pl)
			self.delete(pl.userid)
		end
	
		def player(pl)  #(<= player & player_p)
			if !pl
				nil
			elsif pl.class == Fixnum  # pid
				ary = self.find {|k, p| p.pid == pl }

				return nil if ary == nil

				ary[1]
			else  # login
				return nil unless pl.login
	
				self[pl.userid]
			end
		end
	
		def lives  #(<= pids)
			all().select {|v| v.dead == 0 }
		end

		def deads
			all().select {|v| v.dead == 1 }
		end

		def killed(date)
			all().select {|v| (v.killed? && v.death == date) }
		end

		def notentries  #(<= left_pids)
			a = []
			NAMES.each_with_index {|name, i| a. << i }
			a.shift
			entries = all().collect {|x| x.pid }

			a - entries
		end
	
		def all  #(<= all_pids)
			self.values.sort {|x, y| x.pid <=> y.pid }
		end
	
		def select_skill(klass)  #(<= pids_s)
			lives().select {|p| p.skill.class == klass }
		end
	
		def wolves
			select_skill(Skill::Wolf)
		end

		def villagers
			ary = select_skill(Skill::Folk)
			ary.concat(select_skill(Skill::Pastor))
			ary.concat(select_skill(Skill::Exorcist))
			ary
		end
	
		def silents  #(<= say0s)
			lives().select {|p| (p.pid != 1 && p.cnt.last == 0) }
		end

		def max
			S[:max_entries]
		end

		def size
			keys.size
		end

		def ready?
			#2009/01/25 mod tkt for min_entries by coretime|| size() >= S[:min_entries]
			size() >= min_entries_ready(true)
		end

		def adv_ready?
			size() >= S[:apply_advance_num]
		end

		def open_party
			all().each {|p| p.dead = 0 }
		end

		def reset_count(date)
			all().each {|p| p.reset_count(date) }
		end

		def reset_cmd
			lives().each {|p|
				p.target = nil
				p.vote = nil
			}
			@votes = []
			@mates = []
		end

		def end_action(village)
			wolves().each {|w|
				w.skill.end_action(village, w)
			}
		end

		def collect_prevote
			vote = {'result' => false, 'approve' => 0, 'object' => 0 }
			ary = lives().sort {|a, b| a.pid <=> b.pid }
			ary.each {|pl| (pl.prevote) ? vote['approve'] += 1 : vote['object'] += 1 }
			vote['result'] = true if vote['approve'] > vote['object']

			[ary, vote]
		end

		def vote_suffle(targets)
			lives().each {|p| p.vote_suffle(targets) }
		end

		def vote_map(votes)
			@votes << votes
		end

		def room_map(mates)
			@mates << mates
		end

		def room_remap(mates)
			@mates.pop
			@mates << mates
		end

		def room_mapping
			_save_room_mates(@mates)
			@mates
		end

		def _save_room_mates(room_map)
			room_map.each {|room|
				room.each {|pl|
					mate = room.collect {|p| p.pid }
					mate.delete(pl.pid)
					pl.yesterday_mate = mate
				}
			}
		end
		private :_save_room_mates

		def skill_mapping
			skills = Regulation.get(self.keys.size)
			skills[Skill::Folk] -= 1
			player(1).skill = Skill::Folk.new

			pls = self.keys.shuffle
			pls.delete('master')

			skills.each {|sklass, num|
				num.times {|i|
					pl = pls.shift
					self[pl].skill = sklass.new()
				}
			}
		end

	end

end
