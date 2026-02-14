# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'free_zipcode_data/version'

Gem::Specification.new do |spec|
  spec.metadata = { 'rubygems_mfa_required' => 'true' }
  spec.name          = 'free_zipcode_data'
  spec.version       = FreeZipcodeData::VERSION
  spec.authors       = ['Chris Blackburn', 'Chris McKnight']
  spec.email         = ['87a1779b@opayq.com', 'fixme@mcknight.bogus']
  spec.summary       = 'Free US and world-wide postal codes in SQLite and CSV format'
  spec.description   = <<~STRING
    Free US and world-wide postal codes in SQLite and CSV format.
    Automated zipcode/postal code aggregation and processing for any needs.
  STRING
  spec.homepage      = 'https://github.com/midwire/free_zipcode_data'
  spec.license       = 'MIT'

  spec.required_ruby_version = Gem::Requirement.new(">= #{Bundler.root.join('.ruby-version').read.strip}")
  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'colored', '~> 1.2'
  spec.add_dependency 'csv'
  spec.add_dependency 'kiba', '~> 4.0'
  spec.add_dependency 'logger'
  spec.add_dependency 'optimist', '~> 3.0'
  spec.add_dependency 'ruby-progressbar', '~> 1.9'
  spec.add_dependency 'rubyzip', '>= 1.2.2'
  spec.add_dependency 'sqlite3', '~> 1.3'
end
