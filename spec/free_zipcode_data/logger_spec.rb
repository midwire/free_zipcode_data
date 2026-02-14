# frozen_string_literal: true

RSpec.describe FreeZipcodeData::Logger do
  let(:logger) { described_class.instance }
  let(:string_io) { StringIO.new }
  let(:test_provider) { ::Logger.new(string_io) }

  before do
    logger.log_provider = test_provider
  end

  after do
    # Restore default logger
    logger.log_provider = ::Logger.new($stdout)
  end

  describe '#info' do
    it 'delegates to the log provider' do
      logger.info('test message')
      expect(string_io.string).to include('test message')
    end
  end

  describe '#log_exception' do
    it 'logs exception class, message, and backtrace' do
      error = begin
        raise StandardError, 'something broke'
      rescue StandardError => e
        e
      end

      logger.log_exception(error)
      output = string_io.string
      expect(output).to include('EXCEPTION')
      expect(output).to include('StandardError')
      expect(output).to include('something broke')
    end

    it 'includes data hash when provided' do
      error = begin
        raise StandardError, 'oops'
      rescue StandardError => e
        e
      end

      logger.log_exception(error, { user_id: 42 })
      expect(string_io.string).to include('user_id')
    end
  end

  describe '#verbose' do
    let(:options) { FreeZipcodeData::Options.instance }

    it 'logs when verbose option is true' do
      options.initialize_hash(OpenStruct.new(verbose: true))
      logger.verbose('verbose message')
      expect(string_io.string).to include('verbose message')
    end

    it 'does not log when verbose option is false' do
      options.initialize_hash(OpenStruct.new(verbose: false))
      logger.verbose('should not appear')
      expect(string_io.string).not_to include('should not appear')
    end
  end

  describe '#respond_to?' do
    it 'returns true for methods the log provider responds to' do
      expect(logger.respond_to?(:info)).to be true
      expect(logger.respond_to?(:warn)).to be true
      expect(logger.respond_to?(:error)).to be true
    end

    it 'returns false for unknown methods' do
      expect(logger.respond_to?(:nonexistent_method)).to be false
    end
  end
end
