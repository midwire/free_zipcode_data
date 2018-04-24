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
        ON #{tablename} (abbr, country_id COLLATE NOCASE ASC);
      SQL
      database.execute_batch(ndx)

      ndx = <<-SQL
        CREATE UNIQUE INDEX "main"."state_name"
        ON #{tablename} (name COLLATE NOCASE ASC);
      SQL
      database.execute_batch(ndx)
    end

    def write(row)
      return nil unless row[:short_state]
      row[:state] = 'Marshall Islands' if row[:short_state] == 'MH' && row[:state].nil?
      country_id = get_country_id(row[:country])
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
      end

      update_progress
    end
  end
end
