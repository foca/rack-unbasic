ENV["RACK_ENV"] ||= "test"

require "test/unit"
require "rack/test"
require "contest"
require File.dirname(__FILE__) + "/../lib/rack/unbasic"

class TestUnbasic < Test::Unit::TestCase
  include Rack::Test::Methods

  def unbasic_app(&unbasic)
    Rack::Builder.new {
      use Rack::Session::Cookie
      use Rack::Unbasic, &unbasic

      app = lambda { [200, {}, "Hi there"] }

      map "/login" do
        run app
      end

      map "/" do
        use Rack::Auth::Basic do |user, password|
          user == "johndoe" && password == "secret"
        end
        run app
      end
    }
  end

  def app
    @app ||= unbasic_app do |on|
      on.unauthorized "/login"
      on.bad_request  "/login"
    end
  end

  context "Without providing authorization" do
    test "it redirects to the specified location" do
      get "/foobar"
      follow_redirect!
      assert_equal "http://example.org/login", last_request.url
    end

    test "it saves the previous url and code in env['rack-unbasic.*']" do
      get "/foobar"
      follow_redirect!
      assert_equal "/foobar", last_request.env["rack-unbasic.return-to"]
      assert_equal 401, last_request.env["rack-unbasic.code"]
    end
  end

  context "When providing a broken authorization (or at least not HTTP Basic" do
    test "it redirects to the specified location" do
      get "/foobar", {}, { "HTTP_AUTHORIZATION" => "cuack" }
      follow_redirect!
      assert_equal "http://example.org/login", last_request.url
    end

    test "it saves the previous url and code in env['rack-unbasic.*']" do
      get "/foobar", {}, { "HTTP_AUTHORIZATION" => "cuack" }
      follow_redirect!
      assert_equal "/foobar", last_request.env["rack-unbasic.return-to"]
      assert_equal 400, last_request.env["rack-unbasic.code"]
    end
  end

  context "Providing HTTP Basic authorization" do
    test "it works transparently" do
      authorize "johndoe", "secret"
      get "/foobar"
      assert_equal 200, last_response.status
      assert_equal "Hi there", last_response.body
    end
  end

  context "Passing the credentials as parameters" do
    test "should work as if using HTTP Basic" do
      get "/foobar", :username => "johndoe", :password => "secret"
      assert last_response.ok?
      assert_equal "Hi there", last_response.body
    end

    test "should work for subsequent requests" do
      get "/foobar", :username => "johndoe", :password => "secret"
      assert last_response.ok?

      get "/baz"
      assert last_response.ok?

      get "/quux"
      assert last_response.ok?
    end
  end

  context "When unbasic isn't set to handle 401 or 400 responses" do
    def app
      @app ||= unbasic_app
    end

    test "it doesn't interfere with pages that don't require auth" do
      get "/login"
      assert last_response.ok?
    end

    test "it returns the original 401 if credentials aren't given" do
      get "/foobar"
      assert_equal 401, last_response.status
    end

    test "it returns the original 400 if credentials are malformed" do
      get "/foobar", {}, { "HTTP_AUTHORIZATION" => "cuack" }
      assert_equal 400, last_response.status
    end
  end
end
