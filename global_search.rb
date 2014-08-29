require "rubygems"
require 'net/https'
require "json"
require "uri"


API_KEY = ""
ENGINE_ID = ""


$keyword = [
  {"ruby" => 54},
  {"java" => 50},
  {"java work" => 30},
  {"php" => 10},
  {"perl" => 5},
  {"rails" => 48},
  {"gems" => 44}
]

class GlobalSearch

  def create_queries
    global_domains_array = []
    sets = []

    100.times do
      plurals = create_subset
      if plurals != ""
        sets << plurals.sort
      end
    end
    #sets.uniq.each do |set|
    create_subsets_new.each do |set|
      domains = get_response set
      global_domains_array += domains
    end


    global_domains_array.uniq.first(20)

  end


  def get_response keywords

    domains = []
    uri = "/customsearch/v1?"
    uri += "key=#{API_KEY}"
    uri += "&cref=#{ENGINE_ID}"
    uri += "&q=#{URI.encode_www_form_component(keywords)}"
    
    api_uri = URI.parse("https://www.googleapis.com#{uri}")
    p api_uri
    https = Net::HTTP.new(api_uri.host, api_uri.port)
    https.use_ssl = true
    https.verify_mode = OpenSSL::SSL::VERIFY_PEER
    https.ca_path = '/etc/ssl/certs' if File.exists?('/etc/ssl/certs')
    
    
    request = Net::HTTP::Get.new(api_uri.request_uri)
    @response = JSON.parse https.request(request).body
    p @response
    if @response["items"]
      @response["items"].each do |domain|
        url = URI.parse domain["link"]
        domains << url.host
      end
    elsif @response["error"]
      raise Exception, @response["error"]["message"]
    end

    domains

  end

  private

  def hash_value_sum h
    h.inject(0) { |result, h| result += h.values[0] }
  end

  def weight_of_subset keywords
    hash_value_sum(keywords).to_f / hash_value_sum($keyword).to_f
  end

  def create_subset
    subset = []
    keywords = $keyword.shuffle.first(4)
    if weight_of_subset(keywords) > 0.5
      keywords.each { |h| subset << h.keys[0] }
      array_of_keywords = subset
    else
      array_of_keywords = ""
    end
    array_of_keywords
  end

  def create_subsets_new
    sets = {}
    keywords_array = []
    j = 1
    $keyword.each do |h|
      sets[j.to_i] = h.keys[0]
      j += 1
    end
    subset = sets.keys.sort
    k = 4
      for i in 0..k do
        subset[i] = i
      end
      p = k
      while p >= 1 do
        keywords = ""
        subset[1..k].each do |key|
          sets.each do |h|
            if h[0] == key
              keywords = keywords + h[1] + " "
            end
          end
        end
        keywords_array << keywords
        subset[k] == (subset.length) ? p = p - 1 : p = k
        if p >= 1
          k.downto(p) do |i|
            subset[i] = subset[p] + i - p + 1
          end
        end
      end
    keywords_array
  end

end




@search = GlobalSearch.new
begin
  @search.create_queries.each do |item|
    p item
  end
rescue Exception => exception
  p exception.message  
end



