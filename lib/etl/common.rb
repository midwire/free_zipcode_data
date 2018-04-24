# frozen_string_literal: true

require_relative 'csv_source'
require_relative '../free_zipcode_data/country_table'
require_relative '../free_zipcode_data/state_table'
require_relative '../free_zipcode_data/county_table'
require_relative '../free_zipcode_data/zipcode_table'

def show_me
  transform do |row|
    ap row
    row
  end
end

def limit(count)
  count = Integer(count || -1)
  return if count == -1
  transform do |row|
    @counter ||= 0
    @counter += 1
    @counter > count ? nil : row
  end
end
