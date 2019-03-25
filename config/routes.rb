Spree::Core::Engine.routes.draw do
  post "/enets/pay", to: "enets#pay"
  get "/enets/failure", to: "enets#failure"
  get "/enets/success", to: "enets#success"
  get "/enets/cancel", to: "enets#cancel"
end
