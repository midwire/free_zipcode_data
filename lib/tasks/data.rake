require 'rubygems'
require 'sqlite3'
require 'csv'
require 'open-uri'
require 'zip'
require 'yaml'

# rubocop:disable Metrics/BlockLength
namespace :data do

  desc 'Download the specified data from GeoNames'
  task :download, [:country] do |_t, args|
    BASE_URL = 'http://download.geonames.org/export/zip'.freeze

    # create the download directory
    FileUtils.mkdir_p(data_dir)

    # determine which file to get
    zipfile = country_zipfile(args[:country])
    puts(">>> Downloading: #{zipfile} from GeoNames...")

    # download the file
    open("#{data_dir}/#{zipfile}", 'wb') do |file|
      file << open("#{BASE_URL}/#{zipfile}").read
    end
  end

  # desc 'Delete the sqlite db'
  task :kill_db do
    FileUtils.rm_f('free_zipcode_data.sqlite3')
  end

  desc 'Build the data files. Downloads missing files.'
  task :build, [:country] do |_t, args|
    # create the build directory
    FileUtils.mkdir_p(build_dir)

    # determine the zipfile path
    zipfile = File.join(data_dir, country_zipfile(args[:country]))

    # download the zipfile if it doesn't exist
    Rake::Task['data:download'].invoke(args[:country]) unless File.exist?(zipfile)

    # extract the .tsv files
    puts('>>> Extracting zipfile...')
    Zip.on_exists_proc = true
    country_file = nil
    Zip::File.open(zipfile) do |zip|
      zip.each do |entry|
        next if entry.name =~ /readme/i
        country_file = File.join(build_dir, entry.name)
        entry.extract(country_file)
        break
      end
    end

    # country code       0: iso country code, 2 characters
    # postal code        1: varchar(20)
    # place name         2: varchar(180)
    # admin name1        3: 1. order subdivision (state) varchar(100)
    # admin code1        4: 1. order subdivision (state) varchar(20)
    # admin name2        5: 2. order subdivision (county/province) varchar(100)
    # admin code2        6: 2. order subdivision (county/province) varchar(20)
    # admin name3        7: 3. order subdivision (community) varchar(100)
    # admin code3        8: 3. order subdivision (community) varchar(20)
    # latitude           9: estimated latitude (wgs84)
    # longitude         10: estimated longitude (wgs84)
    # accuracy          11: accuracy of lat/lng from 1=estimated to 6=centroid

    puts('>>> Writing CSV file...')
    CSV.open(output_file(args[:country]), 'w') do |outfile|
      # write the header
      outfile << %w[COUNTRY POSTAL_CODE CITY STATE SHORT_STATE COUNTY SHORT_COUNTY COMMUNITY SHORT_COMMUNITY LATITUDE LONGITUDE ACCURACY]
      CSV.foreach(country_file, headers: false, col_sep: "\t", quote_char: '|') do |row|
        outfile << row
      end
    end

    # delete the extracted file
    FileUtils.rm(country_file)

    # build sqlite db
    FileUtils.rm_f 'free_zipcode_data.sqlite3'
  end

  # desc 'Create countries table'
  task create_countries_table: :kill_db do
    schema = <<-SQL
CREATE TABLE countries (
  id INTEGER NOT NULL PRIMARY KEY,
  alpha2 VARCHAR(2) NOT NULL,
  alpha3 VARCHAR(3),
  iso VARCHAR(3),
  name VARCHAR(255) NOT NULL
)
SQL
    database.execute_batch(schema)
    ndx = <<-SQL
CREATE UNIQUE INDEX main.unique_country_alpha2
ON countries (alpha2 COLLATE NOCASE ASC);
SQL
    database.execute_batch(ndx)
  end

  # desc 'Create states table'
  task create_states_table: :create_countries_table do
    schema = <<-SQL
CREATE TABLE states (
  id INTEGER NOT NULL PRIMARY KEY,
  country_id INTEGER NOT NULL,
  abbr VARCHAR(2) NOT NULL,
  name VARCHAR(255)
)
SQL
    database.execute_batch(schema)
    ndx = <<-SQL
CREATE UNIQUE INDEX main.unique_state
ON states (abbr, country_id COLLATE NOCASE ASC);
SQL
    database.execute_batch(ndx)
  end

  # desc 'Create counties table'
  task create_counties_table: :create_states_table do
    schema = <<-SQL
CREATE TABLE counties (
  id INTEGER NOT NULL PRIMARY KEY,
  state_id INTEGER,
  abbr VARCHAR(255),
  name VARCHAR(255),
  county_seat VARCHAR(255)
)
SQL
    database.execute_batch(schema)
  end

  # desc 'Create zipcodes table'
  task create_zipcodes_table: :create_counties_table do
    schema = <<-SQL
CREATE TABLE zipcodes (
  id INTEGER NOT NULL PRIMARY KEY,
  code VARCHAR(10) NOT NULL,
  state_id INTEGER,
  county_id INTEGER,
  city VARCHAR(255),
  area_code VARCHAR(3),
  lat FLOAT,
  lon FLOAT,
  accuracy VARCHAR(8)
)
SQL
    database.execute_batch(schema)
    ndx = <<-SQL
