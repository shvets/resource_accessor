require 'log4r'
require 'resource_accessor'

GatewayError = Class.new(Exception)

class Gateway
  include Log4r

  attr_accessor :accessor, :logger

  def initialize
    @accessor = ResourceAccessor.new
    @accessor.timeout = 30

    @logger = Logger.new 'my_logger'
    #@logger.outputters = Outputter.stdout
  end

  def bad_response? response
    response.class == Net::HTTPNotFound or (response.kind_of?(Net::HTTPOK) and !!(response.body =~/error/))
  end

  def get params = {}, headers = {}
    with_exception_handler(params, headers) do |params, headers|
      @accessor.get_response(params, headers)
    end
  end

  def post params = {}, headers = {}
    with_exception_handler(params, headers) do |params, headers|
      @accessor.get_response(params.merge(:method => :post), headers)
    end
  end

  def soap_post params = {}, headers = {}
    with_exception_handler(params, headers) do |params, headers|
      response = @accessor.get_soap_response(params.merge(:method => :post), headers)

      logger.debug "#{params[:body]}" if params[:body]

      response
    end
  end

  def with_exception_handler params, headers, &code
    params[:url] = @url unless params[:url]

    begin
      response = code.call(params, headers)

      if bad_response?(response)
        log.error(response, "#{self.class.name} failed with #{response.code}:#{response.message}\n#{response.body}")

        raise GatewayError, "#{response.code} #{response.message}\n#{response.body}\n(URL: '#{params[:url]}')"
      else
        logger.info("Got #{response.code} response from #{self.class.name} Service")
      end

      response
    rescue GatewayError
      raise
    rescue Exception => e
      logger.error("#{self.class.name} received error: #{e}")

      raise GatewayError, "Error: #{e} (URL: '#{params[:url]}')"
    end
  end
end
