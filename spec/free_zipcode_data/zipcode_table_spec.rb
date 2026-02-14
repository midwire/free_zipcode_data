# frozen_string_literal: true

require 'free_zipcode_data/zipcode_table'

RSpec.describe FreeZipcodeData::ZipcodeTable do
  let(:db) { create_test_database(line_count: 5) }
  let(:table) { described_class.new(database: db, tablename: 'zipcodes') }

  before do
    seed_countries(db)
    seed_states(db)
    table.build
  end

  describe '#build' do
    it 'creates the zipcodes table' do
      tables = db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='zipcodes'")
      expect(tables.length).to eq(1)
    end

    it 'creates the unique_zipcode index' do
      indexes = db.execute("SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='zipcodes'")
      index_names = indexes.map(&:first)
      expect(index_names).to include('unique_zipcode')
    end

    it 'creates columns for code, state_id, city, area_code, lat, lon, accuracy' do
      columns = db.execute("PRAGMA table_info('zipcodes')").map { |c| c[1] }
      expect(columns).to include('code', 'state_id', 'city', 'area_code', 'lat', 'lon', 'accuracy')
    end
  end

  describe '#write' do
    let(:row) do
      {
        postal_code: '60601',
        short_state: 'IL',
        state: 'Illinois',
        city: 'Chicago',
        latitude: '41.8819',
        longitude: '-87.6278',
        accuracy: '4'
      }
    end

    it 'inserts a zipcode row' do
      table.write(row)
      rows = db.execute('SELECT code, city FROM zipcodes')
      expect(rows.length).to eq(1)
      expect(rows[0]).to eq(%w[60601 Chicago])
    end

    it 'stores latitude and longitude' do
      table.write(row)
      rows = db.execute('SELECT lat, lon FROM zipcodes')
      expect(rows[0][0].to_s).to start_with('41.88')
      expect(rows[0][1].to_s).to start_with('-87.62')
    end

    it 'links the zipcode to its state' do
      table.write(row)
      state_id = db.execute("SELECT id FROM states WHERE abbr = 'IL'")[0][0]
      zipcode_state_id = db.execute('SELECT state_id FROM zipcodes')[0][0]
      expect(zipcode_state_id.to_i).to eq(state_id)
    end

    it 'returns nil and skips when postal_code is nil' do
      result = table.write(row.merge(postal_code: nil))
      expect(result).to be_nil
      rows = db.execute('SELECT COUNT(*) FROM zipcodes')
      expect(rows[0][0]).to eq(0)
    end

    it 'silently ignores duplicate zipcode entries' do
      table.write(row)
      expect { table.write(row) }.not_to raise_error
      rows = db.execute('SELECT COUNT(*) FROM zipcodes')
      expect(rows[0][0]).to eq(1)
    end

    it 'handles city names with single quotes' do
      table.write(row.merge(city: "Coeur d'Alene", postal_code: '83814'))
      rows = db.execute('SELECT city FROM zipcodes')
      expect(rows[0][0]).to eq("Coeur d'Alene")
    end

    it 'inserts multiple different zipcodes' do
      table.write(row)
      table.write(row.merge(postal_code: '10001', city: 'New York', short_state: 'NY', state: 'New York'))
      rows = db.execute('SELECT COUNT(*) FROM zipcodes')
      expect(rows[0][0]).to eq(2)
    end
  end
end
