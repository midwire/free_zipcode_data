# frozen_string_literal: true

require 'yaml'

module FreeZipcodeData
  class DbTable
    ISSUE_URL = 'https://github.com/midwire/free_zipcode_data/issues/new'

    attr_reader :database, :tablename

    def initialize(database:, tablename:)
      @database  = database
      @tablename = tablename
    end

    private

    def country_lookup_table
      @country_lookup_table ||= YAML.load_file('country_lookup_table.yml')
    end

    def get_country_id(country)
      rows = database.execute("SELECT id FROM countries WHERE alpha2 = '#{country}'")
      rows[0].nil? ? nil : rows[0].first
    end

    def get_state_id(state)
      rows = database.execute("SELECT id FROM states WHERE abbr = '#{state}'")
      rows[0].nil? ? nil : rows[0].first
    end

    def get_county_id(county)
      return nil if county.nil?
      sql = "SELECT id FROM counties WHERE name = '#{escape_single_quotes(county)}'"
      rows = database.execute(sql)
      rows[0].nil? ? nil : rows[0].first
    rescue SQLite3::SQLException => err
      raise "Please file an issue at #{ISSUE_URL}: [#{err}] -> SQL: [#{sql}]"
    end

    def escape_single_quotes(string)
      string&.gsub(/[']/, '\'\'') || ''
    end
  end
end
