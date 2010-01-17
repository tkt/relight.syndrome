class Player

	Live = 0
	Dead = 1

	attr_reader :pid, :userid, :cause
	attr_accessor :skill, :prevote, :vote, :target, :msg, :dead
	attr_accessor :survive, :death, :cnt, :yesterday_mate, :lastmsg_time

	def initialize(pid, userid, skill)
		@pid = pid
		@userid = userid
		@sid = skill
		@dead = 0
		@commit = false
		@cnt = [1]
		@yesterday_mate = []
	end

	def self.name(pid)
		NAMES[pid]
	end

	def name
		NAMES[@pid]
	end

	def sname
		name().sub(/^[^ ]+ /, '')
	end

	#def skill
	#	(@sid == -1) ? 'おまかせ' : Skill.skills[@sid]
	#end
	
	def skill_set(vil, target = nil)
		if @skill.has_action
			@skill.action(vil, self, target)
		else
			nil
		end
	end

	def color
		(dead == 0) ? two(@pid) : two(@pid) + 'rip'
	end

	def can_whisper
		(@skill.class == Skill::Wolf && live?)
	end

	def live?
		@dead == 0
	end

	def dead?
		@dead == 1
	end

	def killed?
		(@dead == 1 && %w(k c).index(@cause))
	end

	def kill(date)
		_death(date)
		@cause = 'k'
	end

	def cide(date)
		_death(date)
		@cause = 'c'
	end

	def execute(date)
		_death(date)
		@cause = 'e'
	end

	def sudden_death(date)
		_death(date)
		@cause = 's'
	end

	def _death(date)
		@dead = 1
		@death = date
	end

	def admin?
		ADMINS.index(@userid)
	end

	def reset_count(date)
		for i in @cnt.size..date
			@cnt.push(0)
		end
	end

	def vote_suffle(targets)
		@vote = targets[rand(targets.size)].pid
	end
end
