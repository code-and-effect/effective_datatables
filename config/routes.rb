EffectiveDatatables::Engine.routes.draw do
  scope :module => 'effective' do
    match 'datatables/:id(.:format)', to: 'datatables#show', via: [:get, :post], as: :datatable
  end
end

Rails.application.routes.draw do
  mount EffectiveDatatables::Engine => '/', :as => 'effective_datatables'
end
