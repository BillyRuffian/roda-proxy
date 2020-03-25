# Roda::Proxy

Roda Proxy is a very simple reverse proxy for Roda. It is designed to proxy APIs, it will not rewrite HTML. 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'roda-proxy'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install roda-proxy

## Usage

Add the plugin to your Roda app and pass it two parameters (one is required, one is optional).

```ruby
require 'roda'
require 'roda/proxy'

class App < Roda
  plugin :proxy, 
         to: 'https://my.server.com', 
         path_prefix: '/my/api/path'
```

The `to:` parameter is required. It should describe the scheme, host and port of the proxy. It should **not** end with a `/`.

The `path_prefix:` parameter is optional. It defaults to `/`. If you chose to specify it, it **should** start and end with a `/`.

The plugin provides both an unconditional and a conditional proxy directive.

To invoke the proxy in your routes, see this example:

```ruby
route do |r|
  # /my
  r.on 'my' do
    # /my/api
    r.on 'api' do
      # /my/api/path
      r.is 'path' do
        # GET /my/api/path
        r.get do
          r.proxy
        end
      end
    end
  end
end
```

The proxy will always be invoked. Headers and body are passed through unmodified in both directions with the exception of `Host` which is rewritten to match the target and `Via` which is created (or appended to if it already exists) to indicate the proxy path.

Also provided is a conditional proxy:

```ruby
route do |r|
  # /my
  r.on 'my' do
    # /my/api
    r.on 'api' do
      # /my/api/path
      r.is 'path' do
        # GET /my/api/path
        r.get do
          r.proxy_when(r.env['HTTP_PROXY'] == 'true', probability: 0.5) do
            'This request has not been proxied'
          end
        end
      end
    end
  end
end
```

With `proxy_when` the first optional parameter expects a truthy value or a block / lambda that returns a truthy value. This must be equivalent to `true` for the proxying to occur. The optional probability is a float between 0 and 1 indicating the probability that proxying will happen. Both parameters can be used alone or in isolation.

If and only if proxying does not occur will the block be evaluated and return to Roda for rendering.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
