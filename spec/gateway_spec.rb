require File.dirname(__FILE__) + '/spec_helper'

GatewayError = Class.new(Exception)

require 'resource_accessor'
require 'log4r'

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
    response.class == Net::HTTPNotFound or (response.kind_of?(Net::HTTPSuccess) and !!(response.body =~/error/))
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
    begin
      response = code.call(params, headers)

      if bad_response?(response)
        log.error(response, "#{self.class.name} failed with #{response.code}:#{response.message}\n#{response.body}")

        raise GatewayError, "#{response.code} #{response.message}\n#{response.body}\n(URL: '#{params[:url]}')"
      else
        logger.info("Got #{response.code} response from #{self.class.name} Service")
      end
    rescue GatewayError
      raise
    rescue Exception => e
      logger.error("#{self.class.name} received error: #{e}")

      raise GatewayError, "Error: #{e} (URL: '#{params[:url]}')"
    end
  end
end

describe Gateway do
  let(:some_https_url) { "https://somehost.com" }

  let(:simple_response) do
    good_response = Net::HTTPSuccess.new "1.1", "200", "success"
    good_response.stubs(:stream_check => '')
    good_response
  end

  it "uses certificate file and OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT as verify mode if validate_ssl_cert is on" do
    subject.accessor.validate_ssl_cert = true
    subject.accessor.ca_file = 'some_ca_file'

    Net::HTTP.any_instance.expects(:use_ssl=).with(true)
    Net::HTTP.any_instance.expects(:verify_mode=).with(OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT)
    Net::HTTP.any_instance.expects(:ca_file=).with('some_ca_file')

    Timeout.expects(:timeout).yields
    Net::HTTP.any_instance.stubs(:request).returns(stub_everything(:kind_of? => true))

    subject.get(:url => some_https_url)
  end

  it "uses VERIFY_NONE to enforce certificate validation" do
    subject.accessor.validate_ssl_cert = false
    subject.accessor.ca_file = 'some_ca_file'

    Net::HTTP.any_instance.expects(:use_ssl=).with(true)
    Net::HTTP.any_instance.expects(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
    Net::HTTP.any_instance.expects(:ca_file=).with('some_ca_file').never

    Timeout.expects(:timeout).yields
    Net::HTTP.any_instance.stubs(:request).returns(stub_everything(:kind_of? => true))

    subject.get(:url => some_https_url)
  end

  it "logs error and raises exception if response is bad" do
    Timeout.expects(:timeout).yields
    Net::HTTP.any_instance.expects(:request).returns(simple_response)

    subject.stubs(:bad_response? => true)

    subject.logger.expects(:error)

    expect do
      subject.soap_post(:url => some_https_url, :body => 'body')
    end.to raise_error(GatewayError)
  end

  it "should set content type to text/xml for soap post request" do
    Net::HTTP.any_instance.expects(:request).returns(simple_response)

    Timeout.expects(:timeout).yields

    params = {:url => some_https_url}
    headers = {}

    subject.soap_post(params, headers)

    headers["Content-Type"].should match "text/xml"
  end

  it "should set content type to application/x-www-form-urlencoded for regular post request" do
    post_request = Net::HTTP::Post.new 'someurl.com'
    Net::HTTP::Post.expects(:new).returns(post_request)

    Net::HTTP.any_instance.expects(:request => simple_response)

    Timeout.expects(:timeout).yields

    params = {:url => some_https_url}
    headers = {}

    subject.post(params, headers)

    headers["Content-Type"].should match "application/x-www-form-urlencoded"
  end

  it "should log timeout errors and raise GatewayError" do
    subject.logger.expects(:error).with("#{subject.class.name} received error: Timeout::Error")
    Net::HTTP.any_instance.expects(:request).raises(Timeout::Error.new(nil))

    Timeout.expects(:timeout).yields

    expect do
      subject.soap_post(:url => some_https_url, :body => 'body')
    end.to raise_error(GatewayError)
  end

  it "logs SocketError and raises GatewayError when service not found" do
    subject.logger.expects(:error).with("#{subject.class.name} received error: SocketError")

    Net::HTTP.any_instance.expects(:request).raises(SocketError)
    Timeout.expects(:timeout).yields

    expect do
      subject.get(:url => some_https_url, :body => '')
    end.to raise_error(GatewayError)
  end

  it "logs Errno::ECONNRESET and raises GatewayError when service connection reset" do
    subject.logger.expects(:error).with("#{subject.class.name} received error: Connection reset by peer")

    Net::HTTP.any_instance.expects(:request).raises(Errno::ECONNRESET)
    Timeout.expects(:timeout).yields

    expect do
      subject.get(:url => some_https_url, :body => '')
    end.to raise_error(GatewayError)
  end

  it "logs body of request" do
    Net::HTTP.any_instance.expects(:request).returns(simple_response)

    subject.logger.expects(:debug).with('some_request')

    subject.soap_post(:url => some_https_url, :body => 'some_request')
  end

end
