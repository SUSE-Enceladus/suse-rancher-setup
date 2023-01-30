NAME          = suse-rancher-setup
VERSION       = $(shell ruby -e 'require "./lib/suse-rancher-setup.rb"; print SUSERancherSetup::VERSION')

all:
	@:

clean:
	rm -rf *.tar.bz2
	rm -rf $(NAME)-$(VERSION)/

dist: clean
	@mkdir -p $(NAME)-$(VERSION)/

	@cp -r app $(NAME)-$(VERSION)/
	@cp -r aws-iam $(NAME)-$(VERSION)/
	@mkdir $(NAME)-$(VERSION)/bin
	@cp -r bin/rails $(NAME)-$(VERSION)/bin
	@cp -r config $(NAME)-$(VERSION)/
	@mkdir $(NAME)-$(VERSION)/db
	@cp -r db/migrate $(NAME)-$(VERSION)/db
	@cp -r db/schema.rb $(NAME)-$(VERSION)/db
	@cp -r engines $(NAME)-$(VERSION)/
	@cp -r lib $(NAME)-$(VERSION)/
	@mkdir $(NAME)-$(VERSION)/log
	@cp -r log/.keep $(NAME)-$(VERSION)/log
	@cp -r public $(NAME)-$(VERSION)/
	@mkdir $(NAME)-$(VERSION)/tmp
	@cp -r tmp/.keep $(NAME)-$(VERSION)/tmp
	@cp -r vendor $(NAME)-$(VERSION)/
	@cp -r config.ru $(NAME)-$(VERSION)/
	@cp -r Gemfile $(NAME)-$(VERSION)/
	@cp -r Gemfile.lock $(NAME)-$(VERSION)/
	@cp -r LICENSE $(NAME)-$(VERSION)/
	@cp -r Rakefile $(NAME)-$(VERSION)/
	@cp -r README.md $(NAME)-$(VERSION)/
	@cp -r server-configs $(NAME)-$(VERSION)/

	# don't bundle external config
	@rm -f $(NAME)-$(VERSION)/config/config.yml

	# don't bundle supportconfig files
	@rm -f $(NAME)-$(VERSION)/public/scc_*

	# don't package engine bin directory, specs (no need) and .gitignore (OBS complains)
	@rm -rf $(NAME)-$(VERSION)/engines/*/bin
	@rm -rf $(NAME)-$(VERSION)/engines/*/test
	@rm -rf $(NAME)-$(VERSION)/engines/*/.gitignore

	# vendor the gem dependencies
	@cd $(NAME)-$(VERSION) && bundle cache

	# bundler hacks
	@sed -i '/source .*rubygems\.org/d' $(NAME)-$(VERSION)/Gemfile
	@sed -i '/remote: .*rubygems\.org/d' $(NAME)-$(VERSION)/Gemfile.lock

	# generate session secret
	@cd $(NAME)-$(VERSION) && EDITOR=cat rails credentials:edit

	# prebuild the database
	@cd $(NAME)-$(VERSION) && RAILS_ENV=production rails db:reset

	# compile assets
	@cd $(NAME)-$(VERSION) && RAILS_ENV=production rails assets:precompile

	# clean up the tmp directory
	@cd $(NAME)-$(VERSION) && rails tmp:clear

	# tidy any editor tmp files
	@find $(NAME)-$(VERSION) -name \*~ -exec rm {} \;

	# package it up, already
	@tar cfvj $(NAME)-$(VERSION).tar.bz2 $(NAME)-$(VERSION)/
	@rm -rf $(NAME)-$(VERSION)/
