
module Cache
  class CacheMiss < StandardError
  end # CacheMiss
  
  EXPIRES_IN_MINUTE = 60
  EXPIRES_IN_HOUR = 60*60
  EXPIRES_IN_DAY = 60*60*24
  EXPIRES_IN_APPROX_MONTH = 60*60*24*30
  EXPIRES_IN_APPROX_YEAR = 60*60*24*30*365
  EXPIRES_NEVER = 'EXPIRES_NEVER'
  
  class BaseCache
    def initialize(hash={})
      @default_expires_in  = hash[:default_expires_in]  || EXPIRES_NEVER
      @auto_purge_interval = hash[:auto_purge_interval] || EXPIRES_NEVER
      @next_purge_time = Time.now
      @auto_purge_on_set = hash[:auto_purge_on_set] || false
      @auto_purge_on_get = hash[:auto_purge_on_get] || false
    end
    
    def clear
    end
    
    def purge
      if @auto_purge_interval != EXPIRES_NEVER
        @next_purge_time = Time.now + @auto_purge_interval
      end
    end
    
    def size
    end
    
    def [](key)
      purge if @auto_purge_on_get && Time.now > @next_purge_time
    end
    
    def []=(key,v1,v2)
      purge if @auto_purge_on_set && Time.now > @next_purge_time
    end
    
    def get_object(key)
      str = self[key]
      raise CacheMiss, key unless str
      Marshal.load(str)
    end
    
    def set_object(key,obj,expires=EXPIRES_NEVER)
      str = Marshal.dump(obj)
      self[key] = str
    end
    
    def delete(key)
    end
    
  end
  
  class MemoryCache < BaseCache
    def initialize(hash={})
      super
      @hash = {}
    end
    
    def clear
      super
      @hash = {}
      GC.start
    end
    
    def purge
      current = Time.now
      @hash.delete_if {|key,(value,expires)|
        if expires != EXPIRES_NEVER
          if current >= expires
            true
          else
            false
          end
        end
      }
      super
    end
    
    def size
      @hash.size
    end
    
    def [](key)
      super
      if @hash.has_key? key
        value,time = @hash[key]
        if time==EXPIRES_NEVER || Time.now < time
          value
        else
          nil
        end
      else
        nil
      end
    end
    
    def []=(key,v1,v2=nil)
      super
      if v2
        @hash[key] = [v2,Time.now+v1]
      else
        @hash[key] = [v1,@default_expires_in]
      end
    end
    
    def get_object(key)
      self[key]
    end
    
    def set_object(key,obj,expires=EXPIRES_NEVER)
      self[key,expires] = str
    end
    
    def delete(key)
      @hash.delete(key)
    end
  end # MemoryCache
  
  
  class GDBMCache < BaseCache
    def initialize(hash={})
      super
      require 'gdbm'
      @db = GDBM.open(hash[:path])
    end
    
    def clear
      super
      @db.clear
    end
    
    def purge
      current = Time.now
      @db.delete_if {|key,v|
        expire,value = v.split(/\t/,2)
        if expires != EXPIRES_NEVER
          expires = Time.at(expires.to_i)
          if current >= expires
            true
          else
            false
          end
        end
      }
      @db.reorganize
      super
    end
    
    def size
      @hash.size
    end
    
    def [](key)
      super
      if @db.has_key? key
        v = @db[key]
        expires,value = v.split(/\t/,2)
        if expires==EXPIRES_NEVER || Time.now < Time.at(expires.to_i)
          value
        else
          nil
        end
      else
        nil
      end
    end
    
    def []=(key,v1,v2=nil)
      super
      if v2
        @db[key] = [(Time.now.to_i+v1).to_s,v2].join("\t")
      else
        @db[key] = [@default_expires_in,v1].join("\t")
      end
    end
    
    def delete(key)
      @db.delete(key)
    end
  end # GDBMCache
  
  class FileCache < BaseCache
    private
    def to_path(key)
      h = key.hash % 65536
      x = h / 256
      y = h % 256
      z = CGI::escape(key)
      "%s/%02x/%02x/%s" % [@root_dir,x,y,z]
    end
    
    public
    def initialize(hash={})
      super
      require 'fileutils'
      require 'cgi'
      @root_dir = hash[:root_dir] || '/tmp'
      FileUtils.mkdir_p(@root_dir)
    end
    
    def clear
      super
      FileUtils.rm_rf(@root_dir)
    end
    
    def purge
      current = Time.now
      (0..0xff).each {|x|
        (0..0xff).each {|y|
          dir = "%s/%02x/%02x/" % [@root_dir,x,y]
          if FileTest.exist? dir
            rm_list = []
            Dir.entries(dir).each {|path|
              next if path=='.' || path=='..'
              v = IO.read(dir+path)
              expires,value = v.split(/\t/,2)
              if expires != EXPIRES_NEVER
                expires = Time.at(expires.to_i)
                if current >= expires
                  rm_list << path
                end
              end
            }
            FileUtils.rm_rf(rm_list)
          end
        }
      }
      super
    end
    
    def size
      n = 0
      (0..0xff).each {|x|
        (0..0xff).each {|y|
          dir = "%s/%02x/%02x/" % [@root_dir,x,y]
          if FileTest.exist? dir
            n += 1
          end
        }
      }
      n
    end
    
    def [](key)
      super
      path = to_path(key)
      if FileTest.exist?(path)
        v = IO.read(path)
        expires,value = v.split(/\t/,2)
        if expires==EXPIRES_NEVER || Time.now < Time.at(expires.to_i)
          value
        else
          nil
        end
      else
        nil
      end
    end
    
    def []=(key,v1,v2=nil)
      super
      path = to_path(key)
      dir = File.dirname(path)
      FileUtils.mkdir_p(dir)
      if v2
        exp = v1 == EXPIRES_NEVER ? EXPIRES_NEVER : (Time.now.to_i+v1).to_s
      else
        exp = @default_expires_in == EXPIRES_NEVER ? EXPIRES_NEVER : (Time.now.to_i+@default_expires_in).to_s
      end
      open(path,'wb') {|f|
        f.write [exp,v1].join("\t")
      }
    end
    
    def delete(key)
      path = to_path(key)
      FileUtils.rm(path, :force)
    end
  end # FileCache
  
  class MemCached < BaseCache
    private
    def memcached_get(key)
      @sock.write "get #{key}\r\n"
      text = @sock.gets # VALUE <key> <flags> <bytes>\r\n
      return nil if text=~/\AEND/
      v,key,flags,bytes = text.split(/ /)
      bytes = bytes.to_i
      value = @sock.read(bytes)
      @sock.read(2) # "\r\n"
      @sock.gets # "END\r\n"
      value
    end
    
    def memcached_set(key,value,exptime)
      @sock.write "set #{key} 0 #{exptime} #{value.size}\r\n"
      @sock.write value + "\r\n"
      @sock.gets
    end
    
    def memcached_delete(key)
      @sock.write "delete #{key} 0\r\n"
      @sock.gets
    end
    
    def memcached_size
      size = 0
      @sock.write "stats\r\n"
      while text=@sock.gets
        case text
        when /\ASTAT curr_items (\d+)\r\n/
          size = $1.to_i
        when /\AEND/
          break
        end
      end
      size
    end
    
    def memcached_flush_all
      @sock.write "flush_all\r\n"
      @sock.gets
    end
    
    public
    def initialize(hash={})
      super
      require 'socket'
      @sock = TCPSocket.open(hash[:host], hash[:port])
    end
    
    def clear
      super
      memcached_flush_all
    end
    
    def purge
      super
    end
    
    def size
      memcached_size
    end
    
    def [](key)
      super
      v = memcached_get(key)
    end
    
    def []=(key,v1,v2=nil)
      super
      if v2
        memcached_set(key,v2,(Time.now.to_i+v1))
      else
        memcached_set(key,v1,0)
      end
    end
    
    def delete(key)
      memcached_delete(key)
    end
    
  end # MemCached
end # Cache
