# Spree::Core::Engine.routes.draw do
#   post '/enets', to: "enets#index", as: :enets_proceed
#   post '/enets/:pid/callback', to: "enets#callback", as: :enets_callback
#   get '/enets/:pid/confirm', to: "enets#confirm", as: :enets_confirm
#   get '/enets/:pid/cancel', to: "enets#cancel", as: :enets_cancel
# end

Spree::Core::Engine.add_routes do
  post '/enets', to: "enets#index", as: :enets_proceed
  post '/enets/callback', to: "enets#callback", as: :enets_callback
  post '/enets/confirm', to: "enets#confirm", as: :enets_confirm
  post '/enets/cancel', to: "enets#cancel", as: :enets_cancel
end
