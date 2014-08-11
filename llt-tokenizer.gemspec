# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'llt/tokenizer/version'

Gem::Specification.new do |spec|
  spec.name          = "llt-tokenizer"
  spec.version       = LLT::Tokenizer::VERSION
  spec.authors       = ["LFDM"]
  spec.email         = ["1986gh@gmail.com"]
  spec.description   = %q{LLT's Tokenizer}
  spec.summary       = %q{Breaks latin sentences into tokens}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "2.14"
  spec.add_development_dependency "simplecov", "~> 0.7"
  spec.add_dependency "array_scanner"
  spec.add_dependency "llt-core"
  spec.add_dependency "llt-core_extensions"
  spec.add_dependency "llt-db_handler"
  spec.add_dependency "llt-helpers"
end
