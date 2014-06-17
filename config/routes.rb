ActionController::Routing::Routes.draw do |map|
  map.resources :gizmo_type_groups

  map.resources :users
  map.resource :session

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

#  map.root :controller => "soap", :conditions => { :method => :post, :soap => true } # this will be used again in rails 3's metals.
  map.root :controller => "sidebar_links", :action => "fgss_moved", :conditions => {:host => /^(printme|fgss|rocky)(.fglan)?$/i}
  map.root :controller => "sidebar_links", :action => "staffsched_moved", :conditions => {:host => /^(bullwinkle)(.fglan)?$/i}
  map.root :controller => "sidebar_links"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect 'api/:namespace/:method', :controller => "api", :action => "handle"
  map.connect 'api/:namespace/:method/:request', :controller => "api", :action => "handle"
  map.connect 'admin/:model', :controller => "admin", :action => "index"
  map.connect 'admin/:model/:action/:id', :controller => "admin"
  map.connect 'admin/:model/:action', :controller => "admin"
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'



  map.connect 'barcode/:id.:format', :controller => "barcode", :action => "barcode"

  map.connect 'todo', :controller => "sidebar_links", :action => "todo_moved"
  map.connect 'mail', :controller => "sidebar_links", :action => "mail_moved"
  map.connect 'deadtrees', :controller => "sidebar_links", :action => "deadtrees_moved"
  map.connect 'dead trees', :controller => "sidebar_links", :action => "deadtrees_moved"

  map.connect 'supplies', :controller => "sidebar_links", :action => "supplies_moved"
  map.connect 'recent_crash', :controller => "sidebar_links", :action => "recent_crash"

  map.connect 'staffsched', :controller => "work_shifts", :action => "staffsched"
  map.connect 'schedule', :controller => "work_shifts", :action => "staffsched"
  map.connect 'staff_sched', :controller => "work_shifts", :action => "staffsched"
  map.connect 'staffschedule', :controller => "work_shifts", :action => "staffsched"
  map.connect 'worksched', :controller => "work_shifts", :action => "staffsched"

  map.connect 'build', :controller => "spec_sheets"

# try levenshtein maybe, on 404 routing failure?
#  map.connect 'gizmo_return'
#  map.connect 'metings'
end
