#2010/01/15:add module:tkt for out entries data
#2011/02/12:mod module:tkt for mod to entries data get
#2011/02/19:mod module:tkt for add to entry tweet mode
#2015/09/09:mod module:tkt for dispatch 5th twitter api
$LOAD_PATH.unshift('./lib')
require 'logger'
require 'rubygems'
#require 'rubytter'
#require 'oauth'
require "twitter"
require 'config'
require 'twit_config'
require 'cache'
require 'ms/xml'
require 'ms/village/const'
require 'ms/feed'
require 'time'

class Twit
	
	def initialize()
		@logger = Logger.new(T_S[:log])
		if T_S[:debug] == false
			@logger.level = Logger::INFO
		end
		
		#make OAuth
		#consumer = OAuth::Consumer.new(
		#	T_S[:custmer_key],
		#	T_S[:custmer_secret_key],
		#	:site => T_S[:twitter_site]
		#)
		#token = OAuth::AccessToken.new(
		#	consumer,
		#	T_S[:oa_access_token],
		#	T_S[:oa_access_token_secret]
		#)
		
		# make twitter client
		#@client = OAuthRubytter.new(token)
		@client = Twitter::REST::Client.new do |config|
		  config.consumer_key        = T_S[:custmer_key]
		  config.consumer_secret     = T_S[:custmer_secret_key]
		  config.access_token        = T_S[:oa_access_token]
		  config.access_token_secret = T_S[:oa_access_token_secret]
		end
		
		#@client.update("It is fine today. It is fine today.")
		
		@timelines = []
		
		#cache data
		@cache_key = 'cache_vids'
		@cache = Cache::FileCache.new(:root_dir => T_S[:cache_dir] + 'feed/twit')
		@vids = get_vids()
		@active_villages = nil
	end
	
	def put()
		vil_info = get_xml()
		get_timelines()

		# update for vils data
		vil_info[:vils].each() { |vil|
			check_vil_state(vil, vil_info[:min_entries].to_i)
			put_data = status(vil, vil_info[:max_entries], vil_info[:link])
			
			tweet(vil, put_data)
		}
		
		finalize()
	end
	
	#tkt@add:2011/02/19 start
	def put_entry(vil)
		get_timelines()
		server = 'http://' + SET_SERV + SET_PATH
		
		vil_put = {\
			:vid => vil.vid,
			:vname => vil.name,
			:link => "?vid=#{vil.vid}",
			:entries => vil.players.size.to_i,
			:update_time => vil.update_time,
			:state => TwitVil::State::Entry,
			:status => '',
		}

		# update for vils data
		tweet(vil_put, status(vil_put, vil.players.max, server))
		
		finalize()
	end
	
	def tweet(vil, put_data)
		if vil[:state].to_i > -1 && update?(put_data)

			if T_S[:simulator_mode]
				@logger.info put_data
			else
				@client.update(put_data)
			end
			if @vids.index(vil[:vid]) == nil
				@vids.push(vil[:vid])
			end
			debug("put #{put_data}")
			
		else
			debug("dont put by duplicative")
		end
	end
	#tkt@add:2011/02/19 end
	
	def get_xml()
		debug("get_xml")
		vils = Feed::VilsInfo.new()
		debug("get vils xml")
		xml = vils.get_xml()
		debug("write feed")
		Feed::RSS20.new('', vils.active_villages).write()
		
		debug("read xml")
		XML::Vil.new('').read(xml)
	end
	
	def get_vids()
		begin
			@vids = @cache.get_object(@cache_key)
		rescue Cache::CacheMiss
			@cache.clear()
			@vids = []
		end
	end
	
	def get_timelines()
		#get timeline
		if T_S[:check_duplicate]
			timelines = @client.user_timeline(T_S[:id])
			timelines.each { |status|
				#puts status.text todo
				#puts status.created_at
				if((Time.now - createTime(status.created_at)) <= T_S[:duplicate_time].to_i)
					@timelines.push(status.text)
				end
			}
		end
		
		data = @timelines
		data
	end
	
	#20件以内に存在したらアップデートしない
	def update?(status)
		is_update = true
		if T_S[:check_duplicate] 
			is_update = @timelines.index(status) == nil
		end
		
		is_update
	end

	def check_vil_state(vil, min)
		if @vids.index(vil[:vid])
			if vil[:state].to_i == Vil::State::Welcome
				if vil[:entries].to_i >= min
					vil[:state] = TwitVil::State::Ready
				elsif vil[:entries].to_i == 1
					vil[:state] = -1
				else
					vil[:state] = TwitVil::State::Welcome
				end
			else
				vil[:state]	= vil[:state].to_i + 1
			end
		else
			vil[:state] = TwitVil::State::Create
		end
	end

	def status(vil, max, url)
		#"#{text(element, 'title')} #{text(element, 'link')}"
		update_time = vil[:update_time].strftime('%Y/%m/%d %H時%M分')
		vil_url = "#{url}#{vil[:link]}"
		sprintf(VIL_STATUS[vil[:state].to_i], vil[:vid], vil[:vname], vil[:entries], max, update_time, vil_url)
	end
	
	def finalize()
		@cache.set_object(@cache_key, @vids)
	end
	
	#create time object by yyyy/mm/dd hh:mm:ss
	def createTime(data)
		#dates = ParseDate.parsedate(data)
		#Time.gm(dates[0], dates[1], dates[2], dates[3], dates[4], dates[5], dates[6])
		data
	end
	
	def debug(log)
		if @logger.debug?
			@logger.debug(log)
		end
	end
end

#Twit.new().put()


