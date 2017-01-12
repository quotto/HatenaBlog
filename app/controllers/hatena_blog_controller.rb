#coding:utf-8
require 'open-uri'
require 'capybara/poltergeist'
class HatenaBlogController < ApplicationController
  protect_from_forgery :except => [:irasutoya_search,:irasutoya_upload] 
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
  def irasutoya_search
    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new(app, {:js_errors => false, :timeout => 5000 })
    end

    session = Capybara::Session.new(:poltergeist)

    session.driver.headers = {
      'User-Agent' => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2564.97 Safari/537.36"
    }

    url = !params[:query].nil? ? "http://www.irasutoya.com/search?q=#{URI.encode(params[:query])}" : params[:url]

    response_text = nil
    begin
      session.driver.visit url
      response = session.html

      results = Array.new
      html_body = Nokogiri::HTML(response)
      html_body.css('.box').each do |box|
        thumbnail = box.css('.boxim').css('img').attr('src')
        img_url = box.css('.boxim').css('a').attr('href')
        title = box.css('.boxmeta').css('h2 > a').text;
        results.push('{"thumbnail":"' + thumbnail + '","url":"' + img_url + '","title":"'+title + '"}')
      end

      next_page = html_body.css('#blog-pager-older-link > a')
      next_page_link = nil
      if !(next_page.blank?) then
        puts next_page
        next_page_link = next_page.attr('href').value
      end

      response_text = '{"images":[' + results.join(',') + ']'
      if !next_page_link.nil? then
        response_text = response_text + ',"next":"' + next_page_link + '"'
      end

      response_text = response_text + '}'

    ensure
      session.driver.quit
    end

    render :json => response_text, :status => '200'
  end
  def irasutoya_upload
    url = params[:url]
    title = params[:title]

    purl = URI.parse(url)
    req = Net::HTTP::Get.new(purl.path)
    response = Net::HTTP.start(purl.host,purl.port) { |http|
      http.request(req)
    }
    response_body = Nokogiri::HTML(response.body)

    image_url = response_body.css('#post > .entry > .separator > a > img').attr('src').value

    rindex = image_url.rindex(".")
    image_type = image_url.slice(rindex + 1,image_url.length - rindex)
    if image_type == 'jpg' then
      image_type = 'jpeg'
    end

    base64_image = []
    open(image_url,:ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE) do |f|
      base64_image = [f.read].pack('m')
    end

    user_name = params[:id]
    password_digest = params[:digest]
    base64nonce = params[:nonce]
    timestamp = params[:timestamp]

    wsse = "UsernameToken Username=\"#{user_name}\",PasswordDigest=\"#{password_digest}\",Nonce=\"#{base64nonce}\",Created=\"#{timestamp}\""

    puts wsse

    header = {'X-WSSE' =>  wsse,'Accept' => 'application/x.atom+xml, application/xml, text/xml, */*'}
    entry = <<-"ENTRY"
    <entry xmlns="http://purl.org/atom/ns#">
      <title>#{title}</title>
      <content mode="base64" type="image/#{image_type}">
        #{base64_image}
      </content>
      <dc:subject>Hatena Blog</dc:subject>
    </entry>
    ENTRY

    client = Net::HTTP.new('f.hatena.ne.jp',80)
    response = client.post('/atom/post',entry,header)

    response_text = nil
    puts response.code
    case response.code
    when '201' then
      response_xml = Nokogiri::XML(response.body)
      syntax = response_xml.xpath('//hatena:syntax');
      image_url = response_xml.xpath('//hatena:imageurl'); 
      image_urlsmall = response_xml.xpath('//hatena:imageurlsmall'); 

      response_text = '{"syntax": "' + syntax.text + '", "imageurl": "' + image_url.text + '", "imageurlsmall": "' + image_urlsmall.text + '"}';
    else 
      response_text = '{"message": "' + response.msg + '"}';
    end

    puts response.body

    render :json => response_text,:status=>response.code
  end
end
