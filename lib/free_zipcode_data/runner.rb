# frozen_string_literal: true

require 'colored'
require 'optimist'
require 'kiba'

require_relative '../etl/free_zipcode_data_job'

require 'pry' if ENV.fetch('APP_ENV', '') == 'development'

module FreeZipcodeData
  # rubocop:disable Metrics/ClassLength
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
      opt = FreeZipcodeData::Options.instance
      opt.initialize_hash(collect_args)
      @options = opt.hash

      logger.info("Starting FreeZipcodeData v#{VERSION}...".green)

      datasource = DataSource.new(options.country)
      datasource.download

      db_file = File.join(options.work_dir, 'free_zipcode_data.sqlite3')
      database = SqliteRam.new(db_file)

      line_count = datasource_line_count(datasource.datafile)
      configure_meta(database.conn, line_count)

      %i[country state county zipcode].each { |t| initialize_table(t, database) }

      extract_transform_load(datasource, database)

      logger.info("Saving database to disk '#{db_file}'...")
      database.save_to_disk

      if options.generate_files
        logger.info('Generating .csv files...')
        database.dump_tables(options.work_dir)
      end

      elapsed = Time.at(Time.now - start_time).utc.strftime('%H:%M:%S')
      logger.info("Processed #{line_count} zipcodes in [#{elapsed}].".yellow)
    end

    private

    def initialize_table(table_sym, database)
      tablename = options["#{table_sym}_tablename".to_sym]
      logger.verbose("Initializing #{table_sym} table: '#{tablename}'...")
      klass = instance_eval("#{titleize(table_sym)}Table", __FILE__, __LINE__)
      table = klass.new(
        database: database.conn,
        tablename: tablename
      )
      table.build
    end

    def datasource_line_count(filename)
      count = File.foreach(filename).inject(0) { |c, _line| c + 1 }
      logger.verbose("Processing #{count} zipcodes in '#{filename}'...")
      count
    end

    def configure_meta(database, line_count)
      schema = <<-SQL
        create table meta (
          id integer not null primary key,
          name varchar(255),
          value varchar(255)
        )
      SQL
      database.execute_batch(schema)

      sql = <<-SQL
        INSERT INTO meta (name, value)
        VALUES ('line_count', #{line_count})
      SQL
      database.execute(sql)
    end

    def extract_transform_load(datasource, database)
      job = ETL::FreeZipcodeDataJob.setup(
        datasource.datafile,
        database.conn,
        logger,
        options
      )
      Kiba.run(job)
    end

    # rubocop:disable Metrics/BlockLength
    # rubocop:disable Metrics/MethodLength
    def collect_args
      Optimist.options do
        opt(
          :work_dir,
          'REQUIRED: Specify your work/build directory, where the SQLite and .csv files will be built',
          type: :string, required: true, short: '-w'
        )
        opt(
          :country,
          'Specify the country code for processing, or all countries if not specified',
          type: :string, required: false, short: '-f'
        )
        opt(
          :generate_files,
          'Generate CSV files: [counties.csv, states.csv, countries.csv, zipcodes.csv]',
          type: :boolean, required: false, short: '-g', default: false
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
  # rubocop:enable Metrics/ClassLength
end
