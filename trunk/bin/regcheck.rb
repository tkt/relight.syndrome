$KCODE = 'u'
$LOAD_PATH.unshift('./lib')
require 'ms'

Vil::Regulation::Table.each {|num, ary|
	p num
	ary.every {|per, reg|
		total = 0
		reg.each {|k, v| total += v }
		state = (num == total) ? 'OK' : 'Unmatch'
		p [per, reg, num, total, state]
	}
}
