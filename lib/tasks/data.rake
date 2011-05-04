require 'rubygems'
require 'sqlite3'
require 'fastercsv'
require 'lib/string'

namespace :data do
  
  desc "Kill the current sqlite db file."
  task :kill_db do
    FileUtils.rm_f "free_zipcode_data.sqlite3"
  end

  desc "Create states table"
  task :create_states_table => :kill_db do
    schema = <<-stop.here_with_pipe
      |create table states (
      |  id integer not null primary key,
      |  abbr varchar(2) not null,
      |  name varchar(255)
      |)
    stop
    database.execute_batch(schema)
  end

  desc "Create counties table"
  task :create_counties_table => :create_states_table do
    schema = <<-stop.here_with_pipe
      |create table counties (
      |  id integer not null primary key,
      |  state_id integer,
      |  abbr varchar(255),
      |  name varchar(255),
      |  county_seat varchar(255)
      |)
    stop
    database.execute_batch(schema)
  end

  desc "Create zipcodes table"
  task :create_zipcodes_table => :create_counties_table do
    schema = <<-stop.here_with_pipe
      |create table zipcodes (
      |  id integer not null primary key,
      |  code varchar(5) not null,
      |  state_id integer,
      |  county_id integer,
      |  city varchar(255),
      |  area_code varchar(3),
      |  lat float,
      |  lon float
      |)
    stop
    database.execute_batch(schema)
  end

  desc "Populate an sqlite DB"
  task :populate_db => :create_zipcodes_table do
    puts ">>> Working..."

    # States
    puts ">>>> States..."
    FasterCSV.foreach("all_us_states.csv", :headers => true) do |row|
      database.execute("INSERT INTO states (abbr, name) values ('#{row['abbr']}', '#{row['name']}')")
    end

    # Counties
    puts ">>>> Counties..."
    FasterCSV.foreach("all_us_counties.csv", :headers => true) do |row|
      state_id = get_state_id(row['state'])
      database.execute("INSERT INTO counties (state_id, name, county_seat) values (#{state_id}, '#{row['name']}', '#{row['county_seat']}')")
    end

    # Zipcodes
    puts ">>>> Zipcodes..."
    FasterCSV.foreach("all_us_zipcodes.csv", :headers => true) do |row|
      state_id = get_state_id(row['state'])
      county_id = get_county_id(row['county'])
      city_name = row['city'].gsub(/[']/, '\'\'')
      sql = "INSERT INTO zipcodes (code,city,state_id,county_id,area_code,lat,lon) values ('#{row['code']}', '#{city_name}', #{state_id}, #{county_id}, '#{row['area_code']}', '#{row['lat']}', '#{row['lon']}')"
      begin
        database.execute(sql)
      rescue Exception => e
        puts ">>>>> Exception: [#{e.inspect}]"
        puts ">>>>> SQL: [#{sql}]"
      end
    end
    puts ">>>> Complete!"
  end
  
  def database
    @db ||= SQLite3::Database.new('free_zipcode_data.sqlite3')
  end
  
  def get_state_id(state)
    rows = database.execute("SELECT id FROM states WHERE abbr = '#{state}'")
    rows[0]
  end

  def get_county_id(county)
    rows = database.execute("SELECT id FROM counties WHERE name = '#{county}'")
    rows[0]
  end

end
