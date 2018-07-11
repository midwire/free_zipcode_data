# frozen_string_literal: true

require 'yaml'
require 'ruby-progressbar'

module FreeZipcodeData
  class DbTable
    ISSUE_URL = 'https://github.com/midwire/free_zipcode_data/issues/new'

    attr_reader :database, :tablename
    @@progressbar = nil

    def initialize(database:, tablename:)
      @database  = database
      @tablename = tablename
      lc = select_first('SELECT value FROM meta where name = "line_count"')
      @@progressbar = ProgressBar.create(total: lc.to_i * 4, format: '%t: |%B| %e')
    end

    def update_progress
      @@progressbar.increment
    end

    private

    def country_lookup_table
      @country_lookup_table ||=
        begin
          path = File.expand_path('../../country_lookup_table.yml', __dir__)
          YAML.load_file(path)
        end
    end

    def select_first(sql)
      rows = database.execute(sql)
      rows[0].nil? ? nil : rows[0].first
    rescue SQLite3::SQLException => err
      raise "Please file an issue at #{ISSUE_URL}: [#{err}] -> SQL: [#{sql}]"
    end

    def get_country_id(country)
      sql = "SELECT id FROM countries WHERE alpha2 = '#{country}'"
      select_first(sql)
    end

    def get_state_id(state_abbr, state_name)
      sql = "SELECT id FROM states
        WHERE abbr = '#{state_abbr}' OR name = '#{escape_single_quotes(state_name)}'"
      select_first(sql)
    end

    def get_county_id(county)
      return nil if county.nil?
      sql = "SELECT id FROM counties WHERE name = '#{escape_single_quotes(county)}'"
      select_first(sql)
    end

    def escape_single_quotes(string)
      string&.gsub(/[']/, '\'\'') || ''
    end
  end
end
