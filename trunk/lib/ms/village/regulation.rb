class Vil

	class Regulation
		require 'ms/village/sitereg.rb'

		def self.to_str(player_num)
			translator = {\
				'w' => '狼',
				'm' => '狂',
				'p' => '牧',
				'e' => '祈',
				'f' => '村',
				'x' => '狐',
			}

			t = Table[player_num]
			all = []
			t.every {|per, table|
				ary, ary2 = [], []
				%w(w m e p f).each {|roll|
					ary << translator[roll] * table[roll]
					ary2 << [translator[roll], table[roll]].join(':')
				}
				if per < 10
					per_s = '   ' + per.to_s
				elsif per < 100
					per_s = '  ' + per.to_s
				elsif per < 1000
					per_s = ' ' + per.to_s
				else
					per_s = per.to_s
				end
				all << [ary.join, ary2.join(' '), "(比重#{per_s})"].join(' ')
			}
			all.join("\n")
		end

		def self.get(player_num)
			translator = {\
				'w' => Skill::Wolf,
				'm' => Skill::Mad,
				'p' => Skill::Pastor,
				'e' => Skill::Exorcist,
				'f' => Skill::Folk,
				'x' => Skill::Fox,
			}

			h, total, reg = {}, 0, nil
			t = Table[player_num]
			t.every {|per, table| total += per }
			point = rand(total) + 1
			t.every {|per, table|
				point -= per
				$logger.debug([total, point, table])
				if point <= 0
					reg = table
					$logger.debug(reg)
					break
				end
			}
			reg.each {|k, v|
				h[translator[k]] = v
			}
			h
		end

		def self.guard(player_num, wolves_num)
			#((player_num - 2) / 2) + 2 + rand(2) mod 2008/11/07 tkt for guard fixed
			if player_num <= S[:guard_fixed_num]
				S[:guard_fixed_day]
			else
				#((player_num - 2) / 2) + 2 + rand(2)  mod 2008/11/08 tkt : for guard day change
				((player_num - wolves_num) / 2) + 2 + rand(2)
			end
		end

		def self.rule(player_num)
			(player_num < S[:apply_advance_num]) ? Rule::Standard : Rule::Advance
		end
	end

end
