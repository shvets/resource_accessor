require 'rspec'

# add lib directory
$:.unshift File.dirname(__FILE__) + '/../lib'

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:

  config.mock_with :mocha
end



