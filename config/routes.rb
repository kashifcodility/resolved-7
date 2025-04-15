# Rails.application.routes.draw do

#   get "up" => "rails/health#show", as: :rails_health_check

 
#   get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
#   get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

# end




# coding: utf-8
# Docs: https://guides.rubyonrails.org/routing.html
#  require 'sidekiq/web'
Rails.application.routes.draw do
  devise_for :users
  namespace :api do
      namespace :v1 do
        resources :orders, only: [:create]
      end
  end
  resources :order_status_signatures, only: [:new, :create]
 
  Rails.application.routes.draw do
  # mount Sidekiq::Web => '/sidekiq'
  # Other routes
  end
  root "root#index"
  # Session
  get  'signup',                      to: 'sessions#signup',                    as: 'signup_form'
  post 'signup',                      to: 'sessions#create_account',            as: 'signup'
  get  'login',                       to: 'sessions#login',                     as: 'login_form'
  post 'login',                       to: 'sessions#create',                    as: 'login'
  get  'logout',                      to: 'sessions#logout',                    as: 'logout'
  get  'forgot_password',             to: 'sessions#forgot_password',           as: 'forgot_password'
  post 'forgot_password',             to: 'sessions#send_reset_password_email', as: 'send_reset_password'
  get  'reset_password',              to: 'sessions#reset_password',            as: 'reset_password'
  post 'reset_password',              to: 'sessions#update_password',           as: 'update_password'
  get  'session/destroy',             to: 'sessions#destroy',                   as: 'destroy_session'
  get  'session/change_location/:id', to: 'sessions#change_location',           as: 'change_location'

  # Information
  get  'about',         to: 'info#index',                   as: 'about'
  get '/delete_room/:id',      to: 'rooms#destroy',          as: 'remove_room'
  get  '/new_room',     to: 'rooms#new',                    as: 'new_room'
  get  '/rooms',        to: 'rooms#index',                  as: 'all_rooms'
  get  '/rooms/:id/edit',  to: 'rooms#edit',                as: 'edit_room'
  post  '/create_room',    to: 'rooms#create',              as: 'create_room'
  post  '/sort_rooms',    to: 'rooms#sort',                 as: 'sort_rooms'
  put  '/update_room',     to: 'rooms#update',              as: 'update_room'
  post 'request_info',  to: 'info#send_request_info_email', as: 'send_request_info'
  get  'contact',       to: 'info#contact',                 as: 'contact'
  get  'faq',           to: redirect('https://resources.r-e-solved.com/faq'), as: 'faq'
  get  'privacy',       to: 'info#privacy_policy',          as: 'privacy'
  get  'services',      to: 'info#services',                as: 'services'
  get  'covid',         to: 'info#covid',                   as: 'covid_19'
  get  'policies',      to: 'info#policies',                as: 'policies'
  get  'moi',           to: 'info#moi_policy',              as: 'moi'
  get  'warehousesale', to: redirect('https://resources.r-e-solved.com/warehouse-sale')

  # Products
  get 'products/autocomplete',   to: 'products#autocomplete',   as: 'autocomplete'
  get 'products/autocomplete_bins',   to: 'products#autocomplete_bins',   as: 'autocomplete_bins'
  get 'products',                to: 'products#index',          as: 'plp'
  get 'products/search_suggest', to: 'products#search_suggest', as: 'search_suggest'
  get 'products/rooms',          to: 'products#rooms',          as: 'rooms'
  get 'products/category',       to: 'products#category',       as: 'pcp'
  get 'products/:id',            to: 'products#show',           as: 'pdp'
  get 'products/:id/barcode',    to: 'products#barcode',        as: 'barcode'
  

  # In-Home Sales
  get  'inhome/:id',            to: 'inhome#index',       as: 'ihs_plp'
  post 'inhome/:id/checkout',   to: 'inhome#add_to_cart', as: 'ihs_addtocart'
  get  'inhome/:id/checkout',   to: 'inhome#checkout',    as: 'ihs_checkout'
  post 'inhome/:id/process',    to: 'inhome#transact',    as: 'ihs_transact'
  get  'inhome/:id/coversheet', to: 'inhome#coversheet',  as: 'ihs_coversheet'

  # Checkout/billing
  get  'cart',              to: 'cart#index',                     as: 'cart'
  get  'cart/preview',      to: 'cart#preview',                   as: 'cart_preview'
  post 'cart',              to: 'cart#create',                    as: 'add_to_cart'
  post '/update_items_quantity', to: 'cart#update_items_quantity', as: 'update_items_quantity'
  post '/update_cart',      to: 'cart#update_cart',               as: 'update_cart'
  get  'cart/:id/remove',   to: 'cart#destroy',                   as: 'remove_from_cart'
  get  'cart/empty',        to: 'cart#empty',                     as: 'empty_cart'
  get  'checkout',          to: 'cart#checkout_form',             as: 'checkout_form'
  post 'checkout',          to: 'cart#checkout_form_handler',     as: 'checkout_form_handler'
  post 'add_items_to_order', to: 'root#add_items_to_order',       as: 'add_items_to_order'
  # get  'checkout',          to: 'cart#checkout_billing',          as: 'checkout'
  # post 'checkout',          to: 'cart#checkout_billing_handler',  as: 'checkout_handler'
  get  'checkout/delivery', to: 'cart#checkout_delivery',         as: 'checkout_delivery'
  post 'checkout/delivery', to: 'cart#checkout_delivery_handler', as: 'checkout_delivery_handler'
  get  'checkout/review',   to: 'cart#checkout_review',           as: 'checkout_review'
  post 'checkout/process',  to: 'cart#checkout_process',          as: 'checkout_process'
  get  'checkout/receipt',  to: 'cart#checkout_receipt',          as: 'checkout_receipt'

  # Account - profile
  get  'account',                           to: 'account#index',                         as: 'account'
  post 'account/edit_profile',              to: 'account#edit_profile_handler',          as: 'account_edit_profile'
  get  'account/remove_payment_method/:id', to: 'account#remove_payment_method_handler', as: 'remove_payment_method'
  get  'account/set_default_location/:id',  to: 'account#set_default_location_handler',  as: 'set_default_location'
  get  'account/new_card',                  to: 'account#new_credit_card',               as: 'new_credit_card'
  post 'account/create_credit_card',        to: 'account#create_credit_card',            as: 'create_credit_card'
  get  'account/new_bin',                   to: 'account#new_bin',                        as: 'new_bin'
  post 'account/create_bin',                to: 'account#create_bin',                            as: 'create_bin'
  post 'account/set_default_credit_card',   to: 'account#set_default_credit_card',       as: 'set_default_credit_card'
  get  'account/update_password',           to: 'account#new_password',                  as: 'account_new_password'
  post 'account/update_password',           to: 'account#update_password',               as: 'account_update_password'

  # Account - orders
  get  'account/orders',                                   to: 'account#orders',                    as: 'account_orders'
  get  'account/orders/:id',                               to: 'account#order_show',                as: 'account_order'
  post 'account/orders/:id/change_room',                   to: 'account#order_change_product_room', as: 'project_update_product_room'
  get  'account/orders/:id/change_room/:line_id/:room_id', to: 'account#order_change_product_room', as: 'order_change_product_room'
  post 'account/orders/:id/void_line',                     to: 'account#order_void_line',           as: 'order_void_line'
  post 'account/orders/add_to_order',                      to: 'account#order_add_products',        as: 'add_to_order'
  get  'account/orders/:id/cancel',                        to: 'account#order_cancel',              as: 'cancel_order'
  get  'account/orders/:ids/receipt',                      to: 'account#order_receipt',             as: 'order_receipt'
  get  'account/orders/:ids/invoice',                      to: 'account#order_invoice',             as: 'order_invoice'
  get  'account/orders/:ids/invoice_sale',                 to: 'account#order_invoice_sale',        as: 'order_invoice_sale'
  get  'account/orders/:ids/items_list_receipt',           to: 'account#orders_items_list_receipt', as: 'orders_items_list_receipt'
  post 'account/orders/:ids/receipt',                      to: 'account#order_receipt_grouped',     as: 'order_receipt_grouped'
  post 'account/orders/:id/request_destage',               to: 'account#order_request_destage',     as: 'request_destage'
  post 'account/orders/:id/update_credit_card',            to: 'account#order_update_credit_card',  as: 'update_order_credit_card'
  get  'account/orders/:id/ordered_date',                  to: 'account#ordered_date',              as: 'ordered_date'

  get  '/project_estimations/estimations_pdf',             to: 'project_estimations#estimations_pdf',       as: 'estimations_pdf'
  get  '/project_estimations/project_proposal_pdf',        to: 'project_estimations#project_proposal_pdf',       as: 'project_proposal_pdf'
  get  '/project_estimations/load',                        to: 'project_estimations#load',       as: 'load'
  get  'project_estimations/client_estimation',            to: 'project_estimations#estimation_form',               as: 'client_estimation'
  post 'project_estimations/create_estimation',            to: 'project_estimations#create_estimation',            as: 'create_estimation'
  # Projects
  get  'projects',     to: 'account#orders',       as: 'projects'
  get  'projects/:id', to: 'account#order_show',   as: 'project'
  post 'projects/:id', to: 'account#order_update', as: 'update_project'
  post 'projects/:id/add_query', to: 'account#add_query', as: 'add_project_query'

  # Invoice
  get 'account/invoice', to: 'account#invoice', as: 'invoices'

  # Account - accounting
  get  'account/accounting',                       to: 'account#accounting',                       as: 'account_accounting'
  get  'account/accounting/rental_income_summary', to: 'account#accounting_rental_income_summary', as: 'account_accounting_rental_income_summary'
  get  'account/income',                           to: 'account#accounting_income',                as: 'account_accounting_income'
  get  'account/payments',                         to: 'account#accounting_payments',              as: 'account_accounting_payments'

  # Account - Receipts
  get  'account/receipt/',                               to: 'account#receipt_by_id',                as: 'receipt_by_id'

  # Account - inventory
  get    'account/inventory',               to: 'account#inventory',                 as: 'account_inventory'
  post   'account/inventory/favorite',      to: 'account#create_inventory_favorite', as: 'create_favorite'
  delete 'account/inventory/favorite',      to: 'account#remove_inventory_favorite', as: 'remove_favorite'
  post   'account/inventory/update_status', to: 'account#inventory_status_update',   as: 'update_inventory_status'
  post   '/create_rating',                  to: 'ratings#create',                    as: 'create_rating'

  get   'cms/about',                  to: 'cms#about', as: 'cms_about'
  put   'cms/about/update',           to: 'cms#update_about', as: 'cms_updates_about'
  get   'cms',                        to: 'cms#index', as: 'cms'
  get   'cms/homepage',               to: 'cms#homepage', as: 'cms_homepage'
  put   'cms/homepage/update',        to: 'cms#update_homepage', as: 'cms_updates_homepage'

  get  'delivery_appointments/new_delivery_appointment',    to: 'delivery_appointments#new_delivery_appointment', as: 'new_delivery_appointment'
  get  'delivery_appointments/edit_delivery_appointment/:id',    to: 'delivery_appointments#edit', as: 'edit_delivery_appointment'
  get  '/delivery_appointments',    to: 'delivery_appointments#index', as: 'delivery_appointments'
  post 'delivery_appointments/create', to: 'delivery_appointments#create', as: 'create_delivery_appointment'
  put 'delivery_appointments/update', to: 'delivery_appointments#update', as: 'update_delivery_appointment'

