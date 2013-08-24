# ResourceAccessor - This library is used to simplify access to protected or unprotected http resource

## Installation

Add this line to to your Gemfile:

    gem "resource_accessor"

And then execute:

    $ bundle

## Usage

Create accessor object:

```ruby
require 'resource_accessor'

accessor = ResourceAccessor.new
```

If you want to access unprotected resource located at **some_url**:

```ruby
response = accessor.get_response :url => some_url
```

If you want to get protected resource, first get a cookie and then access protected resource:

```ruby
# 1. Get cookie

cookie = accessor.get_cookie login_url, user_name, password

# 2.a. Get protected resource through POST and post body as hash

response = accessor.get_response :url => some_url, :method => :post, :cookie => cookie,
                                 :body => some_hash

# 2.b. Get protected resource through POST and post body as string

response = accessor.get_response :url => some_url, :method => :post, :cookie => cookie,
                                 :body => some_string
```
You have to specify HTTP method explicitly here (post).

If you want to get AJAX resource, add special header to the request or use special method:

```ruby
response1 = accessor.get_response {:url => some_url}, {'X-Requested-With' => 'XMLHttpRequest'}

response2 = accessor.get_ajax_response :url => some_url
```

If you want to get SOAP resource, same as before, add special header to the request or use special method:

```ruby
response1 = accessor.get_response {:url => some_url}, {'SOAPAction' => 'someSoapOperation', 'Content-Type' => 'text/xml;charset=UTF-8'}

response2 = accessor.get_soap_response :url => some_url
```

If you want to get JSON resource, same as before, add special header to the request or use special method:

```ruby
response = accessor.get_response {:url => some_url}, {'Content-Type" => "application/json;charset=UTF-8'}

response2 = accessor.get_json_response :url => some_url
```

You can setup timeout for your accessor object in milliseconds:

```ruby
accessor.timeout = 10000
```

If you need to work over ssl enable certificate validation before the call:

```ruby
accessor.validate_ssl_cert = true
accessor.ca_file = 'your cert file location'
```


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request