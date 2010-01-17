require 'pp'
$LOAD_PATH.unshift('./lib')
require 'ms/util'

def wary_gen(num, ary)
	ret = []
	w = 1
	while w <= num
		ret << {'w' => w, 'm' => num - w}
		w += 1
	end

	return ret
end

def fary_gen(num, ary)
	ret = []
	0.step(num) {|i|
		num_minus_e = num - i

		0.step(num_minus_e) {|j|
			num_minus_p = num_minus_e - j

			0.step(num_minus_p) {|k|
				if (
					(i + j + k == num) && \
					(k > 2)
					)

					ret << {'e' => i, 'p' => j, 'f' => k}
				end
			}
		}
	}
	ret
end

def combine(wary, fary)
	ret = []
	wary.each {|wreg|
		w = wreg.dup
		fary.each {|freg|
			ret << w.merge(freg)
		}
	}
	ret
end

def get_regulation(players_num)
	ret = []
	base = players_num / 2
	odd = players_num % 2

	if (odd == 0 || players_num == 11 || players_num == 13)
		wary = wary_gen(base - 2, %w(w m))
		fary = fary_gen(base + 2 + odd, %w(e p f))
		ret.concat(combine(wary, fary))
	end

	# folkstage
	wary = wary_gen(base - 1, %w(w m))
	fary = fary_gen(base + 1 + odd, %w(e p f))
	ret.concat(combine(wary, fary))

	# all
	wary = wary_gen(base, %w(w m))
	fary = fary_gen(base + odd, %w(e p f))
	ret.concat(combine(wary, fary))

	ret.reject! {|reg| reg['w'] < reg['e'] }

	return ret
end

def reg_info(r)
	pls = r['e'] + r['p'] + r['f']
	frs = r['e'] + r['p']
	wvs = r['w'] + r['m']
	all = pls + wvs

	[pls, frs, wvs, all]
end 

def reject_percentage8(reg)
	pls, frs, wvs, all = reg_info(reg)
	(
		reg['m'] == 0 ||\
		reg['m'] > 2 ||\
		reg['m'] == reg['w'] ||\
		frs > reg['w'] ||\
		(reg['w'] != 1 && frs < reg['w'] && reg['e'] == 0)
	)
end

def reject_percentage9(reg)
	pls, frs, wvs, all = reg_info(reg)
	(
		reg['w'] > 2 ||\
		reg['e'] > 1 ||\
		reg['p'] > 2 ||\
		reg['m'] > 3 ||\
		(reg['f'] > 5 && reg['w'] != 1) ||\
		(reg['m'] == 3 && reg['w'] != 1) ||\
		frs == 0 && reg['w'] == 2
	)
end

def reject_percentage11(reg)
	pls, frs, wvs, all = reg_info(reg)
	(
		reg['w'] > 3 ||\
		reg['e'] > 2 ||\
		reg['p'] > 3 ||\
		reg['m'] > 4 ||\
		(reg['m'] == 1 && reg['w'] != 3) ||\
		(reg['m'] == 2 && reg['w'] == 3) ||\
		(reg['m'] == 2 && reg['w'] == 1) ||\
		frs == 5 ||\
		frs == 0 ||\
		frs == 1 && reg['w'] > 2 ||\
		frs == 4 && reg['w'] > 2
	)
end

def reject_percentage12(reg)
	pls, frs, wvs, all = reg_info(reg)
	(
		reg['w'] == 1 ||\
		reg['w'] > 3 ||\
		reg['p'] > 4 ||\
		(reg['m'] > 3 && reg['w'] == 2) ||\
		(reg['p'] > 3 && reg['w'] == 2) ||\
		(reg['e'] > 2 && reg['w'] == 2) ||\
		(reg['m'] > 2 && reg['w'] == 3) ||\
		frs > 4
	)
end

