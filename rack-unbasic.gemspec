Gem::Specification.new do |s|
  s.name    = "rack-unbasic"
  s.version = "0.1"
  s.date    = "2009-05-23"

  s.description = "Elegant workflow for Rack::Auth::Basic"
  s.summary     = "Handle HTTP auth errors nicely, and abstract auth logic a little bit."
  s.homepage    = "http://github.com/foca"

  s.authors = ["Pat Nakajima", "Nicolás Sanguinetti"]
  s.email   = "contacto@nicolassanguinetti.info"

  s.require_paths     = ["lib"]
  s.rubyforge_project = "rack-unbasic"
  s.has_rdoc          = true
  s.rubygems_version  = "1.3.1"

  s.add_dependency "rack"

  if s.respond_to?(:add_development_dependency)
    s.add_development_dependency "sr-mg"
    s.add_development_dependency "contest"
  end

  s.files = %w[
    .gitignore
    LICENSE
    README.rdoc
    Rakefile
    rack-unbasic.gemspec
    lib/rack/unbasic.rb
    test/test_unbasic.rb
  ]
end
