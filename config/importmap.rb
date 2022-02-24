# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin "jquery", to: "jquery.slim.min.js" # @3.6.0
pin "bootstrap", to: "bootstrap.bundle.min.js" # @4.6.1
pin "eos-ds", to: "eos-ds.js"
pin "trix"
pin "@rails/actiontext", to: "actiontext.js"
