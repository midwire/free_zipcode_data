# frozen_string_literal: true

require 'sqlite3'
require 'csv'

# Open a SQlite DB, work with it in-memory and save back to disk
class SqliteRam
  attr_reader :filename, :conn

  def initialize(sqlite_filename)
    @filename = sqlite_filename
    @ram_db   = SQLite3::Database.new(':memory:')
    @file_db  = SQLite3::Database.new(sqlite_filename)
    @conn     = @ram_db
  end

  def save_to_disk
    backup = SQLite3::Backup.new(@file_db, 'main', @ram_db, 'main')
    backup.step(-1)
    backup.finish
  end

  def dump_tables(path)
    tables = conn.execute('select name from sqlite_master where type = "table"')
    sql = nil
    tables.each do |table_array|
      table = table_array.first
      headers_sql = "pragma table_info('#{table}')"
      header = conn.execute(headers_sql).map { |e| e[1] }
      CSV.open(File.join(path, "#{table}.csv"), 'w') do |csv|
        csv << header
        sql = "select * from #{table}"
        conn.execute(sql).each do |row_array|
          csv << row_array
        end
      end
    end
  end
end
