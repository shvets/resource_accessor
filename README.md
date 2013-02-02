# ResourceAccessor - This library is used to simplify access to protected or unprotected http resource

## Installation

Add this line to to your Gemfile:

    gem "resource_accessor"

And then execute:

    $ bundle

## Usage

    require 'resource_accessor'

    accessor = ResourceAccessor.new

    cookie = accessor.get_cookie

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request