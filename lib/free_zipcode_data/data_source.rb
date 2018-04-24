# frozen_string_literal: true

require 'csv'
require 'open-uri'
require 'zip'

module FreeZipcodeData
  class DataSource
    BASE_URL = 'http://download.geonames.org/export/zip'

    attr_reader :country, :options

    def initialize(country = nil)
      @country = country
      @options = Options.instance.hash
      @logger  = Logger.instance
    end

    def download
      return nil if !options.clobber && File.exist?(zipfile_path)
      FileUtils.mkdir_p(options.work_dir)
      @logger.info("Downloading: #{zipfile} from GeoNames...")
      open(zipfile_path, 'wb') do |file|
        file << open("#{BASE_URL}/#{zipfile}").read
      end
    end

    def datafile
      @datafile ||= begin
        datafile_with_headers
      end
    end

    private

    def zipfile
      @zipfile ||= begin
        filename = country.nil? ? 'allCountries' : country.upcase
        filename += '.zip' unless filename =~ /\.zip$/
        filename
      end
    end

    def zipfile_path
      @zipfile_path ||= File.join(options.work_dir, zipfile)
    end

    def unzipped_datafile
      @unzipped_datafile ||= begin
        country_file = nil
        Zip::File.open(zipfile_path) do |zip|
          zip.each do |entry|
            next if entry.name =~ /readme/i
            country_file = File.join(options.work_dir, entry.name)
            if File.exist?(country_file)
              if options[:clobber]
                Zip.on_exists_proc = true
                Logger.instance.verbose("Extracting: #{zipfile}...")
                entry.extract(country_file)
              end
            else
              Logger.instance.verbose("Extracting: #{zipfile}...")
              entry.extract(country_file)
            end
            break
          end
        end
        country_file
      end
    end

    def datafile_with_headers
      filename = "#{unzipped_datafile}.csv"
      if File.exist?(filename) && !options[:clobber]
        @logger.verbose("File: #{filename} already exists, skipping...")
        return filename
      end
      @logger.verbose("Preparing: #{filename} for processing...")
      CSV.open(filename, 'w') do |outfile|
        outfile << %w[COUNTRY POSTAL_CODE CITY STATE SHORT_STATE COUNTY SHORT_COUNTY COMMUNITY SHORT_COMMUNITY LATITUDE LONGITUDE ACCURACY]
        CSV.foreach(unzipped_datafile, headers: false, col_sep: "\t", quote_char: '|') do |row|
          outfile << row
        end
      end
      filename
    end
  end
end