# quickbooks urls

  # get 'quickbooks/authenticate', to: 'quickbooks#authenticate'
  # get 'quickbooks/oauth_callback', to: 'quickbooks#oauth_callback'

  # resources :users do
      # member do
        get 'quickbooks_authenticate' , to: 'quickbooks#quickbooks_authenticate' , as: 'quickbooks_authenticate'
          # get 'quickbooks/oauth_callback', to: 'quickbooks#oauth_callback', as: 'quickbooks_oauth_callback'
          get 'quickbooks/oauth_callback', to: 'quickbooks#oauth_callback', as: 'quickbooks_oauth_callback'

      # end
  #   end

# projet walk through

  get '/project_walk_through/generate_pdf', to: 'project_walk_through#generate_pdf', format: :pdf
  get '/project_walk_through/step1', to: 'project_walk_through#step1'
  post '/project_walk_through/create_step1', to: 'project_walk_through#create_step1'
  get '/project_walk_through/step2', to: 'project_walk_through#step2'
  post '/project_walk_through/create_step2', to: 'project_walk_through#create_step2'
  get '/project_walk_through/step3', to: 'project_walk_through#step3'
  post '/project_walk_through/create_step3', to: 'project_walk_through#create_step3'
  get '/project_walk_through/step4', to: 'project_walk_through#step4'
  post '/project_walk_through/create_step4', to: 'project_walk_through#create_step4'
  get '/project_walk_through/step5', to: 'project_walk_through#step5'
  post '/project_walk_through/create_step5', to: 'project_walk_through#create_step5'
  get '/project_walk_through/step6', to: 'project_walk_through#step6'
  post '/project_walk_through/create_step6', to: 'project_walk_through#create_step6'
  get '/project_walk_through/step7', to: 'project_walk_through#step7'
  post '/project_walk_through/create_step7', to: 'project_walk_through#create_step7'
  get '/project_walk_through/step8', to: 'project_walk_through#step8'
  post '/project_walk_through/create_step8', to: 'project_walk_through#create_step8'
  get '/project_walk_through/step9', to: 'project_walk_through#step9'
  post '/project_walk_through/create_step9', to: 'project_walk_through#create_step9'
  get '/project_walk_through/step10', to: 'project_walk_through#step10'
  post '/project_walk_through/create_step10', to: 'project_walk_through#create_step10'
  get '/project_walk_through/step11', to: 'project_walk_through#step11'
  post '/project_walk_through/create_step11', to: 'project_walk_through#create_step11'
  get '/project_walk_through/step12', to: 'project_walk_through#step12'
  post '/project_walk_through/create_step12', to: 'project_walk_through#create_step12'
  get '/project_walk_through/step13', to: 'project_walk_through#step13'
  post '/project_walk_through/create_step13', to: 'project_walk_through#create_step13'
  get '/project_walk_through/step14', to: 'project_walk_through#step14'
  post '/project_walk_through/create_step14', to: 'project_walk_through#create_step14'
  get '/project_walk_through/step15', to: 'project_walk_through#step15'
  post '/project_walk_through/create_step15', to: 'project_walk_through#create_step15'
  get '/project_walk_through/step16', to: 'project_walk_through#step16'
  post '/project_walk_through/create_step16', to: 'project_walk_through#create_step16'
  get '/project_walk_through/step17', to: 'project_walk_through#step17'
  post '/project_walk_through/create_step17', to: 'project_walk_through#create_step17'
  get '/project_walk_through/download/:filename', to: 'project_walk_through#download', as: :project_walk_through_download

end

