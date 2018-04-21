# frozen_string_literal: true

require 'singleton'

module FreeZipcodeData
  class Options
    include Singleton

    def initialize_hash(hash)
      @@_options = hash
    end

    def [](key)
      @@_options[key]
    end

    def hash
      @@_options
    end
  end
end
