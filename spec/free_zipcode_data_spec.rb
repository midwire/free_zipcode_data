# frozen_string_literal: true

RSpec.describe FreeZipcodeData do
  describe '.root' do
    it 'returns a Pathname to the project root' do
      expect(described_class.root).to be_a(Pathname)
      expect(described_class.root.join('lib', 'free_zipcode_data.rb')).to exist
    end
  end

  describe '.current_environment' do
    it 'returns "test" when APP_ENV is set to test' do
      expect(described_class.current_environment).to eq('test')
    end

    it 'defaults to "development" when APP_ENV is not set' do
      allow(ENV).to receive(:fetch).with('APP_ENV', 'development').and_return('development')
      expect(described_class.current_environment).to eq('development')
    end
  end

  describe '.config_file' do
    it 'returns spec/fixtures path in test environment' do
      path = described_class.config_file
      expect(path.to_s).to include('spec/fixtures/.free_zipcode_data.yml')
    end
  end

  describe '.os' do
    it 'returns :normal on non-Windows platforms' do
      expect(described_class.os).to eq(:normal)
    end
  end

  it 'has a version number' do
    expect(FreeZipcodeData::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end
end
