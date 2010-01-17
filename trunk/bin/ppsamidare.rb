$LOAD_PATH.unshift('./lib')
require 'ms'
$DEBUG = false

def usage
	puts 'usage'
end

vid = ARGV.shift

unless (vid)
	usage()
	exit
end
require 'uri'
require 'net/http'
Net::HTTP.version_1_2

vildb = Store.new("db/vil/#{vid}.db")
fn = Dir.glob(S[:vildb_path] + vid + '_*.html').sort.last
before = IO.readlines(fn).size
before_time = Time.now

sec = 2
now = Time.now()
stime = Time.mktime(now.year, now.month, now.day, now.hour, now.min, now.sec + 3)

players = vildb.transaction { vildb['root'].players.all() }
players.each {|player|
	query = {'vid' => vid, 'cmd' => 'post', 'mtype' => 'say'}
	query['pid'] = player.pid

	userdb = Store.new('db/user.db')
	pass = userdb.transaction(true) {
		(userdb.root?(player.userid)) ? userdb[player.userid]['sig'] : '0'
	}

	login = "#{pass},#{player.userid}"
	header = {'Cookie' => 'login=' + CGI.escape(login)}

	Process.fork {
		query['message'] = player.userid
		query_string = query.collect {|key, value|
			"#{URI.encode(key)}=#{URI.encode(value.to_s)}"
		}.join("&")
		p [login].inspect 

		while Time.now > stime
			sleep(0.01)
		end
		Net::HTTP.start(SET_SERV) {|http|
			res = http.post(SET_PATH, query_string, header)
			if res.code == 200
				print '200 OK'
			else
				p [res.code, res.body, Process.pid]
			end
		}
	}
}

after_time = Time.now
sleep(5)
puts
after = IO.readlines(fn).size
puts "#{before} => #{after} (#{after - before}:#{players.size}), #{after_time - before_time}sec."
