# frozen_string_literal: true

require 'readline'

require 'free_zipcode_data/version'

module FreeZipcodeData
  def self.root
    Pathname.new(File.dirname(__FILE__)).parent
  end

  def self.current_environment
    ENV.fetch('APP_ENV', 'development')
  end

  #:nocov:
  def self.config_file(filename = '.free_zipcode_data.yml')
    return root.join('spec', 'fixtures', filename) if current_environment == 'test'
    home = ENV.fetch('HOME')
    file = ENV.fetch('FZD_CONFIG_FILE', File.join(home, '.free_zipcode_data.yml'))
    FileUtils.touch(file)
    file
  end
  #:nocov:

  def self.os
    if RUBY_PLATFORM.match?(/cygwin|mswin|mingw|bccwin|wince|emx/)
      :retarded
    else
      :normal
    end
  end

  autoload :CountryTable, 'free_zipcode_data/country_table'
  autoload :StateTable,   'free_zipcode_data/state_table'
  autoload :CountyTable,  'free_zipcode_data/county_table'
  autoload :ZipcodeTable, 'free_zipcode_data/zipcode_table'
  autoload :DataSource,   'free_zipcode_data/data_source'
  autoload :Logger,       'free_zipcode_data/logger'
  autoload :Options,      'free_zipcode_data/options'
  autoload :Settings,     'free_zipcode_data/settings'
  autoload :SqliteRam,    'free_zipcode_data/sqlite_ram'
end
