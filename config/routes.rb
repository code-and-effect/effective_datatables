Rails.application.routes.draw do
  mount EffectiveDatatables::Engine => '/', :as => 'effective_datatables'
end

EffectiveDatatables::Engine.routes.draw do
  scope :module => 'effective' do
    resources :datatables, :only => [:show]
  end
end


