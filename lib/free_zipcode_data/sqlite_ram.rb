# frozen_string_literal: true

require 'sqlite3'

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
end
