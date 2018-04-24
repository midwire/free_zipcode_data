# frozen_string_literal: true

require_relative 'common'

module ETL
  module FreeZipcodeDataJob
    module_function

    def setup(country_file, database, logger, options)
      Kiba.parse do
        pre_process do
          logger.info("Processing '#{country_file}' data, please be patient...")
        end

        source CsvSource, filename: country_file, quote_char: '"', delimeter: ','

        destination FreeZipcodeData::CountryTable,
          database: database,
          tablename: options[:country_tablename]

        destination FreeZipcodeData::StateTable,
          database: database,
          tablename: options[:state_tablename]

        destination FreeZipcodeData::CountyTable,
          database: database,
          tablename: options[:county_tablename]

        destination FreeZipcodeData::ZipcodeTable,
          database: database,
          tablename: options[:zipcode_tablename]

        post_process do
          logger.verbose('Finished generating table data...')
        end
      end
    end
  end
end
