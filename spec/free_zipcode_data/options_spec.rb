# frozen_string_literal: true

RSpec.describe FreeZipcodeData::Options do
  let(:options) { described_class.instance }

  after do
    # Reset singleton state
    options.initialize_hash({})
  end

  describe '#initialize_hash' do
    it 'stores the given hash' do
      options.initialize_hash({ work_dir: '/tmp/claude/test', country: 'US' })
      expect(options.hash).to include(work_dir: '/tmp/claude/test', country: 'US')
    end
  end

  describe '#[]' do
    it 'returns the value for the given key' do
      options.initialize_hash({ country: 'GB' })
      expect(options[:country]).to eq('GB')
    end

    it 'returns nil for missing keys' do
      options.initialize_hash({})
      expect(options[:nonexistent]).to be_nil
    end
  end

  describe '#hash' do
    it 'returns the full options hash' do
      data = { work_dir: '/tmp/claude/test', verbose: true }
      options.initialize_hash(data)
      expect(options.hash).to eq(data)
    end
  end
end
