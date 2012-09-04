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

Create a .env file to hold the Fetch and Stripe API keys and add the following
lines adding your keys after the equals signs:

    # .env
    FETCH_KEY=
    FETCH_TOKEN=
    STRIPE_PUBLIC_KEY=
    STRIPE_SECRET=
    DATABASE_URL=postgres://USERNAME@localhost:5432/natureofcode

Finally, install Foreman and start the app.

    $ gem install foreman
    $ foreman start

Foreman runs on port 5000 by default and will load in the contents of .env.

## Deploying to Heroku

For each line in `.env` from above, **except for DATABASE_URL**, do the following:

    $ heroku config:add FETCH_KEY=_____________

## Deploying to Github Pages

All files outside of the **public** directory in `master` should be removed for
the `gh-pages` branch and all files in **public/** can be promoted one level.

Currently links to "read the book online" are directed at **book/**.