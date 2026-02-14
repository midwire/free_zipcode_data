# frozen_string_literal: true

require 'free_zipcode_data/state_table'

RSpec.describe FreeZipcodeData::StateTable do
  let(:db) { create_test_database(line_count: 5) }
  let(:table) { described_class.new(database: db, tablename: 'states') }

  before do
    seed_countries(db)
    table.build
  end

  describe '#build' do
    it 'creates the states table' do
      tables = db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='states'")
      expect(tables.length).to eq(1)
    end

    it 'creates the unique_state index' do
      indexes = db.execute("SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='states'")
      index_names = indexes.map(&:first)
      expect(index_names).to include('unique_state')
    end

    it 'creates the state_name index' do
      indexes = db.execute("SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='states'")
      index_names = indexes.map(&:first)
      expect(index_names).to include('state_name')
    end

    it 'creates columns for country_id, abbr, and name' do
      columns = db.execute("PRAGMA table_info('states')").map { |c| c[1] }
      expect(columns).to include('country_id', 'abbr', 'name')
    end
  end

  describe '#write' do
    it 'inserts a state row' do
      table.write({ country: 'US', short_state: 'NY', state: 'New York' })
      rows = db.execute('SELECT abbr, name FROM states')
      expect(rows.length).to eq(1)
      expect(rows[0]).to eq(['NY', 'New York'])
    end

    it 'links the state to its country' do
      table.write({ country: 'US', short_state: 'NY', state: 'New York' })
      country_id = db.execute("SELECT id FROM countries WHERE alpha2 = 'US'")[0][0]
      state_country_id = db.execute('SELECT country_id FROM states')[0][0]
      expect(state_country_id).to eq(country_id)
    end

    it 'returns nil and skips when short_state is nil' do
      result = table.write({ country: 'US', short_state: nil, state: 'Unknown' })
      expect(result).to be_nil
      rows = db.execute('SELECT COUNT(*) FROM states')
      expect(rows[0][0]).to eq(0)
    end

    it 'silently ignores duplicate state entries' do
      table.write({ country: 'US', short_state: 'NY', state: 'New York' })
      expect { table.write({ country: 'US', short_state: 'NY', state: 'New York' }) }.not_to raise_error
      rows = db.execute('SELECT COUNT(*) FROM states')
      expect(rows[0][0]).to eq(1)
    end

    it 'handles the Marshall Islands edge case' do
      table.write({ country: 'US', short_state: 'MH', state: nil })
      rows = db.execute("SELECT name FROM states WHERE abbr = 'MH'")
      expect(rows[0][0]).to eq('Marshall Islands')
    end

    it 'handles state names with single quotes' do
      # Some international state names can have apostrophes
      table.write({ country: 'US', short_state: 'TX', state: "Cote d'Ivoire" })
      rows = db.execute("SELECT name FROM states WHERE abbr = 'TX'")
      expect(rows[0][0]).to eq("Cote d'Ivoire")
    end
  end
end
