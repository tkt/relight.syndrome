$KCODE = 'u'
$LOAD_PATH.unshift('./lib')

require 'lib/ms'
require 'pp'

ps = Store.new(ARGV.shift)
ps.transaction(true) do
	pp ps.roots
	ps.roots.each {|key|
		pp ps[key]
	}
end
