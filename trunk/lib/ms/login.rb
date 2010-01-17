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
		userdb = Store.new('db/user.db')

		cookie = cgi.cookies['login']
		@c = cookie

		if (cookie.size == 1)
			vals = cookie[0].split(/,/)
			@sig, @userid = vals[0], vals[1]

			@login = userdb.transaction(true) {|db|
				db[@userid]['sig'] == @sig if db.root?(@userid)
			}
		end

		cmd = cgi['cmd']
		if (cmd == 'logout')
			@login = false
			@sig, @userid = '', ''
			set_cookie(cgi)
		elsif (cmd == 'login')
			@userid = cgi['userid'].strip
			@sig = cgi['sig'].strip
			raise ErrorMsg.new('認識できないIDです') if @userid == ''
			raise ErrorMsg.new('IDが長すぎます') if @userid.size > 20
			unless $DEBUG
				if (@sig == '' || @sig == 'LOCKED')
					raise ErrorMsg.new('認識できないパスワードです')
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
				else
					raise ErrorMsg.new("認証エラー")
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
