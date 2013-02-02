# ResourceAccessor - This library is used to simplify access to protected or unprotected http resource

## Installation

Add this line to to your Gemfile:

    gem "resource_accessor"

And then execute:

    $ bundle

## Usage

```ruby
    require 'resource_accessor'

    accessor = ResourceAccessor.new

    # to get unprotected resource
    response = accessor.get_response :url => some_url

    # to get cookie
    cookie = accessor.get_cookie login_url, user_name, password

    # to get protected resource through POST and post body as hash
    response = accessor.get_response :url => some_url, :method => :post, :cookie => cookie,
                                    :body => some_hash

    # to get protected resource through POST and post body as string
    response = accessor.get_response :url => some_url, :method => :post, :cookie => cookie,
                                    :body => some_string

    # to get AJAX resource
    response = accessor.get_ajax_response :url => some_url
    # or
    response = accessor.get_response {:url => some_url}, {'X-Requested-With' => 'XMLHttpRequest'}

    # to get SOAP resource
    response = accessor.get_soap_response :url => some_url
    # or
    response = accessor.get_response {:url => some_url}, {'SOAPAction' => 'someSoapOperation', 'Content-Type' => 'text/xml;charset=UTF-8'}

    # to get JSON resource
    response = accessor.get_response {:url => some_url}, {'Content-Type" => "application/json;charset=UTF-'}


```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request