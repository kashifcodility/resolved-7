# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "main", to: "old/main.js", preload: true
pin "waypoint", to: "old/jquery-waypoints-min.js", preload: true
pin "scrolling", to: "old/infinite-scrolling.js", preload: true
pin "elements", to: "old/ui-elements.js", preload: true
pin "testimonials", to: "old/testimonials.js", preload: true
pin "warning", to: "old/warning.js", preload: true
pin "header", to: "old/header.js", preload: true
pin "routes", to: "routes.js"

pin_all_from "app/javascript/controllers", under: "controllers"
