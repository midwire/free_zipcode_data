# frozen_string_literal: true

require_relative 'db_table'

module FreeZipcodeData
  class ZipcodeTable < DbTable
    def build
      schema = <<-SQL
        create table #{tablename} (
          id integer not null primary key,
          code varchar(10) not null,
          state_id integer,
          city varchar(255),
          area_code varchar(3),
          lat float,
          lon float,
          accuracy varchar(8)
        )
      SQL
      database.execute_batch(schema)

      ndx = <<-SQL
        CREATE UNIQUE INDEX "main"."unique_zipcode"
        ON #{tablename} (state_id, code, city COLLATE NOCASE ASC);
      SQL
      database.execute_batch(ndx)
    end

    def write(row)
      return nil unless row[:postal_code]

      state_id = get_state_id(row[:short_state], row[:state])
      city_name = escape_single_quotes(row[:city])

      sql = <<-SQL
        INSERT INTO zipcodes (code, state_id, city, lat, lon, accuracy)
        VALUES ('#{row[:postal_code]}',
          '#{state_id}',
          '#{city_name}',
          '#{row[:latitude]}',
          '#{row[:longitude]}',
          '#{row[:accuracy]}'
        )
      SQL

      begin
        database.execute(sql)
      rescue SQLite3::ConstraintException => _err
        # there are some duplicates - swallow them
      rescue StandardError => err
        raise "Please file an issue at #{ISSUE_URL}: [#{err}] -> SQL: [#{sql}]"
      end

      update_progress
    end
  end
end
