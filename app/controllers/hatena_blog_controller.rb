#coding:utf-8
require 'open-uri'
require 'RMagick'
class HatenaBlogController < ApplicationController
  protect_from_forgery :except => [:fotolife_upload] 
  @@percent_min = 10
  @@percent_max = 200
  @@direct_min = 10
  @@direct_max = 4000
  def index
    respond_to do |format|
      format.html # index.html.erb
    end
  end
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
  def fotolife_upload
    user_name = params[:id]
    password_digest = params[:digest]
    base64nonce = params[:nonce]
    timestamp = params[:timestamp]
    descriptor = params[:descriptor]
    image_data = params[:imagedata]
    folder_name = params[:folder]
    type = params[:type]

    magick = Magick::Image.from_blob(Base64.decode64(image_data))
    if descriptor === "bmp" then
      magick[0].format = "jpeg"
      descriptor = "jpeg"
    end

    case type
    when "percent" then
      percent = params[:percent].to_i
      if percent >= @@percent_min && percent <= @@percent_max then
        factor = percent * 0.01
        magick[0].scale!(factor)
      end
    when "direct" then
      uwidth = params[:uwidth].to_i
      uheight = params[:uheight].to_i
      if (uwidth >= @@direct_min && uwidth <= @@direct_max) && (uheight >= @@direct_min && uheight <= @@direct_max) then
        magick[0].scale!(uwidth,uheight)
      end
    end
    image_data = Base64.encode64(magick[0].to_blob)
    magick[0].destroy!

    wsse = "UsernameToken Username=\"#{user_name}\",PasswordDigest=\"#{password_digest}\",Nonce=\"#{base64nonce}\",Created=\"#{timestamp}\""

    
    header = {'X-WSSE' =>  wsse,'Accept' => 'application/x.atom+xml, application/xml, text/xml, */*'}
    entry = <<-"ENTRY"
    <entry xmlns="http://purl.org/atom/ns#">
      <content mode="base64" type="image/#{descriptor}">
        #{image_data}
      </content>
      #{(!folder_name.nil? and folder_name.length > 0) ? "<dc:subject>#{folder_name}</dc:subject>" : ""}
    </entry>
    ENTRY

    client = Net::HTTP.new('f.hatena.ne.jp',80)
    response = client.post('/atom/post',entry,header)

    response_text = nil
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

    render :json => response_text,:status=>response.code
  end
end
