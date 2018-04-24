# frozen_string_literal: true

require 'singleton'
require 'logger'

module FreeZipcodeData
  class Logger
    include Singleton

    attr_accessor :log_provider

    def initialize(provider = default_logger)
      @log_provider = provider
    end

    def log_exception(e, data = {})
      msg = "EXCEPTION : #{e.class.name} : #{e.message}"
      msg += "\n data : #{data.inspect}" if data && !data.empty?
      msg += "\n  #{e.backtrace[0, 6].join("\n  ")}"
      log_provider.error(msg)
    end

    def method_missing(meth, *args, &block)
      if log_provider.respond_to?(meth)
        log_provider.send(meth, *args, &block)
      else
        super
      end
    end

    def respond_to?(meth, include_private = false)
      if log_provider.respond_to?(meth)
        true
      else
        super
      end
    end

    def verbose(msg)
      info(msg) if options&.verbose
    end

    private

    def default_logger
      logger = ::Logger.new(STDOUT)
      logger.formatter = proc do |_, _, _, msg|
        "#{msg}\n"
      end
      logger
    end

    def options
      Options.instance.hash
    end
  end
end
