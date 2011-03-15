#2010/01/15:add module:tkt for out entries data
#2011/02/12:mod module:tkt for add read xml data method
require 'rexml/document'
require 'kconv'
require 'parsedate'
module XML
	class Base
		attr_reader :xml_path, :xml_doc
		def initialize(path)
			@xml_path = path
			@xml_doc = nil
			
			if path != ''
				File.open(@xml_path) {|fp|
					@xml_doc = REXML::Document.new fp
				}
			end
		end

		def get_element(element, tag)
			element[tag]
		end
		
		def get_text(element, tag)
			get_element(element, tag).text
		end
		
		def get_under_element(element, tag)
			element.elements[tag]
		end
		
		def get_under_text(element, tag)
			get_under_element(element, tag).text
		end
		
		def get_attribute(element, attr)
			element.attributes.get_attribute(attr).value
		end
		
		#create time object by yyyy/mm/dd hh:mm:ss
		def createTime(data)
			dates = ParseDate.parsedate(data)
			Time.gm(dates[0], dates[1], dates[2], dates[3], dates[4], "GMT")
		end

	end
	
	class Vil < Base
		ROOT_TAG = 'VilsInfo'
		attr_reader :max_entries, :link, :site
		
		def initialize(path)
			super(path)
			@max_entries = 13
			@min_entries = 6
			@link = ''
			@site = ''
			
		end
		
		def get()
			get_header()
			
			datas = {\
				:max_entries => @max_entries,
				:min_entries => @min_entries,
				:site => @site,
				:link => @link,
				:vils => []
			}
			
			@xml_doc.elements.each(ROOT_TAG + '/vil') do |element|
				status = get_under_element(element, 'status')
				
				vil = {\
					:vid => get_attribute(element, 'id'),
					:vname => get_under_text(element, 'name'),
					:link => get_under_text(element, 'link'),
					:entries => get_under_text(element, 'entries'),
					:update_time => createTime(get_under_text(element, 'updateTime')),
					:state => get_attribute(status, 'state'),
					:status => status.text,
				}
				datas[:vils].push(vil)
			end
			
			datas
		end
		def get_header()
			@site = get_text(@xml_doc.elements, ROOT_TAG + '/title')
			@link = get_text(@xml_doc.elements, ROOT_TAG + '/link')
			@max_entries = get_text(@xml_doc.elements, ROOT_TAG + '/maxEntries')
			@min_entries = get_text(@xml_doc.elements, ROOT_TAG + '/minEntries')
		end
		
		def read(data)
			@xml_doc = REXML::Document.new data
			
			get()
		end
	end
end