FROM ruby:3.4-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential git pkg-config && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock free_zipcode_data.gemspec .ruby-version ./
COPY lib/free_zipcode_data/version.rb lib/free_zipcode_data/version.rb
RUN git init && git add . && \
    bundle config set --local without development && \
    bundle install

COPY . .
RUN git add .

ENV COUNTRY=""
VOLUME /output

ENTRYPOINT ["./docker-entrypoint.sh"]
