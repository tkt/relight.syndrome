class Vil

	class Rooms < Array
		def in?(date, number, pid)
			self[date-1][number].index(pid)
		end

		def number(date, pid)
			number = nil
			self[date-1].each_with_index {|r, i| number = i if r.index(pid) }
			number
		end

		def members(date, number)
			self[date-1][number]
		end

		def room(date, player)
			self[date-1].find {|r| r.index(player.pid) }
		end
	end

	class Room < Array; end

end
