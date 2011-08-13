require 'net/http'
require 'xmlsimple'

class Clip
  include MongoMapper::Document

  key :source, String
  key :source_id, String

  key :title, String
  key :length, Integer
  key :link, String

  def self.youtube_search(query)
    query = CGI.escape(query)
    url = URI.parse("http://gdata.youtube.com")
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.get("/feeds/api/videos?q=#{query}&start-index=1&max-results=10&v=2&format=5")
    }

    xml = XmlSimple.xml_in(res.body)
    (xml['entry'] || []).map do |x|
      {
        :title => x['title'][0],
        :length => x['group'][0]['duration'][0]['seconds'].to_i,
        :link => (x['content'] || {})['src'],
        :source => 'youtube',
        :source_id => x['group'][0]['videoid'][0]
      }
    end
  end

  def self.live_suggest(query)
    query = CGI.escape(query)
    url = URI.parse("http://suggestqueries.google.com")
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.get("/complete/search?hl=en&ds=yt&client=youtube&hjson=t&q=#{query}&cp=1")
    }
    JSON.parse(res.body)[1].collect(&:first)
  end
end
