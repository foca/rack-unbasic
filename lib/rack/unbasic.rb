module Rack
  class Unbasic
    def initialize(app, &block) # :yields: middleware
      @app = app
      block.call(self) if block
    end

    def call(env)
      @env = env

      response = @app.call(@env)

      case response[0].to_i
        when 401; handle_unauthorized || response
        when 400; handle_bad_request || response
        else response
      end
    end

    def unauthorized(location)
      @unauthorized_location = location
    end

    def bad_request(location)
      @bad_request_location = location
    end

    private

    def handle_unauthorized
      return nil if @unauthorized_location.nil?
      [302, {"Location" => @unauthorized_location}, []]
    end

    def handle_bad_request
      return nil if @bad_request_location.nil?
      [302, {"Location" => @bad_request_location}, []]
    end
  end
end
