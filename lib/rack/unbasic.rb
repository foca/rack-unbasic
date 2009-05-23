module Rack
  class Unbasic
    def initialize(app, &middleware)
      @app = app
      @locations = {}
      middleware.call(self) if middleware
    end

    def call(env)
      @env = env

      clean_session_data

      response = @app.call(@env)

      case response[0].to_i
        when 401; handle_unauthorized || response
        when 400; handle_bad_request || response
        else response
      end
    end

    def unauthorized(location)
      @locations["unauthorized"] = location
    end

    def bad_request(location)
      @locations["bad_request"] = location
    end

    private

    def handle_unauthorized
      return nil if @locations["unauthorized"].nil?
      store_location_and_response_code(401)
      [302, {"Location" => @locations["unauthorized"]}, []]
    end

    def handle_bad_request
      return nil if @locations["bad_request"].nil?
      store_location_and_response_code(400)
      [302, {"Location" => @locations["bad_request"]}, []]
    end

    def store_location_and_response_code(code)
      @env["rack.session"]["rack-unbasic.return-to"] = @env["PATH_INFO"]
      @env["rack.session"]["rack-unbasic.code"] = code
    end

    def clean_session_data
      unless @env["rack.session"].respond_to?("delete")
        raise "You need to enable sessions for this middleware to work"
      end
      @env["rack-unbasic.return-to"] = @env["rack.session"].delete("rack-unbasic.return-to")
      @env["rack-unbasic.code"] = @env["rack.session"].delete("rack-unbasic.code")
    end
  end
end
