#coding:utf-8
class HatenaBlogController < ApplicationController
  def newentry
    url = "http://blog.hatena.ne.jp/-/recent"
    purl = URI.parse(url)
    req = Net::HTTP::Get.new(purl.path)
    response = Net::HTTP.start(purl.host,purl.port) { |http|
      http.request(req)
    }
    response_body = Nokogiri::HTML(response.body)

    article_array = Array.new
    items = response_body.css('div.item')
    for n in 0..4 do
      item = items[n]
      a_title = item.css('div.entry-title > a')
      href = a_title.attr('href')
      title = a_title.text()

      article = item.css('p.article').text().gsub(' ','').gsub("\n",' ')
      user = item.css('span.meta > a').text().gsub(' ','').gsub("\n",' ')
      time = item.css('span.meta > time').text()
      article_array.push('{"href":"' + href + '","title":"' + title + '","article":"' + article + '","user":"' + user + '","time":"' + time + '"}')
    end

    response_text = '{"articles":[' + article_array.join(',') + ']}'

    render :json => response_text,:status => '200'
  end
end
