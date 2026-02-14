# frozen_string_literal: true

require 'free_zipcode_data/county_table'

RSpec.describe FreeZipcodeData::CountyTable do
  let(:db) { create_test_database(line_count: 5) }
  let(:table) { described_class.new(database: db, tablename: 'counties') }

  before do
    seed_countries(db)
    seed_states(db)
    table.build
  end

  describe '#build' do
    it 'creates the counties table' do
      tables = db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='counties'")
      expect(tables.length).to eq(1)
    end

    it 'creates the unique_county index' do
      indexes = db.execute("SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='counties'")
      index_names = indexes.map(&:first)
      expect(index_names).to include('unique_county')
    end

    it 'creates columns for state_id, abbr, name, and county_seat' do
      columns = db.execute("PRAGMA table_info('counties')").map { |c| c[1] }
      expect(columns).to include('state_id', 'abbr', 'name', 'county_seat')
    end
  end

  describe '#write' do
    it 'inserts a county row' do
      table.write({ county: 'Cook', short_county: '031', short_state: 'IL', state: 'Illinois' })
      rows = db.execute('SELECT name, abbr FROM counties')
      expect(rows.length).to eq(1)
      expect(rows[0]).to eq(['Cook', '031'])
    end

    it 'links the county to its state' do
      table.write({ county: 'Cook', short_county: '031', short_state: 'IL', state: 'Illinois' })
      state_id = db.execute("SELECT id FROM states WHERE abbr = 'IL'")[0][0]
      county_state_id = db.execute('SELECT state_id FROM counties')[0][0]
      expect(county_state_id).to eq(state_id)
    end

    it 'returns nil and skips when county is nil' do
      result = table.write({ county: nil, short_county: nil, short_state: 'IL', state: 'Illinois' })
      expect(result).to be_nil
      rows = db.execute('SELECT COUNT(*) FROM counties')
      expect(rows[0][0]).to eq(0)
    end

    it 'returns nil when state cannot be found' do
      result = table.write({ county: 'Unknown', short_county: '999', short_state: 'ZZ', state: 'Nonexistent' })
      expect(result).to be_nil
      rows = db.execute('SELECT COUNT(*) FROM counties')
      expect(rows[0][0]).to eq(0)
    end

    it 'silently ignores duplicate county entries' do
      table.write({ county: 'Cook', short_county: '031', short_state: 'IL', state: 'Illinois' })
      expect {
        table.write({ county: 'Cook', short_county: '031', short_state: 'IL', state: 'Illinois' })
      }.not_to raise_error
      rows = db.execute('SELECT COUNT(*) FROM counties')
      expect(rows[0][0]).to eq(1)
    end

    it 'handles county names with single quotes' do
      table.write({ county: "Prince George's", short_county: '033', short_state: 'NY', state: 'New York' })
      rows = db.execute('SELECT name FROM counties')
      expect(rows[0][0]).to eq("Prince George's")
    end
  end
end
