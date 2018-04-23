# frozen_string_literal: true
# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'free_zipcode_data/version'

# rubocop:disable Metrics/BlockLength
Gem::Specification.new do |spec|
  spec.name          = 'free_zipcode_data'
  spec.version       = FreeZipcodeData::VERSION
  spec.authors       = ['Chris Blackburn', 'Chris McKnight']
  spec.email         = ['87a1779b@opayq.com', 'fixme@mcknight.bogus']
  spec.summary       = 'Free US postal codes in CSV and SQLite3 format.'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/midwire/free_zipcode_data'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 2.3.0'
  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'pry-nav', '~> 0.2'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.7'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'ruby-prof'
  spec.add_development_dependency 'simplecov'

  spec.add_runtime_dependency 'colored', '~> 1.2'
  spec.add_runtime_dependency 'kiba', '~> 2.0'
  spec.add_runtime_dependency 'ruby-progressbar', '~> 1.9'
  spec.add_runtime_dependency 'rubyzip', '~> 1.2'
  spec.add_runtime_dependency 'sqlite3', '~> 1.3'
  spec.add_runtime_dependency 'trollop', '~> 2.1'
end
# rubocop:enable Metrics/BlockLength
