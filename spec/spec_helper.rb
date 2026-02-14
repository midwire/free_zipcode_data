# frozen_string_literal: true

ENV['APP_ENV'] = 'test'

begin
  require 'pry'
rescue NameError, LoadError
  # pry may not be compatible with current Ruby version
end

require 'ostruct'
require 'free_zipcode_data'
require 'free_zipcode_data/runner'

Dir[Pathname.new(File.dirname(__FILE__)).parent.join('spec/support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.include DatabaseHelpers

  # Silence progress bar output during tests
  config.before do
    allow(ProgressBar).to receive(:create).and_wrap_original do |method, **args|
      method.call(**args, output: StringIO.new)
    end
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.filter_run_when_matching :focus

  config.example_status_persistence_file_path = 'spec/examples.txt'

  config.disable_monkey_patching!

  config.warnings = true

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.profile_examples = 3

  config.order = :random

  Kernel.srand config.seed
end
