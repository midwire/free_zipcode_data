# frozen_string_literal: true

require 'etl/csv_source'

RSpec.describe CsvSource do
  let(:fixture_csv) { File.join(FreeZipcodeData.root, 'spec', 'fixtures', 'test_data.csv') }

  describe '#initialize' do
    it 'stores the filename and options' do
      source = described_class.new(filename: fixture_csv)
      expect(source.filename).to eq(fixture_csv)
      expect(source.headers).to be true
      expect(source.delimeter).to eq("\t")
    end

    it 'accepts custom delimiter and quote char' do
      source = described_class.new(filename: fixture_csv, delimeter: ',', quote_char: '"')
      expect(source.delimeter).to eq(',')
      expect(source.quote_char).to eq('"')
    end
  end

  describe '#each' do
    it 'yields each row as a hash with symbolized keys' do
      source = described_class.new(filename: fixture_csv, delimeter: ',', quote_char: '"')
      rows = []
      source.each { |row| rows << row }

      expect(rows.length).to eq(5)
      expect(rows.first).to be_a(Hash)
      expect(rows.first.keys).to include(:country, :postal_code, :city)
    end

    it 'parses the correct data from each row' do
      source = described_class.new(filename: fixture_csv, delimeter: ',', quote_char: '"')
      rows = []
      source.each { |row| rows << row }

      first = rows.first
      expect(first[:country]).to eq('US')
      expect(first[:postal_code]).to eq('10001')
      expect(first[:city]).to eq('New York')
      expect(first[:short_state]).to eq('NY')
    end

    it 'handles rows from multiple countries' do
      source = described_class.new(filename: fixture_csv, delimeter: ',', quote_char: '"')
      countries = []
      source.each { |row| countries << row[:country] }

      expect(countries.uniq.sort).to eq(%w[CA GB US])
    end
  end
end
