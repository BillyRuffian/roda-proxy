require "faraday"
require "roda/proxy/version"

class Roda
  module RodaPlugins
    module Proxy
    
      def self.configure(app, opts = {})
        app.opts[:proxy_to] = opts.fetch(:to, nil) 
        app.opts[:proxy_path] = opts.fetch(:path, '/')
        
        raise 'Proxy host not set, use "plugin :proxy, to: http://example.com"' unless app.opts[:proxy_to]
      end

    
      module RequestMethods
        def proxy
          #pp @_request.env
          #pp @_request.body.read
          method = Faraday.method(env['REQUEST_METHOD'].downcase.to_sym)
          pp _proxy_url
          pp _proxy_headers
          pp roda_class
          f_response = method.call(_proxy_url) { |req| _proxy_request(req) }
          response.status = f_response.status
          f_response.headers.each { |k,v| response[k] = v }
          response.write(f_response.body)
          halt
        end
        
        private
        
        def _proxy_url
          @_proxy_uri ||= URI(roda_class.opts[:proxy_to])
            .then { |uri| uri.path = roda_class.opts[:proxy_path] ; uri }
            .then { |uri| uri.query = env['QUERY_STRING'] ; uri }
        end
        
        def _proxy_headers
          env
            .select { |k,_v| k.start_with? 'HTTP_'}
            .reject { |k,_v| k == 'HTTP_HOST' }
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
      end
    end
    
    register_plugin :proxy, Proxy
  end
end
