# frozen_string_literal: true

require 'free_zipcode_data/runner'

RSpec.describe FreeZipcodeData::Runner do
  let(:work_dir) { Dir.mktmpdir('runner_test') }
  let(:fixture_zip) { File.join(FreeZipcodeData.root, 'spec', 'fixtures', 'US.zip') }
  let(:string_io) { StringIO.new }

  after do
    FileUtils.rm_rf(work_dir)
  end

  describe '.instance' do
    it 'returns a Runner instance' do
      expect(described_class.instance).to be_a(described_class)
    end
  end

  describe '#initialize' do
    it 'sets up a logger' do
      runner = described_class.new
      expect(runner.logger).to eq(FreeZipcodeData::Logger.instance)
    end
  end

  describe '#start' do
    let(:runner) { described_class.new }

    before do
      # Suppress logger output
      runner.logger.log_provider = ::Logger.new(string_io)

      # Copy fixture zip and pre-extracted text into work_dir
      fixture_dir = File.join(FreeZipcodeData.root, 'spec', 'fixtures')
      FileUtils.mkdir_p(work_dir)
      FileUtils.cp(File.join(fixture_dir, 'US.zip'), File.join(work_dir, 'US.zip'))
      FileUtils.cp(File.join(fixture_dir, 'US.txt'), File.join(work_dir, 'US.txt'))

      # Stub ARGV to provide required CLI args
      stub_const('ARGV', [
        '--work-dir', work_dir,
        '--country', 'US',
        '--generate-files'
      ])
    end

    it 'creates an SQLite database in the work directory' do
      runner.start
      expect(File.exist?(File.join(work_dir, 'free_zipcode_data.sqlite3'))).to be true
    end

    it 'generates CSV files when --generate-files is specified' do
      runner.start
      %w[countries states counties zipcodes].each do |table|
        expect(File.exist?(File.join(work_dir, "#{table}.csv"))).to be true
      end
    end

    it 'populates the SQLite database with data' do
      runner.start
      db = SQLite3::Database.new(File.join(work_dir, 'free_zipcode_data.sqlite3'))
      country_count = db.execute('SELECT COUNT(*) FROM countries')[0][0]
      zipcode_count = db.execute('SELECT COUNT(*) FROM zipcodes')[0][0]
      expect(country_count).to be >= 1
      expect(zipcode_count).to be >= 1
      db.close
    end

    it 'sets the options on the runner' do
      runner.start
      expect(runner.options).not_to be_nil
      expect(runner.options[:work_dir]).to eq(work_dir)
    end

    context 'without --generate-files' do
      before do
        stub_const('ARGV', [
          '--work-dir', work_dir,
          '--country', 'US'
        ])
      end

      it 'creates the database but not CSV files' do
        runner.start
        expect(File.exist?(File.join(work_dir, 'free_zipcode_data.sqlite3'))).to be true
        expect(File.exist?(File.join(work_dir, 'countries.csv'))).to be false
      end
    end
  end
end
