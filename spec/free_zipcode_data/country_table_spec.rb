# frozen_string_literal: true

require 'free_zipcode_data/country_table'

RSpec.describe FreeZipcodeData::CountryTable do
  let(:db) { create_test_database(line_count: 5) }
  let(:table) { described_class.new(database: db, tablename: 'countries') }

  before { table.build }

  describe '#build' do
    it 'creates the countries table' do
      tables = db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='countries'")
      expect(tables.length).to eq(1)
    end

    it 'creates the unique alpha2 index' do
      indexes = db.execute("SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='countries'")
      index_names = indexes.map(&:first)
      expect(index_names).to include('unique_country_alpha2')
    end

    it 'creates columns for alpha2, alpha3, iso, and name' do
      columns = db.execute("PRAGMA table_info('countries')").map { |c| c[1] }
      expect(columns).to include('alpha2', 'alpha3', 'iso', 'name')
    end
  end

  describe '#write' do
    it 'inserts a country row using the lookup table' do
      table.write({ country: 'US' })
      rows = db.execute('SELECT alpha2, alpha3, name FROM countries')
      expect(rows.length).to eq(1)
      expect(rows[0]).to eq(['US', 'USA', 'United States of America'])
    end

    it 'inserts multiple different countries' do
      table.write({ country: 'US' })
      table.write({ country: 'CA' })
      table.write({ country: 'GB' })
      rows = db.execute('SELECT alpha2 FROM countries ORDER BY alpha2')
      expect(rows.flatten).to eq(%w[CA GB US])
    end

    it 'silently ignores duplicate country codes' do
      table.write({ country: 'US' })
      expect { table.write({ country: 'US' }) }.not_to raise_error
      rows = db.execute('SELECT COUNT(*) FROM countries')
      expect(rows[0][0]).to eq(1)
    end
  end
end
