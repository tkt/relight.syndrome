$LOAD_PATH.unshift('./lib')
require 'ms'

def usage
	puts 'usage'
end

vid = ARGV.shift


now = Time.now
update_time = Time.mktime(00, 00, now.hour,
	now.day, now.month, now.year, nil, nil, nil, nil)
update_time += 1 * 60 * 60 if update_time < now
vilname = 'test village'

begin
	vldb = Store.new('db/vil.db')
	vid = vldb.transaction do
		vid = vldb['recent_vid'].to_i + 1
		vldb['recent_vid'] = vid

		vil = Hash.new
		vil['name'] = vilname
		vil['vid'] = vid
		vil['state'] = 0
		vil['start'] = update_time
		vldb['root'].push(vil)

		vid
	end

	vildb = Store.new("db/vil/#{vid}.db")
	vil = vildb.transaction {
		vil = Vil.new(vilname, vid, 'master', update_time)
		vildb['root'] = vil
		vil.start()
		vil
	}
end
