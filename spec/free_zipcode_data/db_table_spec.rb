# frozen_string_literal: true

require 'free_zipcode_data/db_table'

RSpec.describe FreeZipcodeData::DbTable do
  let(:db) { create_test_database(line_count: 5) }

  # DbTable is abstract - we need a concrete subclass to test it
  let(:concrete_class) do
    Class.new(described_class) do
      def build; end
    end
  end

  let(:table) { concrete_class.new(database: db, tablename: 'test_table') }

  describe '#initialize' do
    it 'stores the database and tablename' do
      expect(table.database).to eq(db)
      expect(table.tablename).to eq('test_table')
    end
  end

  describe '#update_progress' do
    it 'increments the progress bar without error' do
      expect { table.update_progress }.not_to raise_error
    end
  end

  describe 'private #escape_single_quotes' do
    it 'escapes single quotes for SQL safety' do
      result = table.send(:escape_single_quotes, "O'Brien")
      expect(result).to eq("O''Brien")
    end

    it 'handles nil gracefully' do
      result = table.send(:escape_single_quotes, nil)
      expect(result).to eq('')
    end

    it 'handles strings without quotes' do
      result = table.send(:escape_single_quotes, 'Chicago')
      expect(result).to eq('Chicago')
    end
  end

  describe 'private #country_lookup_table' do
    it 'loads the YAML lookup table' do
      lookup = table.send(:country_lookup_table)
      expect(lookup).to be_a(Hash)
      expect(lookup['US'][:name]).to eq('United States of America')
    end
  end

  describe 'private #select_first' do
    it 'returns the first column of the first row' do
      result = table.send(:select_first, "SELECT value FROM meta WHERE name = 'line_count'")
      expect(result).to eq('5')
    end

    it 'returns nil when no rows match' do
      result = table.send(:select_first, "SELECT value FROM meta WHERE name = 'nonexistent'")
      expect(result).to be_nil
    end

    it 'raises with issue URL on SQL error' do
      expect do
        table.send(:select_first, 'SELECT * FROM nonexistent_table')
      end.to raise_error(/Please file an issue/)
    end
  end

  context 'with seeded countries and states' do
    before do
      seed_countries(db)
      seed_states(db)
    end

    describe 'private #get_country_id' do
      it 'returns the country ID for a known alpha2 code' do
        id = table.send(:get_country_id, 'US')
        expect(id).to be_a(Integer)
      end

      it 'returns nil for an unknown country' do
        id = table.send(:get_country_id, 'ZZ')
        expect(id).to be_nil
      end
    end

    describe 'private #get_state_id' do
      it 'finds a state by abbreviation' do
        id = table.send(:get_state_id, 'NY', 'New York')
        expect(id).to be_a(Integer)
      end

      it 'finds a state by name' do
        id = table.send(:get_state_id, 'XX', 'New York')
        expect(id).to be_a(Integer)
      end

      it 'returns nil for an unknown state' do
        id = table.send(:get_state_id, 'ZZ', 'Nonexistent')
        expect(id).to be_nil
      end
    end
  end

  context 'with seeded counties' do
    before do
      seed_countries(db)
      seed_states(db)
      seed_counties(db)
    end

    describe 'private #get_county_id' do
      it 'returns the county ID for a known county name' do
        id = table.send(:get_county_id, 'Cook')
        expect(id).to be_a(Integer)
      end

      it 'returns nil for nil county' do
        id = table.send(:get_county_id, nil)
        expect(id).to be_nil
      end

      it 'returns nil for an unknown county' do
        id = table.send(:get_county_id, 'Nonexistent County')
        expect(id).to be_nil
      end
    end
  end
end