def reject_percentage13(reg)
	pls, frs, wvs, all = reg_info(reg)
	(
		reg['w'] == 1 ||\
		reg['w'] > 3 ||\
		reg['p'] > 4 ||\
		(reg['p'] > 3 && reg['w'] == 2) ||\
		(reg['e'] > 2 && reg['w'] == 2) ||\
		(reg['m'] < 3 && reg['w'] == 2) ||\
		(reg['m'] > 2 && reg['w'] == 3) ||\
		frs > 5
	)
end

def get_percentage8(reg)
	per = 10
	pls, frs, wvs, all = reg_info(reg)

	per -= 7 if frs == 0
	per -= 5 if reg['e'] == 1 && reg['p'] == 1
	per -= 7 if reg['w'] == reg['e']

	per
end

def get_percentage9(reg)
	per = 100
	pls, frs, wvs, all = reg_info(reg)

	# base
	per -= 20 if reg['w'] == 2
	per -= 80 if reg['w'] == 1

	# case
	case reg['w']
	when 1
		case reg['m']
		when 2
			per += 10
			per -= 5 if reg['e'] == 1
			per += 5 if frs == 0
			per += 3 if frs == 1
			per -= 30 if frs > 1
		when 3
			per -= 10
			per -= 5 if frs == 0
			per += 5 if (reg['e'] == 1 && reg['p'] == 1)
		end
	when 2
		per += 30 if (reg['e'] == 1 && reg['p'] == 1)
		per -= 7 if !(reg['e'] == 1 && reg['p'] == 1)

		case reg['m']
		when 1
			per -= 20
			per -= 30 if frs > reg['w']
			per += 6 if frs <= reg['w']
		when 2
			per += 20
			per += 10 if (reg['e'] == 1 && reg['p'] == 1)
			per -= 3 if !(reg['e'] == 1 && reg['p'] == 1)
			per -= 30 if reg['p'] == 1
			per += 7 if reg['p'] != 1
		end
	end

	per
end

def get_percentage11(reg)
	per = 100
	pls, frs, wvs, all = reg_info(reg)

	# base
	per -= 80 if reg['w'] == 1
	per -= 10 if reg['w'] == 2
	per -= 70 if reg['w'] == 3

	per -= 30 if frs > 3

	# case
	case reg['w']
	when 1
		per -= 10 if frs == 0
		per -= 10 if frs > 1
		case reg['m']
		when 3
			per -= 10 if reg['e'] == 1
			per += 5 if frs == 0
			per += 3 if frs == 1
			per -= 10 if frs > 1
			per -= 100 if frs > 2
		when 4
			per -= 5 if frs == 0
			per += 5 if (reg['e'] == 1 && reg['p'] == 1)
			per -= 10 if frs > 1
			per -= 100 if frs > 2
		end
	when 2
		per -= 70 if reg['w'] == reg['e']

		per += 30 if (reg['e'] == 1 && reg['p'] == 2)
		per -= 7 if !(reg['e'] == 1 && reg['p'] == 2)
		per -= 30 if reg['p'] == 3
		per += 7 if reg['p'] != 3
		per -= 10 if reg['e'] == 0
		per += 2 if reg['e'] != 0
		per -= 10 if reg['p'] == 0
		per += 2 if reg['p'] != 0
		per -= 10 if frs == 1
		per += 2 if frs > 1

		case reg['m']
		when 2
			per += 20
			per -= 30 if frs > reg['w']
			per += 6 if frs <= reg['w']
		when 3
			per -= 20
			per += 10 if (reg['e'] == 1 && reg['p'] == 1)
			per -= 3 if !(reg['e'] == 1 && reg['p'] == 1)
			per -= 20 if frs < 3
			per -= 30 if frs < 2
		end
	when 3
		per += 30 if (reg['e'] == 1 && reg['p'] == 2)
		per -= 10 if !(reg['e'] == 1 && reg['p'] == 2)

		case reg['m']
		when 0
			per += 2 if reg['e'] != 0
			per -= 3 if reg['e'] == 0
		when 1
			per += 2 if reg['e'] != 0
			per -= 3 if reg['e'] == 0
		end
	end

	per
