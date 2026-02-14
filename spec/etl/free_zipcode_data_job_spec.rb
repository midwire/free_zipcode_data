# frozen_string_literal: true

require 'kiba'
require 'etl/free_zipcode_data_job'

RSpec.describe ETL::FreeZipcodeDataJob do
  let(:db) { create_test_database(line_count: 5) }
  let(:fixture_csv) { File.join(FreeZipcodeData.root, 'spec', 'fixtures', 'test_data.csv') }
  let(:logger) { FreeZipcodeData::Logger.instance }
  let(:string_io) { StringIO.new }
  let(:options) do
    OpenStruct.new(
      country_tablename: 'countries',
      state_tablename: 'states',
      county_tablename: 'counties',
      zipcode_tablename: 'zipcodes',
      verbose: false
    )
  end

  before do
    FreeZipcodeData::Options.instance.initialize_hash(options)
    logger.log_provider = Logger.new(string_io)
  end

  describe '.setup' do
    it 'returns a Kiba job definition' do
      job = described_class.setup(fixture_csv, db, logger, options)
      expect(job).not_to be_nil
    end
  end

  describe 'full ETL pipeline' do
    before do
      # Build all tables
      FreeZipcodeData::CountryTable.new(database: db, tablename: 'countries').build
      FreeZipcodeData::StateTable.new(database: db, tablename: 'states').build
      FreeZipcodeData::CountyTable.new(database: db, tablename: 'counties').build
      FreeZipcodeData::ZipcodeTable.new(database: db, tablename: 'zipcodes').build

      job = described_class.setup(fixture_csv, db, logger, options)
      Kiba.run(job)
    end

    it 'populates the countries table' do
      rows = db.execute('SELECT alpha2 FROM countries ORDER BY alpha2')
      expect(rows.flatten).to include('CA', 'GB', 'US')
    end

    it 'populates the states table' do
      rows = db.execute('SELECT abbr FROM states ORDER BY abbr')
      abbrs = rows.flatten
      expect(abbrs).to include('CA', 'IL', 'NY')
    end

    it 'populates the counties table' do
      rows = db.execute('SELECT name FROM counties ORDER BY name')
      names = rows.flatten
      expect(names).to include('Cook', 'Los Angeles', 'New York')
    end

    it 'populates the zipcodes table' do
      rows = db.execute('SELECT code FROM zipcodes ORDER BY code')
      codes = rows.flatten
      expect(codes).to include('10001', '60601', '90210')
    end

    it 'links zipcodes to states' do
      rows = db.execute(<<-SQL)
        SELECT z.code, s.abbr
        FROM zipcodes z
        JOIN states s ON CAST(z.state_id AS INTEGER) = s.id
        WHERE z.code = '60601'
      SQL
      expect(rows[0]).to eq(%w[60601 IL])
    end

    it 'links states to countries' do
      rows = db.execute(<<-SQL)
        SELECT s.abbr, c.alpha2
        FROM states s
        JOIN countries c ON s.country_id = c.id
        WHERE s.abbr = 'NY'
      SQL
      expect(rows[0]).to eq(%w[NY US])
    end

    it 'stores geocode data for zipcodes' do
      rows = db.execute("SELECT lat, lon FROM zipcodes WHERE code = '10001'")
      lat = rows[0][0].to_f
      lon = rows[0][1].to_f
      expect(lat).to be_within(0.01).of(40.7484)
      expect(lon).to be_within(0.01).of(-73.9967)
    end
  end
end
