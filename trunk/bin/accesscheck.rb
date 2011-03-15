#add@tkt 2009/12/30 for access check
$LOAD_PATH.unshift('./lib')
require 'config'
require 'ms/access'

addr = ARGV.shift

check = Access::Check.new(addr)

accessdata = check.selectAll()

print "accessdata size:#{accessdata.size}\n"
print "result!\n"
print check.result()
print "\n"
