LogFile = 'db/system.log'

class Array
	# from ref. manual
	def every(&block)
		arity = block.arity
		return self.each(&block) if arity <= 0

		i = 0
		while i < self.size
			yield(*self[i, arity])
			i += arity
		end
	self
	end
end

def File.lwrite(filepath, mode, stream)
	File.open(filepath, mode) {|fh|
		fh.flock(File::LOCK_EX)
		fh.print stream
	}
end

def c(msg, *a)
	msg = msg.clone
	for i in 1..9
		break if (!msg.gsub!(/%#{i}/, a[i-1].to_s.gsub(/%/, '!%!')))
	end
	msg.gsub!(/!%!/, '%')
	msg
end

def two(n)
	s = n.to_s
	if (s.size < 2)
		'0' + s
	else
		s
	end
end

def timestr(t = Time.now, j = false)
	if j
	"#{t.hour}時#{two(t.min)}分#{two(t.sec)}秒"
	else
	"#{t.hour}:#{two(t.min)}:#{two(t.sec)}"
	end
end

def message(str)
	"<div class=\"message\">#{str.chomp}</div>\n"
end

def _message(mtype, str)
	message("<div class=\"#{mtype}\">#{str.chomp}</div>")
end

def announce(str)
	message("<div class=\"announce\">#{str.chomp}</div>")
end

def nextra(number, str)
	message("<!--nextra#{number}--><div class=\"nextra\">#{str.chomp}</div>")
end

def announce(str) ; _message('announce', str) ; end
def wsystem(str)  ; _message('system', str)   ; end
def vote(str)     ; _message('vote', str)     ; end
def room(str)     ; _message('room', str)     ; end
def vote_res(str) ; _message('vote_res', str) ; end
def room_res(str) ; _message('room_res', str) ; end
def room_res2(str); _message('room_res2', str); end
def apology(str)  ; _message('apology', str)  ; end

def erbrun(file)
	Erubis::Eruby.load_file(file).run(binding)
	# ERB.new(File.open(file){|f| f.read}).run(binding)
end
def erbres(file, bind = nil)
	bind = binding unless bind
	Erubis::Eruby.load_file(file).result(bind)
	# ERB.new(File.open(file){|f| f.read}).result(bind)
end

def trunc(str)
	s = str.gsub(/\r\n/, "\n").rstrip
	s = $1 if s =~ /((.*?\n){5})/mu
	s = $1 if s =~ /(.{200})/mu
	s
end

def logize(str)
	s = str.dup
	s.gsub!(/href="([^#])/, 'href="' + S[:src_parent] + '\1')
	s.gsub!(/href="\."/, 'href="' + S[:log_parent] + '"')
	s.gsub!(/href="\.\/"/, 'href="' + S[:log_parent] + '"')
	s.gsub!(/src="/, "src=\"#{S[:src_parent]}")
	s
end

def wrap_message(pid, msg)
	message(%Q!<a name="none">#{NAMES[pid]}</a><table border=0 cellpadding=0 cellspacing=0 class="message_box"><tr><td width="40"><img src="#{S[:char_image_dir]}face#{two(pid)}.jpg"></td><td width="16"><img src="#{S[:image_dir]}say00.jpg"></td><td> <div class="mes_say_body0"> <div class="mes_say_body1">#{msg}</div> </div> </td></tr></table>!)
end

#2009/01/25 add tkt
#coretime:min_entries +1 -> else:min_entries.
def min_entries_num(up, check = false)
	(Time.coretimeThat?(up)) ? (S[:min_entries] + 1) : S[:min_entries]
end

def min_entries_ready(check = false)
	#min_entries_num(Time.now.to_f, check)
	(Time.coretime?) ? (S[:min_entries] + 1) : S[:min_entries]
end