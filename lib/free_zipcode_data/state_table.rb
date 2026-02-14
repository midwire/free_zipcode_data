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
      return nil unless country_id

      sql = <<-SQL
        INSERT INTO states (abbr, name, country_id)
        VALUES ('#{row[:short_state]}',
          '#{escape_single_quotes(row[:state])}',
          #{country_id}
        )
      SQL
      begin
        database.execute(sql)
      rescue SQLite3::ConstraintException
        # Swallow duplicates
      rescue StandardError => e
        raise "Please file an issue at #{ISSUE_URL}: [#{e}] -> SQL: [#{sql}]"
      end

      update_progress
    end

    private

    # Synthesize state from country for stateless countries (downstream tables need this)
    def synthesize_state(row)
      if row[:short_state].nil? || row[:short_state] == ''
        country_entry = country_lookup_table[row[:country]]
        return false unless country_entry

        row[:short_state] = row[:country]
        row[:state] = country_entry[:name]
      end
      row[:short_state]
    end
  end
end
