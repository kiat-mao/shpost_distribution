ShpostDistribution::Application.routes.draw do
  # resources :order_detail_logs

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
  root 'welcome#index'

  devise_for :users, controllers: { sessions: "users/sessions" }

  resources :user_logs, only: [:index, :show, :destroy]

  resources :units do
    resources :users, :controller => 'unit_users'
  end

  resources :users do
    member do
      get 'to_reset_pwd'
      patch 'reset_pwd'
      post 'lock' => 'users#lock'
      post 'unlock' => 'users#unlock'
    end
    resources :roles, :controller => 'user_roles'
  end

  resources :up_downloads do
    collection do 
      get 'up_download_import'
      post 'up_download_import' => 'up_downloads#up_download_import'
      
      get 'to_import'
      
      
    end
    member do
      get 'up_download_export'
      post 'up_download_export' => 'up_downloads#up_download_export'
    end
  end

  resources :import_files do
    collection do
      get 'image_index'
    end
    
    member do 
      get 'download'
      post 'download' => 'import_files#download'
    end
  end

  resources :suppliers do
    collection do 
      get 'supplier_import'
      post 'supplier_import' => 'suppliers#supplier_import'
      
    end

    member do
      get 'set_valid'
      get 'contracts_upload'
      post 'contracts_upload' => 'suppliers#contracts_upload'
      get 'contracts_show'
    end
  end

  resources :commodities do
    collection do 
      get 'commodity_import'
      post 'commodity_import' => 'commodities#commodity_import'
    end

    member do
      get 'cover_upload'
      post 'cover_upload' => 'commodities#cover_upload'
      get 'cover_show'
      get 'set_on_sell'
    end
  end

  resources :supplier_autocom do
    collection do
      get 'c_autocomplete_supplier_name'
        
    end
  end

  resources :orders do
    collection do
      get 'fresh'
      get 'pending'
      get 'checking'
      get 'declined'
      get 'rechecking'
      get 'receiving'
      get 'look'
    end

    # resources :order_details, only: [:index, :new, :create]
    # resources :order_details do
    #   collection do
    #     get 'pending'
    #     get 'checking'
    #     get 'declined'
    #     get 'rechecking'
    #     get 'receiving'
    #   end
    # end

    member do
      get 'commodity_choose'
      get 'to_check'
      post 'to_recheck'
      post 'check_decline'
      post 'place'
      post 'recheck_decline'
      post 'confirm'
    end
  end


  resources :order_details do
    resources :order_detail_logs, only: [:index]
    collection do
      # get 'order_details' => 'order_details#index'
      get 'pending'
      get 'checking'
      get 'declined'
      get 'rechecking'
      get 'receiving'
      get 'look'
      get 'readlog'
    end
    member do
      # get 'edit'
      post 'to_check'
      post 'to_recheck'
      post 'check_decline'
      post 'place'
      post 'recheck_decline'
      post 'confirm'
      post 'cancel'
    end
  end

  match "/shpost_distribution/reports/order_report" => "reports#order_report", via: [:get, :post]
  match "/shpost_distribution/reports/supplier_report" => "reports#supplier_report", via: [:get, :post]
  match "/shpost_distribution/reports/commodity_report" => "reports#commodity_report", via: [:get, :post]
  match "/shpost_distribution/reports/unit_report" => "reports#unit_report", via: [:get, :post]

end
