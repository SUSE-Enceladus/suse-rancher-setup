# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin "jquery", to: "jquery.min.js" # @3.6.0
pin "bootstrap", to: "bootstrap.bundle.min.js" # @4.6.1
pin "eos-ds", to: "eos-ds.js"
