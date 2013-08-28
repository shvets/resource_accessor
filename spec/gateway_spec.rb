require File.dirname(__FILE__) + '/spec_helper'

require 'gateway'

describe Gateway do
  let(:some_https_url) { "https://somehost.com" }

  let(:simple_response) do
    response = Net::HTTPSuccess.new "1.1", "200", "success"
    response.stubs(:stream_check => '')
    response
  end

  it "uses certificate file and OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT as verify mode if validate_ssl_cert is on" do
    subject.accessor.validate_ssl_cert = true
    subject.accessor.ca_file = 'some_ca_file'

    Net::HTTP.any_instance.expects(:use_ssl=).with(true)
    Net::HTTP.any_instance.expects(:verify_mode=).with(OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT)
    Net::HTTP.any_instance.expects(:ca_file=).with('some_ca_file')

    Net::HTTP.any_instance.stubs(:request => stub_everything)

    subject.get(:url => some_https_url)
  end

  it "uses VERIFY_NONE to enforce certificate validation" do
    subject.accessor.validate_ssl_cert = false
    subject.accessor.ca_file = 'some_ca_file'

    Net::HTTP.any_instance.expects(:use_ssl=).with(true)
    Net::HTTP.any_instance.expects(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
    Net::HTTP.any_instance.expects(:ca_file=).with('some_ca_file').never

    Net::HTTP.any_instance.stubs(:request => stub_everything)

    subject.get(:url => some_https_url)
  end

  it "logs error and raises exception if response is bad" do
    Net::HTTP.any_instance.expects(:request => simple_response)

    subject.stubs(:bad_response? => true)

    subject.logger.expects(:error)

    expect do
      subject.soap_post(:url => some_https_url, :body => 'body')
    end.to raise_error(GatewayError)
  end

  it "should set content type to text/xml for soap post request" do
    Net::HTTP.any_instance.expects(:request => simple_response)

    params = {:url => some_https_url}
    headers = {}

    subject.soap_post(params, headers)

    headers["Content-Type"].should match "text/xml"
  end

  it "should set content type to application/x-www-form-urlencoded for regular post request" do
    Net::HTTP.any_instance.expects(:request => simple_response)

    params = {:url => some_https_url}
    headers = {}

    subject.post(params, headers)

    headers["Content-Type"].should match "application/x-www-form-urlencoded"
  end

  it "logs body of request" do
    Net::HTTP.any_instance.expects(:request => simple_response)

    subject.logger.expects(:debug).with('some_request')

    subject.soap_post(:url => some_https_url, :body => 'some_request')
  end

  it "should log timeout errors and raise GatewayError" do
    subject.logger.expects(:error).with("#{subject.class.name} received error: Timeout::Error")
    Net::HTTP.any_instance.expects(:request).raises(Timeout::Error.new(nil))

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

    expect do
      subject.get(:url => some_https_url, :body => '')
    end.to raise_error(GatewayError)
  end

end
