natureofcode.com
================

Repo for web files for nature of code

## Development

This app uses Postgres for a database, the easiest way to use Postgres on Mac
is to install [Postgres.app](http://postgresapp.com/). Be sure the app is
running and then build the bundle.

    $ bundle install

Now create a Postgres database with the following:

    $ psql -h localhost
    > CREATE DATABASE natureofcode

