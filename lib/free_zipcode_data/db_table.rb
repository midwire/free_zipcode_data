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
      rows[0]&.first
    rescue SQLite3::SQLException => e
      raise "Please file an issue at #{ISSUE_URL}: [#{e}] -> SQL: [#{sql}]"
    end

    def get_country_id(country)
      sql = "SELECT id FROM countries WHERE alpha2 = '#{country}'"
      select_first(sql)
    end

    def get_state_id(country, state_abbr, state_name)
      escaped_country = escape_single_quotes(country)
      escaped_abbr = escape_single_quotes(state_abbr)
      escaped_name = escape_single_quotes(state_name)

      # Try exact match: abbr + name + country
      sql = <<-SQL
        SELECT s.id FROM states s
        INNER JOIN countries c ON s.country_id = c.id
        WHERE s.abbr = '#{escaped_abbr}'
        AND s.name = '#{escaped_name}'
        AND c.alpha2 = '#{escaped_country}'
      SQL
      res = select_first(sql)

      # Fallback: abbr + country only
      if res.nil?
        sql = <<-SQL
          SELECT s.id FROM states s
          INNER JOIN countries c ON s.country_id = c.id
          WHERE s.abbr = '#{escaped_abbr}'
          AND c.alpha2 = '#{escaped_country}'
        SQL
        res = select_first(sql)
      end

      # Fallback: name + country only
      if res.nil?
        sql = <<-SQL
          SELECT s.id FROM states s
          INNER JOIN countries c ON s.country_id = c.id
          WHERE s.name = '#{escaped_name}'
          AND c.alpha2 = '#{escaped_country}'
        SQL
        res = select_first(sql)
      end

      res
    end

    def get_county_id(county)
      return nil if county.nil?

      sql = "SELECT id FROM counties WHERE name = '#{escape_single_quotes(county)}'"
      select_first(sql)
    end

    def escape_single_quotes(string)
      string&.gsub('\'', '\'\'') || ''
    end
  end
end
