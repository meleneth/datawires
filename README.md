# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

- Ruby version

- System dependencies

- Configuration

- Database creation

- Database initialization

- How to run the test suite

- Services (job queues, cache servers, search engines, etc.)

- Deployment instructions

- ...

  rake db:create
  rake db:migrate
  bin/rails runner script/import_json.rb schema <https://json-schema.org/draft/2020-12/schema>
  bin/rails db:seed
