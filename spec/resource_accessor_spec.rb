require_relative 'spec_helper'

require 'resource_accessor/resource_accessor'

describe ResourceAccessor do

  it "should get simple response" do
    response = subject.get_response :url => "http://www.etvnet.com/catalog/"

    response.should_not be_nil
  end

end

