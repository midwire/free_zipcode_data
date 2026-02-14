# frozen_string_literal: true

require 'free_zipcode_data/data_source'

RSpec.describe FreeZipcodeData::DataSource do
  let(:work_dir) { Dir.mktmpdir('datasource_test') }
  let(:options) do
    OpenStruct.new(
      work_dir: work_dir,
      clobber: false,
      country: 'US',
      verbose: false
    )
  end
  let(:options_instance) { FreeZipcodeData::Options.instance }

  before do
    options_instance.initialize_hash(options)
  end

  after do
    FileUtils.rm_rf(work_dir)
  end

  describe '#initialize' do
    it 'stores the country' do
      ds = described_class.new('US')
      expect(ds.country).to eq('US')
    end

    it 'defaults country to nil' do
      ds = described_class.new
      expect(ds.country).to be_nil
    end
  end

  describe '#download' do
    let(:datasource) { described_class.new('US') }
    let(:fixture_zip) { File.read(File.join(FreeZipcodeData.root, 'spec', 'fixtures', 'US.zip')) }

    it 'downloads and saves the zip file' do
      uri_object = instance_double(URI::HTTP)
      allow(URI).to receive(:parse).and_return(uri_object)
      allow(uri_object).to receive(:open).and_yield(StringIO.new(fixture_zip))

      datasource.download

      expect(File.exist?(File.join(work_dir, 'US.zip'))).to be true
    end

    it 'skips download if the file already exists and clobber is false' do
      FileUtils.touch(File.join(work_dir, 'US.zip'))

      expect(URI).not_to receive(:parse)
      datasource.download
    end

    it 'redownloads if clobber is true' do
      FileUtils.touch(File.join(work_dir, 'US.zip'))
      options_instance.initialize_hash(OpenStruct.new(work_dir: work_dir, clobber: true, country: 'US',
                                                      verbose: false))

      uri_object = instance_double(URI::HTTP)
      allow(URI).to receive(:parse).and_return(uri_object)
      allow(uri_object).to receive(:open).and_yield(StringIO.new(fixture_zip))

      datasource.download

      expect(File.size(File.join(work_dir, 'US.zip'))).to be > 0
    end
  end

  describe '#datafile' do
    let(:datasource) { described_class.new('US') }

    before do
      fixture_dir = File.join(FreeZipcodeData.root, 'spec', 'fixtures')
      # Copy fixture zip and pre-extracted text to work_dir
      FileUtils.cp(File.join(fixture_dir, 'US.zip'), File.join(work_dir, 'US.zip'))
      FileUtils.cp(File.join(fixture_dir, 'US.txt'), File.join(work_dir, 'US.txt'))
    end

    it 'returns a CSV file path with headers prepended' do
      result = datasource.datafile
      expect(result).to end_with('.csv')
      expect(File.exist?(result)).to be true
    end

    it 'prepends headers to the extracted data' do
      result = datasource.datafile
      first_line = File.open(result, &:readline)
      expect(first_line).to include('COUNTRY')
      expect(first_line).to include('POSTAL_CODE')
      expect(first_line).to include('LATITUDE')
    end

    it 'contains the original data rows' do
      result = datasource.datafile
      lines = File.readlines(result)
      # header + 5 data rows
      expect(lines.length).to eq(6)
    end

    it 'does not re-extract if CSV already exists and clobber is false' do
      first = datasource.datafile
      mtime = File.mtime(first)
      sleep(0.1)
      # Create a new instance to avoid memoization
      ds2 = described_class.new('US')
      second = ds2.datafile
      expect(File.mtime(second)).to eq(mtime)
    end
  end

  describe 'zipfile naming' do
    it 'uses country code for single country' do
      ds = described_class.new('US')
      expect(ds.send(:zipfile)).to eq('US.zip')
    end

    it 'uppercases the country code' do
      ds = described_class.new('us')
      expect(ds.send(:zipfile)).to eq('US.zip')
    end

    it 'uses allCountries when no country specified' do
      ds = described_class.new(nil)
      expect(ds.send(:zipfile)).to eq('allCountries.zip')
    end
  end
end
