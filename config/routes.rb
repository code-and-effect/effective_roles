EffectiveRoles::Engine.routes.draw do
  namespace :admin do
    resources :roles, only: [:index]
  end
end

Rails.application.routes.draw do
  mount EffectiveRoles::Engine => '/', as: 'effective_roles'
end
