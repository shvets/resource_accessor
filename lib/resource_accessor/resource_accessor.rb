require 'net/https'
require 'cgi'

class ResourceAccessor
  attr_accessor :timeout, :ca_file, :validate_ssl_cert

  def initialize timeout = 10000, ca_file = nil, validate_ssl_cert = false
    @timeout = timeout
    @ca_file = ca_file
    @validate_ssl_cert = validate_ssl_cert
  end

  def get_response params, headers = {}
    locate_response(params[:url], params[:method], headers, params[:body], params[:cookie])
  end

  def get_soap_response params, headers = {}
    headers["SOAPAction"] = params[:soap_action] if params[:soap_action]
    headers["SOAPAction"] = "" unless headers["SOAPAction"]
    headers["Content-Type"] = "text/xml;charset=UTF-8" unless headers["Content-Type"]

    locate_response(params[:url], params[:method], headers, params[:body], params[:cookie])
  end

  def get_ajax_response params, headers = {}
    headers['X-Requested-With'] = 'XMLHttpRequest'

    locate_response(params[:url], params[:method], headers, params[:body], params[:cookie])
  end

  def get_json_response params, headers = {}
    headers["Content-Type"] = "application/json;charset=UTF-8"

    locate_response(params[:url], params[:method], headers, params[:body], params[:cookie])
  end

  def get_cookie url, user_name, password
    headers = {"Content-Type" => "application/x-www-form-urlencoded; charset=UTF-8"}

    body = {:username => user_name, :password => password}

    response = locate_response(url, :post, headers, body)

    response.response['set-cookie']
  end

  def query_from_hash(params)
    return "" if params.empty?

    params.sort.map {|k, v| "#{k}=#{v.nil? ? '' : CGI.escape(v)}"}.join("&")
  end

  private

  def locate_response url, method, headers, body, cookie=nil
    response = execute_request url, method, headers, body, cookie

    if response.class == Net::HTTPMovedPermanently
      response = execute_request response['location'], method, headers, body, cookie
    end

    response
  end

  def execute_request url, method, headers, body, cookie=nil
    headers["User-Agent"] = "Ruby/#{RUBY_VERSION} (Macintosh; Intel Mac OS X 10.8)" unless headers["User-Agent"]
    headers["Content-Type"] = "application/x-www-form-urlencoded; charset=UTF-8" unless headers["Content-Type"]

    if cookie
      headers['Cookie'] = cookie
    end

    uri = URI.parse(URI.escape(url))

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
    else
      request = Net::HTTP::Get.new(uri.request_uri, headers)
    end

    connection.read_timeout = timeout
    connection.open_timeout = timeout

    Timeout.timeout(timeout) do
      return connection.request(request)
    end
  end

  def validate_ssl_cert?
    validate_ssl_cert
  end

end