end

def get_percentage12(reg)
	per = 50
	pls, frs, wvs, all = reg_info(reg)

	# base
	per -= 50 if reg['w'] == reg['e']
	per -= 50 if (reg['w'] == reg['e']) && reg['p'] != 0

	per -= 100 if frs == 0
	per -= 60 if frs == 1
	per -= 20 if frs == 2
	per -= 5 if frs > 4

	per += 30 if (reg['e'] > 0 && reg['p'] > 0)
	per -= 10 if (reg['e'] == 0 || reg['p'] == 0)

	# case
	case reg['w']
	when 2
		per += 20 if (reg['e'] == 1 && reg['p'] == 2)
		per -= 5 if !(reg['e'] == 1 && reg['p'] == 2)
		case reg['m']
		when 2
			per -= 20
			per -= 20 if frs > 3
		when 3
			per += 20
			per -= 20 if frs < 4
		end
	when 3
		per += 20 if (reg['e'] == 1 && reg['p'] == 2)
		per -= 5 if !(reg['e'] == 1 && reg['p'] == 2)
		case reg['m']
		when 1
			per += 20
			per -= 50 if reg['p'] == 4
			per -= 10 if (reg['e'] == 2 || reg['p'] == 2)
			per -= 20 if frs > 3
		when 2
			per -= 20
			per -= 20 if frs < 4
		end
	end

	per
end

def add_percentage(reg)
	ret, fret = [], []
	reg.each {|r|
		all = r['e'] + r['p'] + r['f'] + r['w'] + r['m']
		case all
		when 8
			next if reject_percentage8(r)
			next if reject_percentage9(r)
			per = get_percentage8(r)
		when 9
			next if reject_percentage9(r)
			per = get_percentage9(r)
		when 10
			next if reject_percentage9(r)
			per = get_percentage9(r)
		when 11
			next if reject_percentage11(r)
			per = get_percentage11(r)
		when 12
			next if reject_percentage12(r)
			per = get_percentage12(r)
		when 13
			next if reject_percentage13(r)
			per = get_percentage12(r)
			# per = 100
		else
			per = 100
		end
		next r if per <= 0

		ret << per
		ret << r
	}
	total, t, pers = 0, 0, []
	ret.every {|per, reg| total += per}
	ret.every {|per, reg|
		pe = (per.to_f / total.to_f * 1000).to_i
		fret << pe
		t += pe
		pers << pe
		fret << reg
	}

	ffret = []
	pers.uniq.sort.reverse_each {|pe|
		fret.every {|per, reg|
			if pe == per
				ffret << per
				ffret << reg
			end
		}
	}
	ffret
end

def programize(reg, num)
	r = reg.inspect
	r.gsub!(/, (\d+)/) { ",\n#{$1}" }
	r.gsub!(/\[/, "[\\\n")
	r.gsub!(/\]/, ",\n],\n")
	r.gsub!(/^(\d)/, '	\1')
	r = [num.to_s, ' => ', r].join.gsub(/^/, "\t")

	total, cnt = 0, 0
	r.gsub!(/\t(\d+), (.*)/) {
		cnt += 1
		total += $1.to_i
		"\t#{$1}, #{$2} ##{total} ##{cnt}"
	}
	r
end

ret = ''

=begin
nums = [11]
nums.each {|num|
	reg = get_regulation(num)
	re =  add_percentage(reg)
	ret << programize(re, num)
}
=end

8.step(13) {|num|
	reg = get_regulation(num)
	re =  add_percentage(reg)
	ret << programize(re, num)
}

print "class Vil; class Regulation\n"
print "\tTable = {\\\n" + ret + "}\n"
print "end; end\n\n"
