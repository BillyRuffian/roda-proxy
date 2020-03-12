# frozen_string_literal: true

require 'faraday'
require 'roda/proxy/version'

# :nodoc:
class Roda
  # :nodoc:
  module RodaPlugins
    # Roda plugin for simple API proxying
    module Proxy
    
      # Respond to the configure method to set the destination when proxying
      # Expects the following options:
      # [to] Required. The scheme and host of the proxy. Should not end with a slash.
      # [path] Optional. The path to append to the above for proxying.
      #        Should begin with a +/+. Defaults to +/+.
      # Example:
      #   plugin :proxy, to: 'https://foo.bar', path: '/my/api'
      def self.configure(app, opts = {})
        app.opts[:proxy_to] = opts.fetch(:to, nil) 
        app.opts[:proxy_path] = opts.fetch(:path, '/')
        
        raise 'Proxy host not set, use "plugin :proxy, to: http://example.com"' unless app.opts[:proxy_to]
      end

      # :nodoc:
      module RequestMethods
        
        # Proxies the request, forwarding all headers except +Host+ which is 
        # rewritten to be the destination host. The response headers, body and
        # status are returned to the client.
        def proxy
          method = Faraday.method(env['REQUEST_METHOD'].downcase.to_sym)
          f_response = method.call(_proxy_url) { |req| _proxy_request(req) }
          _respond(f_response)
        end
        
        # Conditionally proxies when +condition+ is true and with selective probability.
        # For instance, to proxy 50% of the time:
        #   r.proxy_when(probability: 0.5)
        # Condition can be a truthy value or a block / lambda, in which case
        # the result from the +#call+ is expected to be truthy.
        #   r.proxy_when( r.env['HTTP_PROXY_ME'] == 'true' )
        # The two parameters can be combined, the probability is evaluated first.
        #   r.proxy_when( r.env['HTTP_PROXY_ME'] == 'true', probability: 0.8 )
        # If and only if this method choses not to proxy is the block evaluated.
        # The block is then expected to return a meaningful response to Roda.
        def proxy_when(condition = true, probability: 1.0)
          shall_proxy = Random.rand(0.0..1.0) <= probability
                    
          if shall_proxy && ( condition.respond_to?(:call) ? condition.call : condition )
            yield(self)
          else
            proxy
          end
        end
        
        private
        
        def _proxy_url
          @_proxy_url ||= URI(roda_class.opts[:proxy_to])
                          .then { |uri| uri.path = roda_class.opts[:proxy_path]; uri }
                          .then { |uri| uri.query = env['QUERY_STRING']; uri }
        end
        
        def _proxy_headers
          env
            .select { |k, _v| k.start_with? 'HTTP_' }
            .reject { |k, _v| k == 'HTTP_HOST' }
            .transform_keys do |k| 
              k.sub(/^HTTP_/, '')
               .split('_')
               .map(&:capitalize)
               .join('-')
            end.merge({ 'Host' => "#{_proxy_url.host}:#{_proxy_url.port}" })
        end
        
        def _proxy_request(req)
          req.headers = _proxy_headers
        end
        
        def _respond(proxied_response)
          response.status = proxied_response.status
          proxied_response.headers.each { |k, v| response[k] = v }
          response.write(proxied_response.body)
        end
      end
    end
    
    register_plugin :proxy, Proxy
  end
end
