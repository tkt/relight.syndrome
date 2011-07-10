class Login
	attr_reader :userid, :passwd, :cookie, :login

	def set_cookie(cgi)
		if (!@userid)
			return
		end
		@cookie = CGI::Cookie.new({
			"name" => 'login', "value" => "#{@sig},#{@userid}"})
		@cookie.expires = Time.now + 60*60*24*30
		@cookie.path = SET_PATH
	end

	def master?
		login && userid == MASTER
	end

	def admin?
		login && ADMINS.index(userid)
	end

	def initialize(cgi)
		#2010/01/14:add:tkt for change proc of out log start
		@acclogger = Logger.new('db/accesslogin.log')
		#2010/01/14:add:tkt for change proc of out log end
		
		userdb = Store.new('db/user.db')

		cookie = cgi.cookies['login']
		@c = cookie

		if (cookie.size == 1)
			vals = cookie[0].split(/,/)
			@sig, @userid = vals[0], vals[1]

			#2011/07/10:mod:tkt rollback for speed upgrade start
			#2010/01/13:mod:tkt for speed upgrade start
			@login = userdb.transaction(true) {|db|
				db[@userid]['sig'] == @sig if db.root?(@userid)
			}
			#2010/01/13:mod:tkt for speed upgrade end
			#2011/07/10:mod:tkt rollback for speed upgrade end
		end

		cmd = cgi['cmd']
		if (cmd == 'logout')
			@acclogger.info("[ログイン] logout #{@userid} from #{cgi.remote_addr}")
			@login = false
			@sig, @userid = '', ''
			set_cookie(cgi)
		elsif (cmd == 'login')
			@userid = cgi['userid'].strip
			@sig = cgi['sig'].strip
			raise ErrorMsg.new('認識できないIDです') if @userid == ''
			raise ErrorMsg.new("IDが長すぎます [#{@userid}]") if @userid.size > 20
			#raise ErrorMsg.new('IDが長すぎます') if @userid.size > 20 mod 2009/01/13 tkt
			unless $DEBUG
				if (@sig == '' || @sig == 'LOCKED')
					#raise ErrorMsg.new('認識できないパスワードです') mod 2009/01/21 tkt
					#2010/01/13:del:tkt File.open('db/accesslogin.log', 'a') {|fh| fh.write "[#{Time.now.to_s}] 認識できないパスワードです #{@userid} from #{cgi.remote_addr}\n" }
					raise ErrorMsg.new("認識できないパスワードです [#{@userid}] to #{@sig}")
				end
			end
			userdb.transaction do
				if !userdb.root?(@userid)
					userdb[@userid] = Hash.new
					userdb[@userid]['sig'] = @sig
				end
				if userdb[@userid]['sig'] == @sig
					@login = true
					set_cookie(cgi)
					#2010/01/13:mod:tkt for logger
					@acclogger.info("[ログイン] login #{@userid} from #{cgi.remote_addr}")
				else
					#2010/01/13:mod:tkt for logger
					@acclogger.warn("[ログイン] 認証エラー #{@userid} to #{@sig} from #{cgi.remote_addr}")
					raise ErrorMsg.new("認証エラー [#{@userid}]")
					#raise ErrorMsg.new("認証エラー")  mod 2009/01/13 tkt
				end
			end
		end

		if (cmd == 'login' || cmd == 'logout')
			print "Status Code: 302 Moved Temporary\n"
			print "Set-Cookie: #{@cookie}\n"
			if cgi['vid'].to_i == 0
				print "Location: .\n\n"
			else
				print "Location: ?vid=#{cgi['vid']}\n\n"
			end
			exit(0)
		end
	end

	def registaddress(req)
		DB::Users.registaddress(userid, req.remote_addr)
	end

	def form(vid = 0)
		if login
%Q(<form action="./" method="get" class="login_form">
<input type="hidden" name="cmd" value="logout">
<input type="hidden" name="userid" value="#{userid}"> 
<input type="hidden" name="vid" value="#{vid}">
user_id: #{userid}
<input type="submit" value="logout">
</form><br>
)
		else
%Q(<form action="./" method="get" class="login_form">
user_id: <input type="text" size="10" name="userid" value="">
password: <input type="password" size="10" name="sig" value="">
<input type="hidden" name="cmd" value="login">
<input type="hidden" name="vid" value="#{vid}">
<input type="submit" value="login">
</form><br>
)
		end
	end
end