CREATE UNIQUE INDEX main.unique_zipcode
ON zipcodes (state_id, code, city COLLATE NOCASE ASC);
SQL
    database.execute_batch(ndx)
  end

  desc 'Populate an sqlite DB'
  task :populate_db, [:country] => [:create_zipcodes_table] do |_t, args|
    start_time = Time.now
    puts '>>> Building SQLite3 DB...'

    csvfile = output_file(args[:country])

    # run the build task if the data is missing for the passed country
    Rake::Task['data:build'].invoke(args[:country]) unless File.exist?(csvfile)

    last_country = nil
    count = 0

    # Countries
    CSV.foreach(csvfile, headers: true) do |row|
      country_hash = country_lookup_table[row['COUNTRY']]
      puts(">>> #{country_hash[:name]}") if last_country != country_hash[:name]
      last_country = country_hash[:name]
      puts(">>> COUNT: #{count}") if (count % 10000).zero?
      count += 1

      # insert country
      sql = <<-SQL
INSERT INTO countries (alpha2, alpha3, iso, name)
VALUES ('#{row['COUNTRY']}',
  '#{country_hash[:alpha3]}',
  '#{country_hash[:iso]}',
  '#{country_hash[:name]}')
SQL
      begin
        database.execute(sql)
      rescue SQLite3::ConstraintException
        # next
      end

      # state
      if row['STATE']
        country_id = get_country_id(row['COUNTRY'])
        sql = <<-SQL
INSERT INTO states (abbr, name, country_id)
VALUES ('#{row['SHORT_STATE']}',
  '#{escape_single_quotes(row['STATE'])}',
  #{country_id}
)
SQL
        begin
          database.execute(sql)
        rescue StandardError => err
          # next
        end
      end

      # county
      if row['COUNTY']
        state_id = get_state_id(row['SHORT_STATE'])
        sql = <<-SQL
INSERT INTO counties (state_id, abbr, name)
VALUES ('#{state_id}',
  '#{row['SHORT_COUNTY']}',
  '#{escape_single_quotes(row['COUNTY'])}'
)
SQL
        begin
          database.execute(sql)
        rescue StandardError => err
          raise "Please file an issue at https://github.com/midwire/free_zipcode_data/issues/new: [#{err}] -> SQL: [#{sql}]"
        end
      end

      # zipcode
      if row['POSTAL_CODE']
        state_id = get_state_id(row['SHORT_STATE'])
        county_id = get_county_id(row['COUNTY'])
        city_name = escape_single_quotes(row['CITY'])
        sql = <<-SQL
INSERT INTO zipcodes (code, state_id, county_id, city, lat, lon, accuracy)
VALUES ('#{row['POSTAL_CODE']}',
  '#{state_id}',
  '#{county_id}',
  '#{city_name}',
  '#{row['LATITUDE']}',
  '#{row['LONGITUDE']}',
  '#{row['ACCURACY']}'
)
SQL
        begin
          database.execute(sql)
        rescue SQLite3::ConstraintException => err
          # there are some duplicates
        rescue StandardError => err
          raise "Please file an issue at https://github.com/midwire/free_zipcode_data/issues/new: [#{err}] -> SQL: [#{sql}]"
        end
      else
        puts(">>> Missing Postal Code: #{row}")
      end
    end

    end_time = Time.now - start_time
    puts ">>>> Completed in #{end_time} seconds"
  end

  private

  def database
    @db ||= SQLite3::Database.new('free_zipcode_data.sqlite3')
  end

  def get_country_id(country)
    rows = database.execute("SELECT id FROM countries WHERE alpha2 = '#{country}'")
    rows[0].nil? ? nil : rows[0].first
  end

  def get_state_id(state)
    rows = database.execute("SELECT id FROM states WHERE abbr = '#{state}'")
    rows[0].nil? ? nil : rows[0].first
  end

  def get_county_id(county)
    return nil if county.nil?
    sql = "SELECT id FROM counties WHERE name = '#{escape_single_quotes(county)}'"
    rows = database.execute(sql)
    rows[0].nil? ? nil : rows[0].first
  rescue SQLite3::SQLException => err
    raise "Please file an issue at https://github.com/midwire/free_zipcode_data/issues/new: [#{err}] -> SQL: [#{sql}]"
  end

  def escape_single_quotes(string)
    string.gsub(/[']/, '\'\'')
  end

  def root
    Pathname.new(File.dirname(__FILE__)).parent.parent
  end

  def data_dir
    File.join(root, 'data')
  end

  def build_dir
    File.join(root, 'build')
  end

  def country_zipfile(country)
    filename = country.nil? ? 'allCountries' : country.upcase
    filename += '.zip' unless filename =~ /\.zip$/
    filename
  end

  def country_csvfile(country)
    filename = country.nil? ? 'all_countries' : country.downcase
    filename += '.csv' unless filename =~ /\.csv$/
    filename
  end

  def output_file(country)
    filename = country.nil? ? 'all_countries.csv' : "#{country.downcase}.csv"
    File.join(build_dir, filename)
  end

  def country_lookup_table
    @country_lookup_table ||= YAML.load_file('country_lookup_table.yml')
  end
end
# rubocop:enable Metrics/BlockLength
