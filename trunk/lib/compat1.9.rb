# if you use 1.9.x, it's built-in.
#
class Array
  def shuffle!
    size.downto(2) do |i|
      r = rand(i)
      self[i-1], self[r] = self[r], self[i-1]
    end
    self
  end

  def shuffle
    self.dup.shuffle!
  end
end

# It's not 1.9.x feature, but extention of std. classes
#
#2009/12/27 mod:tkt:coretime get from the configuration file
class Time
	def self.coretime?
		hour = Time.now.hour
		((S[:coretime_start] -1) < hour && hour < S[:coretime_end])
	end
	
	#2009/01/25 add tkt
	def self.coretimeThat?(time)
		hour = time.hour
		((S[:coretime_start] -1) < hour && hour < S[:coretime_end])
	end
	#2009/01/25 add tkt
end
