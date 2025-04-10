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
pin "routes", to: "routes.js",preload: true
pin "checkout", to: "old/checkout.js",preload: true
pin "add_review", to: "old/add_review.js",preload: true
pin "checkout_review", to: "old/checkout_review.js",preload: true
pin "edit_project_name", to: "old/edit_project_name.js",preload: true
pin "edit_stage_info", to: "old/edit_stage_info.js",preload: true
pin "global_functions", to: "old/global_functions.js",preload: true
pin "project_detail_page", to: "old/project_detail_page.js",preload: true
pin "user_account", to: "old/user_account.js",preload: true


pin_all_from "app/javascript/controllers", under: "controllers"
