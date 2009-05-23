require "test/unit"
require "rack/test"
require "contest"
require File.dirname(__FILE__) + "/../lib/rack/unbasic"

class TestUnbasic < Test::Unit::TestCase
  include Rack::Test::Methods

  def unbasic_app_failing_with(code, &unbasic)
    Rack::Builder.new {
      use Rack::Session::Cookie
      use Rack::Unbasic, &unbasic
      run lambda {|env| 
        if env["PATH_INFO"] == "/login"
          [200, {}, "Please login"]
        else
          [code, {}, "Go away!"]
        end 
      }
    }
  end

  context "when the downstream app returns a 401 status code" do
    context "and Unbasic handles unauthorized requests" do
      def app
        @app ||= unbasic_app_failing_with 401 do |on|
          on.unauthorized "/login"
        end
      end

      test "it returns a 302 status code" do
        get "/foobar"
        assert_equal 302, last_response.status
      end

      test "it redirects to the specified location" do
        get "/foobar"
        follow_redirect!
        assert_equal "http://example.org/login", last_request.url
      end

      test "it saves the previous url in env['rack-unbasic.return-to']" do
        get "/foobar"
        follow_redirect!
        assert_equal "/foobar", last_request.env["rack-unbasic.return-to"]
      end
    end

    context "but Unbasic doesn't handle unauthorized requests" do
      def app
        @app ||= unbasic_app_failing_with 401
      end

      test "it just returns the original response to the user" do
        get "/foobar"
        assert_equal 401, last_response.status
        assert_equal "Go away!", last_response.body
      end
    end
  end

  context "when the downstream app returns a 400 status code" do
    context "and Unbasic handles bad requests" do
      def app
        @app ||= unbasic_app_failing_with 400 do |on|
          on.bad_request "/login"
        end
      end

      test "it returns a 302 status code" do
        get "/foobar"
        assert_equal 302, last_response.status
      end

      test "it redirects to the specified location" do
        get "/foobar"
        follow_redirect!
        assert_equal "http://example.org/login", last_request.url
      end

      test "it saves the previous url in env['rack-unbasic.return-to']" do
        get "/foobar"
        follow_redirect!
        assert_equal "/foobar", last_request.env["rack-unbasic.return-to"]
      end
    end

    context "but Unbasic doesn't handle bad requests" do
      def app
        @app ||= unbasic_app_failing_with 400
      end

      test "it just returns the original response to the user" do
        get "/foobar"
        assert_equal 400, last_response.status
        assert_equal "Go away!", last_response.body
      end
    end
  end
end
