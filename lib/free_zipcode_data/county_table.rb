# frozen_string_literal: true

require_relative 'db_table'

module FreeZipcodeData
  class CountyTable < DbTable
    def build
      schema = <<-SQL
        create table #{tablename} (
          id integer not null primary key,
          state_id integer,
          abbr varchar(255),
          name varchar(255),
          county_seat varchar(255)
        )
      SQL
      database.execute_batch(schema)

      ndx = <<-SQL
        CREATE UNIQUE INDEX "main"."unique_county"
        ON #{tablename} (state_id, abbr, name COLLATE NOCASE ASC);
      SQL
      database.execute_batch(ndx)
    end

    def write(row)
      return nil unless row[:county]
      state_id = get_state_id(row[:short_state])
      raise "Could not find state: #{row[:short_state]}" unless state_id
      sql = <<-SQL
        INSERT INTO counties (state_id, abbr, name)
        VALUES ('#{state_id}',
          '#{row[:short_county]}',
          '#{escape_single_quotes(row[:county])}'
        )
      SQL

      begin
        database.execute(sql)
      rescue SQLite3::ConstraintException
        # swallow duplicates
      rescue StandardError => err
        raise "Please file an issue at #{ISSUE_URL}: [#{err}] -> SQL: [#{sql}]"
      end
    end
  end
end
