# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Ruby gem that downloads postal/zipcode data from GeoNames.org, processes it via an ETL pipeline, and outputs an SQLite3 database and optional CSV files. Supports single-country or all-countries processing.

## Commands

```bash
# Install dependencies (vendored to vendor/bundle, binstubs in stubs/)
bundle install

# Run all tests
bundle exec rspec

# Run a single test file
bundle exec rspec spec/path/to/file_spec.rb

# Run a specific test by line number
bundle exec rspec spec/path/to/file_spec.rb:42

# Lint
bundle exec rubocop

# Lint with auto-correct
bundle exec rubocop -a

# Version bumping (do on develop branch, not master)
bundle exec rake version:bump_patch
bundle exec rake version:bump_minor
bundle exec rake version:bump_major

# Build and install gem
bundle exec rake build
bundle exec rake install

# Release gem
bundle exec rake release
```

## Architecture

The gem follows an ETL (Extract, Transform, Load) pattern using the Kiba gem:

1. **Extract**: `DataSource` downloads zip files from GeoNames.org, extracts them, and prepares CSV files with headers
2. **Source**: `CsvSource` (Kiba source) feeds rows from the prepared CSV into the pipeline
3. **Load**: Four Kiba destination table classes write rows into an in-memory SQLite database

### Key Flow

`bin/free_zipcode_data` → `Runner#start` → `DataSource#download` → `DataSource#datafile` (extract zip + add CSV headers) → `SqliteRam` (in-memory DB) → `ETL::FreeZipcodeDataJob` (Kiba pipeline) → `SqliteRam#save_to_disk`

### Core Classes

- **`FreeZipcodeData::Runner`** - CLI entry point; parses args via Optimist, orchestrates the full pipeline
- **`FreeZipcodeData::DataSource`** - Downloads and extracts GeoNames zip files, prepares CSV with headers
- **`SqliteRam`** - Wraps SQLite3; works entirely in-memory then saves to disk via `SQLite3::Backup`
- **`FreeZipcodeData::DbTable`** - Base class for all table classes; provides progress bar, SQL helpers, and country lookup from `country_lookup_table.yml`
- **`FreeZipcodeData::CountryTable`/`StateTable`/`CountyTable`/`ZipcodeTable`** - Kiba destinations; each has `build` (creates schema + indexes) and `write` (inserts rows, swallows duplicate constraint violations)
- **`ETL::FreeZipcodeDataJob`** - Configures the Kiba pipeline with one source and four destinations
- **`CsvSource`** - Kiba-compatible CSV reader

### Singletons

`Options` and `Logger` are singletons (via Ruby's `Singleton` module). `Runner` has an `.instance` convenience class method (returns `new` each time, not cached).

## Configuration

- `.ruby-version`: 3.4.8
- Bundle path: `vendor/bundle` (binstubs in `stubs/`)
- Environment: `APP_ENV` controls environment (`test`, `development`)
- Config file: `~/.free_zipcode_data.yml` (overridable via `FZD_CONFIG_FILE` env var; uses `spec/fixtures/` version in test)

## Rubocop

Key style settings (`.rubocop.yml`):
- Target Ruby 3.4
- Max line length: 110
- Max method length: 30 lines
- `Style/ClassVars`, `Style/Documentation`, `Metrics/AbcSize`, `Lint/SuppressedException` disabled
- `vendor/` and `stubs/` excluded

## Git Workflow

- `master` is the release branch
- `develop` is the development branch
- Version bumps should happen on `develop`, then merge to `master` before `rake release`
