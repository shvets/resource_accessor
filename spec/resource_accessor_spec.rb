require_relative 'spec_helper'

require 'resource_accessor'

describe ResourceAccessor do
  context "#get_response" do
    it "should use provided url" do
      Net::HTTP.expects(:new).with("someurl.com", 80).returns(stub_everything(:request => stub_everything))

      subject.get_response :url => "http://someurl.com"
    end

    it "should use provided query parameters" do
      Net::HTTP.expects(:new).with("someurl.com", 80).returns(stub_everything(:request => stub_everything))

      Net::HTTP::Get.expects(:new).with("/?param1=p1&param2=p2", {'User-Agent' => 'user_agent', 'Content-Type' => 'content_type'})

      subject.get_response({:url => "http://someurl.com", :query => {:param1 => 'p1', :param2 => 'p2'}},
                           {'User-Agent' => 'user_agent', 'Content-Type' => 'content_type'})
    end
  end

  context "#query_from_hash" do
    it "escapes ampersands and spaces in values" do
      subject.class.query_from_hash({:name1 => "name 1", :name2 => "name 2"}).should eql "name1=name+1&name2=name+2"
    end

    it "maps properly nil values " do
      subject.class.query_from_hash({:param1 => nil, :param2 => "A&B", :param3 => "C & D"}).should eql "param1=&param2=A%26B&param3=C+%26+D"
    end
  end

end

