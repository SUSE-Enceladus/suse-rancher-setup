![CI testing](https://github.com/SUSE-Enceladus/suse-rancher-setup/actions/workflows/rails-testing.yml/badge.svg)

# SUSE Rancher Setup

Simple, usable web application for deploying complex applications to the cloud; wrapping cloud native SDK/CLIs.

## Dependencies

*suse-rancher-setup* depends on, primarily:

* Ruby 3.1 (currently 3.1.2)
* Rails 7.1
* Sqlite 3
* AWS-CLI (v1 or v2)
* [ec2metadata](https://github.com/SUSE-Enceladus/ec2metadata)
* helm ~3.4
* [kuberlr](https://github.com/flavio/kuberlr) (or kubectl 1.24)

## Contributing

This Ruby on Rails-bsed project uses [rvm](http://rvm.io/rvm/basics) to manage a virtual environment for development.

1.  Clone this project

2.  RVM will prompt you to install the required ruby version, if necessary, when entering the project directory.

3.  Install dependencies
    ```
    gem install bundler
    bundle
    ```
    If you have trouble with _nokogiri_, make sure you have development versions of _libxml2_ & _libxslt_ installed. Install also sqlite-devel. On (open)SUSE:
    ```
    sudo zypper in libxml2-devel libxslt-devel sqlite3-devel
    ```

4.  Create a local config file
    ```
    cp config/example_config.yml config/config.yml
    ```
    Only an example config is included in the project for reference. Your working config is not included in the source repository.

4.  Initialize a development database
    ```
    rails db:setup
    ```

5.  Start a development server on http://localhost:3000
    ```
    rails server -b localhost -p 3000
    ````

6.  If running the Azure engine, the active subscription ID is detected via IMDS (e.g., the suse-rancher-setup instance must run in the subscription where it will deploy). When developing locally, the subscription must be set via the `rails console` instead, before interacting with the Azure API:
    ```
    Azure::Subscription.new(value: "YOUR SUBSCRIPTION UUID").save
    ```

Please be sure to include a screenshot with any view or style changes.

## Testing

To run the full test suite using all avialable recordings, run `rails coverage`. Alternatively, specify a workflow and engine set, as would be defined in a production config, in environment variables, and only specs appropriate to that workflow will be run:

* `LASSO_WORKFLOW` - name of the workflow engine
* `LASSO_ENGINES` - comma-separated list of engines to load

Example:
```
LASSO_WORKFLOW=RancherOnAks LASSO_ENGINES=Azure,ShirtSize,PreFlight,RancherOnAks,Helm rspec
```

💡 *Use the environment variable `RERECORD=true` when re-recording the test suite.*

### Azure

The Azure interface uses the Azure REST API; test fixtures are recorded with VCR. To record new tests, delete the old recordings from `spec/vcr/$SPEC_NAME`, and set the following environment variables when running `rspec`:

* `APP_ID` - The UUID of the Azure service principal
* `PASSWORD` - the Azure service principal secret
* `TENANT` - the Azure service principal tenant UUID
* `SUBSCRIPTION` - the Azure subscription UUID where the application will be executed (SP must have permissions)

Due to random selection, a few static values need to be reset on the suite after re-recording. Please follow the inline instructions to update the `before(:example)` block in spec/system/RancherOnAks/happy_path_spec.rb .

### AWS

The AWS interface uses the AWS CLI (`aws`); test fixtures are recorded via a harness trap. Please see `rails -T vcr` for _rake_ tasks used to maintain the recordings. Your local AWS CLI must be authenticated to the account where Rancher will be deployed.

Due to random selection, a few static values need to be reset on the suite after re-recording. Please follow the inline instructions to update the `before(:example)` block in spec/system/RancherOnEks/happy_path_spec.rb .

## Component Engine Architecture

Each UI & backend component is developed in an independent Rails Engine in order
to provide test/dev isolation of components, while allowing for an instance of
the Installer to load only the needed components.

### Adding a new engine

`rails plugin new engines/$ENGINE_NAME -d sqlite3 --skip-git --mountable --skip-gemfile-entry`

* Remove the `Gemfile`, `*.gemspec`, `lib/$ENGINE_NAME/version.rb`
* Remove `require '$ENGINE_NAME/version'` from `lib/$ENGINE_NAME.rb`
* Remove any unnecessary components, if desired (mailers, jobs, assets)
* Edit `config/routes.rb` to include a route for the engine, conditioned on the engine being loaded.

### Loading a collection of engines as a workflow

Engines are only loaded if the application is configured to do so. To load an engine it must be included in the list `Rails.configuration.engines`, defined in `config/application.rb`.

Since each engine may define UI elements in the workflow, the order engines are loaded determines the order of the menu entries in the application. The only exception is the 'Welcome' page, which is always first.

### Deployment Engine

One Engine in the workflow should be designated as the 'deployment engine'. This should define the overall workflow and the steps to be performed for the deployment, including authorization for the entire workflow. See [engines/rancher_on_eks/app/helpers/rancher_on_eks/authorization_helper.rb](engines/rancher_on_eks/app/helpers/rancher_on_eks/authorization_helper.rb) for an example.

### Adding workflow UI to an engine

Add web content to an engine like any other application; it must be routed, have controllers & views, and may use models.

In order to include it in the workflow, _menu_entries_ must be defined for the engine. Menu entries are defined in `engines/$ENGINE/lib/$ENGINE.rb` as follows:

```
module SomeEngineName
  def self.menu_entries
    [
      { caption: 'Do a thing', icon: 'manage_accounts', target: '/some_engine_name/do_a_thing' },
      { caption: 'Do something else', icon: 'location_on', target: '/some_engine_name/do_something_else' },
    ]
  end
end
```

`self.menu_entries` should return a list of dictionaries, each defining three attributes:

* `caption:` the text to use on the main menu
* `icon:` the name of the [EOS icon](https://eos-icons.com/) to use on the
main menu
* `target:` the route to the first page of the workflow. _This must include the top-level directory where the engine is mounted, as defined in `config/routes.rb`._

**Translations** should be provided under the `engines.$ENGINE` namespace.

While the web content of a component is defined exclusively by the engine, there are some user interface _conventions_ defined; complying with application UI conventions provides a consistent experience for end users.

Page views should adhere to the following template:

```
= page_header(t('engines.$ENGINE.$MENU_ENTRY.title'))
-# body
YOUR CONTENT HERE
-# end
= render('layouts/navigation_buttons') do
  = previous_step_button()
  = next_step_button()
```

### UI style

_suse-rancher-setup_ uses and conforms to the [EOS Design System](https://suse.eosdesignsystem.com/).

## Engine Notes

### AWS

In order to comply with AWS Marketplace requirements, the AWS module does not prompt for credentials. In order to use AWS via this application, it must be run either on an EC2 instance with an assigned IAM machine role, or credentials must be configured locally in `~/.aws/credentials`.

## Workflow Notes

### Rancher on EKS

The minimum IAM permissions required to run the _Rancher on EKS_ workflow are provided as [aws-iam/iam_role.json](aws-iam/iam_role.json).

## Packaging

_suse-rancher-setup_ includes supporting tools and documents to build on an open build service (OBS) instance, such as https://build.opensuse.org

**⚠ Note:** before packaging or running in production mode, session storage secrets must be generated and provided as:
* config/credentials.yml.enc
* config/master.key

These files can be generated using `bin/rails credentials:edit` and are ignored by _git_. We recommend storing the key in a secure location.

### New dependencies

When updating dependencies, add a categorized entry with a comment, in Gemfile.development.

_Please note any new external CLI dependencies in this documentation._

Gems _must_ be included with the _ruby_ framework target; OBS will not accept prebuilt libraries included in gems (like _nokogiri_ and _sqlite3_ ). I recommend using the following _bundler_ config (`.bundle/config`):

```
---
BUNDLE_BUILD__SQLITE3: "--enable-system-libraries"
BUNDLE_FORCE_RUBY_PLATFORM: "true"
BUNDLE_CACHE_ALL: "false"
```

### Releases

Update the [changelog](packaging/suse-rancher-setup.changes) for the expected release version, and stage it for _git_.

**💡 Hint:** You can use `bin/vc` to get the proper format for changelogs, assuming you have [_osc_](https://software.opensuse.org/package/osc) installed.


[bumpversion](https://pypi.org/project/bumpversion/) is used to tag releases; the `--allow-dirty` flag will include the _changelog_ in the version bump commit.

```
bumpversion [major|minor|patch] --allow-dirty
```

### Generating a tarball

1. All steps required for generating a production-ready tarball, including precompiling assets and preparing _bootsnap_ caches, are included in the Makefile task:
  ```
  make dist
  ```
2. Copy the specfile and move the tarball to an OBS project dir
  ```
  cp packaging/* path/of/your/project/
  mv *.tar* path/of/your/project/
  ```

## License

Copyright © 2022 SUSE LLC.
Distributed under the terms of GPL-3.0+ license, see [LICENSE](LICENSE) for details.
