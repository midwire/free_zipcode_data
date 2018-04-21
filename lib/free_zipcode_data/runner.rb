# frozen_string_literal: true

require 'colored'
require 'trollop'
require 'kiba'

require_relative '../etl/free_zipcode_data_job'

require 'pry' if ENV.fetch('APP_ENV') == 'development'

module FreeZipcodeData
  class Runner
    attr_accessor :logger, :options

    # Make a singleton but allow the class to be instantiated for easier testing
    def self.instance
      @instance || new
    end

    def initialize
      @logger = Logger.instance
    end

    def start
      start_time = Time.now
      options = FreeZipcodeData::Options.instance
      options.initialize_hash(collect_args)

      logger.info('Starting FreeZipcodeData...'.green)

      datasource = DataSource.new(options.hash.country)
      datasource.download

      database = SqliteRam.new(File.join(options.hash.work_dir, 'free_zipcode_data.sqlite3'))

      %i[country state county zipcode].each { |t| initialize_table(t, database) }

      extract_transform_load(datasource, database)

      database.save_to_disk

      elapsed = Time.now - start_time
      logger.info("Finished in [#{elapsed}] seconds.".yellow)
    end

    private

    def initialize_table(table_sym, database)
      options = Options.instance.hash
      tablename = options["#{table_sym}_tablename".to_sym]
      logger.verbose("Initializing #{table_sym} table: '#{tablename}'...")
      klass = instance_eval("#{titleize(table_sym)}Table", __FILE__, __LINE__)
      table = klass.new(
        database: database.conn,
        tablename: tablename
      )
      table.build
    end

    def extract_transform_load(datasource, database)
      job = ETL::FreeZipcodeDataJob.setup(
        datasource.datafile,
        database.conn,
        logger,
        FreeZipcodeData::Options.instance.hash
      )
      Kiba.run(job)
    end

    # rubocop:disable Metrics/BlockLength
    # rubocop:disable Metrics/MethodLength
    def collect_args
      Trollop.options do
        opt(
          :country,
          'Specify the country code for processing, or all countries if not specified',
          type: :string, required: false, short: '-g'
        )
        opt(
          :work_dir,
          'Specify your work/build directory, where the SQLite and .csv files will be built',
          type: :string, required: true, short: '-w'
        )
        opt(
          :country_tablename,
          'Specify the name for the `countries` table',
          type: :string, required: false, default: 'countries'
        )
        opt(
          :state_tablename,
          'Specify the name for the `states` table',
          type: :string, required: false, default: 'states'
        )
        opt(
          :county_tablename,
          'Specify the name for the `counties` table',
          type: :string, required: false, default: 'counties'
        )
        opt(
          :zipcode_tablename,
          'Specify the name for the `zipcodes` table',
          type: :string, required: false, default: 'zipcodes'
        )
        opt(
          :clobber,
          'Overwrite existing files',
          type: :boolean, required: false, short: '-c', default: false
        )
        opt(
          :dry_run,
          'Do not actually move or copy files',
          type: :boolean, required: false, short: '-d',
          default: false
        )
        opt(
          :verbose,
          'Be verbose with output',
          type: :boolean, required: false, short: '-v',
          default: false
        )
      end
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/BlockLength

    def titleize(string)
      ret = string.to_s.dup
      ret[0] = ret[0].capitalize
      ret
    end
  end
end
