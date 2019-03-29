Spree::Core::Engine.add_routes do
  post '/enets', to: "enets#index", as: :enets_proceed
  post '/enets/:pid/callback', to: "enets#callback", as: :enets_callback
  post '/enets/:pid/confirm', to: "enets#confirm", as: :enets_confirm
  post '/enets/:pid/cancel', to: "enets#cancel", as: :enets_cancel
end
