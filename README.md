# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...


## Component Engines

Each UI & backend component is developed in an independent Rails Engine in order
to provide test/dev isolation of components, while allowing for an instance of
the Installer to load only the needed components.

### Adding a new engine

`rails plugin new engines/$ENGINE_NAME -d sqlite3 --skip-git --mountable --skip-gemfile-entry`

* Remove the `Gemfile`, `*.gemspec`, `lib/$ENGINE_NAME/version.rb`
* Add the following to `appliction_controller.rb`:
  ```
  helper Rails.application.helpers
  layout 'layouts/application'
  ```
