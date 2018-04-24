# frozen_string_literal: true

require_relative 'db_table'

module FreeZipcodeData
  class CountryTable < DbTable
    def build
      schema = <<-SQL
        create table #{tablename} (
          id integer not null primary key,
          alpha2 varchar(2) not null,
          alpha3 varchar(3),
          iso varchar(3),
          name varchar(255) not null
        )
      SQL
      database.execute_batch(schema)

      ndx = <<-SQL
        CREATE UNIQUE INDEX "main"."unique_country_alpha2"
        ON #{tablename} (alpha2 COLLATE NOCASE ASC);
      SQL
      database.execute_batch(ndx)
    end

    def write(row)
      country_hash = country_lookup_table[row[:country]]

      sql = <<-SQL
        INSERT INTO countries (alpha2, alpha3, iso, name)
        VALUES ('#{row[:country]}',
          '#{country_hash[:alpha3]}',
          '#{country_hash[:iso]}',
          '#{country_hash[:name]}')
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
