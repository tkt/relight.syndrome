#2011/09/30:add module:tkt for out rss
require 'rss'
module RSS
	class Base
		attr_reader :path, :xml_doc
		def initialize(path, ver)
			@path = path
			@ver = ver
			
		end

	end
	
	
end