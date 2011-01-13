# Free Zipcode Data

We got sick and tired of trying to find free zipcode data.  So we pulled down all the census data we could find, parsed it and exported it into these .csv files.

## CSV Data

### `all_us_counties.csv`
    name, state, county_seat

### `all_us_states.csv`
    abbr, name

### `all_us_zipcodes.csv`
    code, city, state, county, area_code, lat, lon
    
Both `lat` and `lon`, geocodes, are populated for each zipcode record.

## SQL Data

### `counties_states_zipcodes.sql`

This is a MySQL ready dump of the three tables `counties`, `states` and `zipcodes`.  Both structure and data, along with complete and extended INSERTs are included in the dump.

## Updating

Please add any missing data, or correct mistakes, and send us a pull request.

## Errata

At last check there were ...

* 897 orphaned zipcodes without an associated county
* 1 county without any zipcodes (PISCATAGUIS, Maine)
