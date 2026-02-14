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

    def logger
      Logger.instance
    end

    def warn_once(message)
      @warned_messages ||= {}
      return if @warned_messages[message]

      logger.warn(message)
      @warned_messages[message] = true
    end

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

    # Look up a state ID scoped to a country, trying progressively less specific
    # criteria: (1) abbr + name + country, (2) abbr + country, (3) name + country.
    # Returns nil if no match is found.
    def get_state_id(country, state_abbr, state_name)
      escaped_country = escape_single_quotes(country)
      return nil if escaped_country.empty?

      escaped_abbr = escape_single_quotes(state_abbr)
      escaped_name = escape_single_quotes(state_name)
      country_cond = "c.alpha2 = '#{escaped_country}'"
      # Most specific lookup: abbr + name + country
      res = find_state_where("s.abbr = '#{escaped_abbr}'", "s.name = '#{escaped_name}'", country_cond)
      return res if res

      # Fallback: abbr + country only
      res = find_state_where("s.abbr = '#{escaped_abbr}'", country_cond)
      if res
        logger.verbose("State fallback: abbr '#{state_abbr}' + country '#{country}' (name mismatch)")
        return res
      end
      # Fallback: name + country only
      res = find_state_where("s.name = '#{escaped_name}'", country_cond)
      if res
        logger.verbose("State fallback: name '#{state_name}' + country '#{country}' (abbr mismatch)")
        return res
      end
      logger.warn("State lookup failed: abbr='#{state_abbr}', name='#{state_name}', country='#{country}'")
      nil
    end

    def find_state_where(*conditions)
      sql = <<-SQL
        SELECT s.id FROM states s
        INNER JOIN countries c ON s.country_id = c.id
        WHERE #{conditions.join(' AND ')}
      SQL
      select_first(sql)
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
