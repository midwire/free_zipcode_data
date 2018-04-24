# Free Zipcode Data

Zipcode data is free from the various governments around the world. Yet so many organizations, reputable or not, want to charge money for it.

This project is an automated solution for retrieving and collating US and worldwide zipcode data.

## History

In 2011, we originally pulled down all the US census data we could find, parsed it and exported it into 3 .csv files. Later, we wrote 3 rake tasks to automate this process.

In 2017 we began using [GeoNames](http://www.geonames.org) data, which is licensed under Creative Commons. We are grateful to [GeoNames](http://www.geonames.org) for sharing, and urge you to [visit their site](http://www.geonames.org) and support their work.

In 2018 we refactored the project and made it into a Ruby gem with a command-line executable for automating this process.

## What's Included

* An executable: `free_zipcode_data` - which automates the process of downloading and process the zipcode data from GeoNames. Not all countries are accounted for. Please check [GeoNames](http://download.geonames.org/export/zip/) to see a list of supported country zip files.

Each zipcode is correlated with estimated or zip-centroid, latitude and longitude coordinates. Where applicable, country, county/province, state and community are also correlated.

See the GeoNames [readme.txt](http://download.geonames.org/export/zip/readme.txt) file for more information.

## Usage

First, you need to install Ruby and Rubygems. Though that is not a difficult task, it is beyond the scope of this README. A search engine of your choice will help discover how to do this.  Once you have done that:

```bash
$ gem install free_zipcode_data
```

Determine the 2-letter country codes for the countries you want to use at [GeoNames](http://download.geonames.org/export/zip/), or don't specify a country to get all zipcodes for all available countries...

### Command Line Options

```bash
Options:
  -w, --work-dir=<s>             REQUIRED: Specify your work/build directory, where the SQLite and .csv files will be built
  -f, --country=<s>              Specify the country code for processing, or all countries if not specified
  -g, --generate-files           Generate CSV files: [counties.csv, states.csv, countries.csv, zipcodes.csv]
  -o, --country-tablename=<s>    Specify the name for the `countries` table (default: countries)
  -s, --state-tablename=<s>      Specify the name for the `states` table (default: states)
  -u, --county-tablename=<s>     Specify the name for the `counties` table (default: counties)
  -z, --zipcode-tablename=<s>    Specify the name for the `zipcodes` table (default: zipcodes)
  -c, --clobber                  Overwrite existing files
  -d, --dry-run                  Do not actually move or copy files
  -v, --verbose                  Be verbose with output
  -h, --help                     Show this message
```

### Examples

**Download and process all US zipcodes**:

```bash
$ free_zipcode_data --work-dir /tmp/work_dir --country US --generate-files
```

**Download and process zipcodes for all available countries**:

```bash
$ free_zipcode_data --work-dir /tmp/work_dir --generate-files
```

The rake tasks cascade, from the bottom up. So if you run `rake data:populate_db`, it will automatically call `rake data:build` if the .csv files are missing, which will call `rake data:download` if the .zip files are missing.

## SQLite3 Database

The executable will generate an SQLite3 database in the specified directory `--work-dir` but it will not generate the `.csv` files by default. Specify `--generate-files` if you want those as well.

By default the tables will be named as follows. To override the table names see the command line options above.

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

See [CHANGELOG](CHANGELOG) for more history and errata.
