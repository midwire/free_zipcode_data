# frozen_string_literal: true

require 'csv'

class CsvSource
  attr_reader :filename, :delimeter, :quote_char, :headers

  def initialize(filename:, headers: true, delimeter: "\t", quote_char: '"')
    @filename   = filename
    @headers    = headers
    @delimeter  = delimeter
    @quote_char = quote_char
  end

  def each
    CSV.open(filename,
      col_sep: delimeter,
      headers: headers,
      header_converters: :symbol,
      quote_char: quote_char) do |csv|
      csv.each do |row|
        yield(row.to_hash)
      end
    end
  end
end
