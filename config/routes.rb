Spree::Core::Engine.routes.draw do
  post '/enets', to: "enets#index", as: :enets_proceed
  get '/enets/:pid/callback', to: "enets#callback", as: :enets_callback
  get '/enets/:pid/confirm', to: "enets#confirm", as: :enets_confirm
  get '/enets/:pid/cancel', to: "enets#cancel", as: :enets_cancel
end
