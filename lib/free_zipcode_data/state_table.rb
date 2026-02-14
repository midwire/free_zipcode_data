# frozen_string_literal: true

require_relative 'db_table'

module FreeZipcodeData
  class StateTable < DbTable
    def build
      schema = <<-SQL
        create table #{tablename} (
          id integer not null primary key,
          country_id integer not null,
          abbr varchar(2) not null,
          name varchar(255)
        )
      SQL
      database.execute_batch(schema)

      ndx = <<-SQL
        CREATE UNIQUE INDEX "main"."unique_state"
        ON #{tablename} (abbr COLLATE NOCASE ASC, country_id);
      SQL
      database.execute_batch(ndx)

      ndx = <<-SQL
        CREATE UNIQUE INDEX "main"."state_name"
        ON #{tablename} (name COLLATE NOCASE ASC, country_id);
      SQL
      database.execute_batch(ndx)
    end

    def write(row)
      return nil unless synthesize_state(row)

      row[:state] = 'Marshall Islands' if row[:short_state] == 'MH' && row[:state].nil?
      country_id = get_country_id(row[:country])
      unless country_id
        warn_once("Country '#{row[:country]}' not found in countries table, skipping state")
        return nil
      end

      sql = <<-SQL
        INSERT INTO states (abbr, name, country_id)
        VALUES ('#{row[:short_state]}',
          '#{escape_single_quotes(row[:state])}',
          #{country_id}
        )
      SQL
      begin
        database.execute(sql)
      rescue SQLite3::ConstraintException => e
        unless e.message.include?('UNIQUE')
          raise "Please file an issue at #{ISSUE_URL}: [#{e}] -> SQL: [#{sql}]"
        end
      rescue StandardError => e
        raise "Please file an issue at #{ISSUE_URL}: [#{e}] -> SQL: [#{sql}]"
      end

      update_progress
    end

    private

    # Synthesize state from country for stateless countries.
    # Mutates the row hash so downstream Kiba destinations (CountyTable, ZipcodeTable)
    # see the synthesized short_state and state values.
    def synthesize_state(row)
      if row[:short_state].nil? || row[:short_state] == ''
        country_entry = country_lookup_table[row[:country]]
        unless country_entry
          warn_once(
            "Cannot synthesize state for country '#{row[:country]}': " \
            'not in country_lookup_table'
          )
          return false
        end

        row[:short_state] = row[:country]
        row[:state] = country_entry[:name]
      end
      row[:short_state]
    end
  end
end
