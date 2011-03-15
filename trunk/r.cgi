#!/usr/bin/ruby -Ku

$LOAD_PATH.unshift('./lib')

require 'ms/feed'

cgi = CGI.new()

type = cgi['xml']
state = cgi['state']

if type == 'rss2.0'
	Feed::RSS20.new(state).get()
else
	Feed::VilsInfo.new(state).get()
end
