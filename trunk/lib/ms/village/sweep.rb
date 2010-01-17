class Vil

	class Sweeper
		def self.sweep(vil)
			new(vil).sweep
		end

		def initialize(vil)
			@vil = vil
			@dir = S[:log_dir] + @vil.vid.to_s + '/'
			Dir.mkdir(@dir) unless File.exist?(@dir)
		end

		def sweep
			(0..10).each {|date|
				fname = @dir + date.to_s + '.html'
				break unless File.exist?(S[:vildb_path] + "#{@vil.vid}_#{date}.html")

				File.open(fname, 'w') {|of|
					of.print erbres('skel/staticday.rhtml', binding)
				}

				# fp = S[:vildb_path] + "#{@vil.vid}_#{date}.html"
				# File.unlink(fp) if File.exists?(fp)
			}
		end
	end

end
