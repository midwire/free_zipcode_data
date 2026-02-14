# frozen_string_literal: true

require 'sqlite3'

module DatabaseHelpers
  def create_test_database(line_count: 5)
    db = SQLite3::Database.new(':memory:')
    db.execute_batch(<<-SQL)
      CREATE TABLE meta (
        id integer not null primary key,
        name varchar(255),
        value varchar(255)
      )
    SQL
    db.execute("INSERT INTO meta (name, value) VALUES ('line_count', #{line_count})")
    db
  end

  def seed_countries(db, tablename: 'countries')
    table = FreeZipcodeData::CountryTable.new(database: db, tablename: tablename)
    table.build
    [
      { country: 'US' },
      { country: 'CA' },
      { country: 'GB' }
    ].each { |row| table.write(row) }
  end

  def seed_states(db, tablename: 'states')
    table = FreeZipcodeData::StateTable.new(database: db, tablename: tablename)
    table.build
    [
      { country: 'US', short_state: 'NY', state: 'New York' },
      { country: 'US', short_state: 'CA', state: 'California' },
      { country: 'US', short_state: 'IL', state: 'Illinois' }
    ].each { |row| table.write(row) }
  end

  def seed_counties(db, tablename: 'counties')
    table = FreeZipcodeData::CountyTable.new(database: db, tablename: tablename)
    table.build
    [
      { county: 'New York', short_county: '061', short_state: 'NY', state: 'New York' },
      { county: 'Los Angeles', short_county: '037', short_state: 'CA', state: 'California' },
      { county: 'Cook', short_county: '031', short_state: 'IL', state: 'Illinois' }
    ].each { |row| table.write(row) }
  end
end
