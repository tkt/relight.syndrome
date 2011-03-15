#2010/01/15:add module:tkt for out entries data

$LOAD_PATH.unshift('./lib')
require 'ms/feed'

type = ARGV.shift
state = ARGV.shift

if type == 'rss2.0'
	Feed::RSS20.new(state).write()
else
	Feed::VilsInfo.new(state).write()
end