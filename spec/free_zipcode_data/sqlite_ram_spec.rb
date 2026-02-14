# frozen_string_literal: true

require 'tempfile'
require 'free_zipcode_data/sqlite_ram'

RSpec.describe SqliteRam do
  let(:tmpdir) { Dir.mktmpdir('sqlite_ram_test') }
  let(:db_path) { File.join(tmpdir, 'test_db.sqlite3') }
  let(:sqlite_ram) { described_class.new(db_path) }

  after do
    FileUtils.rm_rf(tmpdir)
  end

  describe '#initialize' do
    it 'creates an in-memory database connection' do
      expect(sqlite_ram.conn).to be_a(SQLite3::Database)
    end

    it 'stores the filename' do
      expect(sqlite_ram.filename).to eq(db_path)
    end
  end

  describe '#save_to_disk' do
    it 'persists in-memory data to the file database' do
      sqlite_ram.conn.execute('CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT)')
      sqlite_ram.conn.execute("INSERT INTO test (name) VALUES ('hello')")
      sqlite_ram.save_to_disk

      file_db = SQLite3::Database.new(db_path)
      rows = file_db.execute('SELECT name FROM test')
      expect(rows).to eq([['hello']])
      file_db.close
    end
  end

  describe '#dump_tables' do
    it 'exports each table to a CSV file in the given directory' do
      sqlite_ram.conn.execute('CREATE TABLE widgets (id INTEGER PRIMARY KEY, name TEXT, weight REAL)')
      sqlite_ram.conn.execute("INSERT INTO widgets (name, weight) VALUES ('gear', 1.5)")
      sqlite_ram.conn.execute("INSERT INTO widgets (name, weight) VALUES ('bolt', 0.3)")

      sqlite_ram.dump_tables(tmpdir)

      csv_path = File.join(tmpdir, 'widgets.csv')
      expect(File.exist?(csv_path)).to be true

      csv = CSV.read(csv_path)
      expect(csv[0]).to eq(%w[id name weight])
      expect(csv.length).to eq(3) # header + 2 rows
    end

    it 'exports multiple tables' do
      sqlite_ram.conn.execute('CREATE TABLE a (id INTEGER PRIMARY KEY)')
      sqlite_ram.conn.execute('CREATE TABLE b (id INTEGER PRIMARY KEY)')

      sqlite_ram.dump_tables(tmpdir)

      expect(File.exist?(File.join(tmpdir, 'a.csv'))).to be true
      expect(File.exist?(File.join(tmpdir, 'b.csv'))).to be true
    end
  end
end
