require_relative 'spec_helper'

require 'resource_accessor'

describe ResourceAccessor do

  it "should get simple response" do
    response = subject.get_response :url => "http://www.lenta.ru"

    response.should_not be_nil
  end

  it "query_string_from_hash escapes ampersands and spaces in values" do
    subject.query_from_hash({'name1' => "name 1", 'name2' => "name 2"}).should eql "name1=name+1&name2=name+2"
  end

  it "query_string_from_hash maps properly nil values " do
    subject.query_from_hash({'param1' => nil, 'param2' => "A&B", 'param3' => "C & D"}).should eql "param1=&param2=A%26B&param3=C+%26+D"
  end

end

