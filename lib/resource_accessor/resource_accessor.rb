require 'net/https'

require 'system_timer' if RUBY_VERSION.to_f < 1.9 and RUBY_PLATFORM != 'java'

class ResourceAccessor
  include SystemTimer if RUBY_VERSION.to_f < 1.9 and RUBY_PLATFORM != 'java'

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

  def get_cookie url, user_name, password
    headers = {"Content-Type" => "application/x-www-form-urlencoded; charset=UTF-8"}

    body = {:username => user_name, :password => password}

    response = locate_response(url, :post, headers, body)

    response.response['set-cookie']
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

    connection.read_timeout = timeout()
    connection.open_timeout = timeout()

    timeout_class = defined?(SystemTimer) ? SystemTimer : Timeout

    timeout_class.timeout(timeout) do
      return connection.request(request)
    end
  end

  def validate_ssl_cert?
    false
  end

  def ca_file
    nil
  end

  def timeout
    10000
  end
end
