require "rack"

module Rack
  class Unbasic
    def initialize(app, &block) # :yields: middleware
      @app = app
      @locations = {}
      block.call(self) if block
    end

    def call(env)
      @env = env

      clean_session_data

      authorize_from_params || authorize_from_session

      @response = @app.call(@env)

      case status_code
      when 401
        unauthorized_response
      when 400
        bad_request_response
      else
        store_credentials
        @response
      end
    end

    def unauthorized(location)
      @locations["unauthorized"] = location
    end

    def bad_request(location)
      @locations["bad_request"] = location
    end

    private

    def unauthorized_response
      return @response if @locations["unauthorized"].nil?
      store_location_and_response_code
      [302, {"Location" => @locations["unauthorized"]}, []]
    end

    def bad_request_response
      return @response if @locations["bad_request"].nil?
      store_location_and_response_code
      [302, {"Location" => @locations["bad_request"]}, []]
    end

    def store_location_and_response_code
      session["rack-unbasic.return-to"] = @env["PATH_INFO"]
      session["rack-unbasic.code"] = status_code
    end

    def clean_session_data
      unless session.respond_to?("delete")
        raise "You need to enable sessions for this middleware to work"
      end
      @env["rack-unbasic.return-to"] = session.delete("rack-unbasic.return-to")
      @env["rack-unbasic.code"] = session.delete("rack-unbasic.code")
    end

    def authorize_from_params
      return nil if request.params["username"].nil? || request.params["password"].nil?
      send_http_authorization(request.params["username"], request.params["password"])
    end

    def authorize_from_session
      return nil if session["rack-unbasic.username"].nil? || session["rack-unbasic.password"].nil?
      send_http_authorization(session["rack-unbasic.username"], session["rack-unbasic.password"])
    end

    def send_http_authorization(username, password)
      return nil unless @env["HTTP_AUTHORIZATION"].nil?
      @username, @password = username, password
      encoded_login = ["#{username}:#{password}"].pack("m*")
      @env["HTTP_AUTHORIZATION"] = "Basic #{encoded_login}"
    end

    def store_credentials
      return if @username.nil? || @password.nil?
      session["rack-unbasic.username"] = @username
      session["rack-unbasic.password"] = @password
    end

    def status_code
      @response[0].to_i
    end

    def request
      @request ||= Rack::Request.new(@env)
    end

    def session
      @env["rack.session"]
    end
  end
end
