# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'quikchat/version'

Gem::Specification.new do |spec|
  spec.name          = "quikchat"
  spec.version       = QuikChat::VERSION
  spec.authors       = ["Konstantin Gredeskoul", "Atasay Gokkaya", "Paul Henry"]
  spec.email         = ["kigster@gmail.com"]
  spec.summary       = %q{Ruby client library for connecting to quikchat-server}
  spec.description   = %q{Ruby client library for connecting to quikchat-server}
  spec.homepage      = "https://github.com/kigster/quikchat"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'httparty'

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3"
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "webmock"
end
