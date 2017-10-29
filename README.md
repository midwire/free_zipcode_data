# Free Zipcode Data

Zipcode data is free from the various governments around the world. Yet so many organizations, reputable or not, want to charge money for it.

We originally pulled down all the US census data we could find, parsed it and exported it into .csv files.

In 2017 we began using [GeoNames](http://www.geonames.org) data, which is licensed under Creative Commons:

We thank [GeoNames](http://www.geonames.org) for sharing, and urge you to [visit their site](http://www.geonames.org) and support their work.

## What's Included

There are three rake tasks which automatically download the latest zipcode data from the country that you specify. Not all countries are accounted for. Please check [GeoNames](http://download.geonames.org/export/zip/) to see a list of supported country zip files.

Each zipcode is correlated with estimated or zip-centroid, latitude and longitude coordinates. Where applicable, county/province, state and community are also correlated.

See the GeoNames [readme.txt](http://download.geonames.org/export/zip/readme.txt) file for more information.

## Usage

```bash
$ git clone https://github.com/midwire/free_zipcode_data
$ cd free_zipcode_data
```

Determine the countries you want to use at [GeoNames](http://download.geonames.org/export/zip/), or just use the rake task without any `country` argument to get zipcode data for all countries...
```bash
# download will pull down the zipcodes for the specified country
$ rake data:download[country]
# rake data:download[US] - For US-only zipcodes
# rake data:download[GB_full.csv] - All UK data zipcodes:
# rake data:download - ALL zipcodes
```

```bash
# build the .csv files
$ rake data:build[country]
# rake data:build - ALL countries
```

```bash
# populate_db will automatically download the zips and build the .csv files
$ rake data:populate_db[country]
# rake data:populate_db - ALL countries - WARNING: takes a long time
```

The rake tasks cascade, from the bottom up. So if you run `rake data:populate_db`, it will automatically call `rake data:build` if the .csv files are missing, which will call `rake data:download` if the .zip files are missing.

## SQLite3 Database

The rake task `rake data:populate_db[country]` will create an SQLite3 database with the following tables, and populate each one:

```sql
create table countries (
  id integer not null primary key,
  alpha2 varchar(2) not null,
  alpha3 varchar(3),
  iso varchar(3),
  name varchar(255) not null
)

create table states (
  id integer not null primary key,
  country_id integer not null,
  abbr varchar(2) not null,
  name varchar(255)
)

create table counties (
  id integer not null primary key,
  state_id integer,
  abbr varchar(255),
  name varchar(255),
  county_seat varchar(255)
)

create table zipcodes (
  id integer not null primary key,
  code varchar(10) not null,
  state_id integer,
  county_id integer,
  city varchar(255),
  area_code varchar(3),
  lat float,
  lon float,
  accuracy varchar(8)
)
```

Both `lat` and `lon`, geocodes, are populated for each zipcode record.

## Data License

The zipcode data is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by/3.0/">Creative Commons Attribution 3.0 Unported License</a>, carried forward from [GeoNames](http://www.geonames.org).<br />
<a rel="license" href="http://creativecommons.org/licenses/by/3.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by/3.0/88x31.png" /></a>

## Errata

### 05/04/2011:

* Removed un-assigned zipcodes, which were not valid for today
* Added a Rakefile and some rake tasks to facilitate building a SQLite relational database for the three tables (states, counties, zipcodes)
* Zipcodes without an associated county == 0
* Counties without a zipcode == 1 (PISCATAGUIS, Maine)

### 01/24/2011:

* 670 orphaned zipcodes without an associated county
* 1 county without any zipcodes (PISCATAGUIS, Maine)

### 01/13/2011:

At last check there were ...

* 897 orphaned zipcodes without an associated county
* 1 county without any zipcodes (PISCATAGUIS, Maine)
