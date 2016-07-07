require 'net/https'
require 'cgi'

class ResourceAccessor
  attr_accessor :timeout, :ca_file, :validate_ssl_cert

  alias validate_ssl_cert? validate_ssl_cert

  def initialize timeout = 10000, ca_file = nil, validate_ssl_cert = false
    @timeout = timeout
    @ca_file = ca_file
    @validate_ssl_cert = validate_ssl_cert
  end

  def get_response params, headers = {}
    locate_response(params[:url], params[:query], params[:method], headers, params[:body], params[:escape], params[:cookie])
  end

  def get_soap_response params, headers = {}
    headers["SOAPAction"] = params[:soap_action] if params[:soap_action]
    headers["SOAPAction"] = "" unless headers["SOAPAction"]
    headers["Content-Type"] = "text/xml;charset=UTF-8" unless headers["Content-Type"]

    locate_response(params[:url], params[:query], params[:method], headers, params[:body], params[:escape], params[:cookie])
  end

  def get_ajax_response params, headers = {}
    headers['X-Requested-With'] = 'XMLHttpRequest'

    locate_response(params[:url], params[:query], params[:method], headers, params[:body], params[:escape], params[:cookie])
  end

  def get_json_response params, headers = {}
    headers["Content-Type"] = "application/json;charset=UTF-8"

    locate_response(params[:url], params[:query], params[:method], headers, params[:body], params[:escape], params[:cookie])
  end

  def get_cookie url, user_name, password
    headers = {"Content-Type" => "application/x-www-form-urlencoded; charset=UTF-8"}

    body = {:username => user_name, :password => password}

    response = locate_response(url, nil, :post, headers, body)

    response.response['set-cookie']
  end

  def self.query_from_hash(params, escape=true)
    return nil if params.nil? or params.empty?

    encode params, escape
  end

  def locate_response url, query, method, headers, body, escape=true, cookie=nil
    response = execute_request url, query, method, headers, body, escape, cookie

    if response.class == Net::HTTPMovedPermanently
      location = response['location']

      if URI(location).scheme
        new_uri = URI(location)
      else
        new_uri = URI(url)
        new_uri.path = location
      end

      response = execute_request new_uri.to_s, query, method, headers, body, escape, cookie
    end

    response
  end

  def execute_request url, query, method, headers, body, escape, cookie=nil
    headers["User-Agent"] = "Ruby/#{RUBY_VERSION}" unless headers["User-Agent"]
    headers["Content-Type"] = "application/x-www-form-urlencoded; charset=UTF-8" unless headers["Content-Type"]

    if cookie
      headers['Cookie'] = cookie
    end

    query_string = ResourceAccessor.query_from_hash(query, escape)
    new_url = query_string.nil? ? url : "#{url}?#{query_string}"
    # new_url = escape ? URI.escape(new_url) : new_url

    uri = URI.parse(URI.escape(new_url))

    connection = Net::HTTP.new(uri.host, uri.port)

    if uri.scheme == "https"
      connection.use_ssl = true

      if validate_ssl_cert?
        connection.ca_file = ca_file
        connection.verify_mode = OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT
      else
        connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
    end

    #request.basic_auth(@username, @password) unless @username

    method = :get if method.nil?

    if method == :get
      request = Net::HTTP::Get.new(uri.request_uri, headers)
    elsif method == :post
      request = Net::HTTP::Post.new(uri.request_uri, headers)

      request.body = body if body.kind_of? String
      request.set_form_data(body) if body.kind_of? Hash
    elsif method == :put
      request = Net::HTTP::Put.new(uri.request_uri, headers)

      request.body = body if body.kind_of? String
      request.set_form_data(body) if body.kind_of? Hash
    else
      request = Net::HTTP::Get.new(uri.request_uri, headers)
    end

    connection.read_timeout = timeout
    connection.open_timeout = timeout

    Timeout.timeout(timeout) do
      return connection.request(request)
    end
  end

  private

  def self.encode(value, escape=true, key = nil)
    case value
      when Hash  then value.map { |k,v| encode(v, escape, append_key(key,k)) }.join('&')
      when Array then value.map { |v| encode(v, escape, "#{key}[]") }.join('&')
      when nil   then "#{key}="
      else
        escape ? "#{key}=#{CGI.escape(value.to_s)}" : "#{key}=#{value.to_s}"
    end
  end

  def self.append_key(root_key, key)
    root_key.nil? ? key : "#{root_key}[#{key.to_s}]"
  end

end
