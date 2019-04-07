EffectiveDatatables::Engine.routes.draw do
  scope :module => 'effective' do
    get 'datatables/i18n/:language', to: 'datatables#i18n'
    match 'datatables/:id(.:format)', to: 'datatables#show', via: [:get, :post], as: :datatable
    match 'datatables/:id/reorder(.:format)', to: 'datatables#reorder', via: [:post], as: :reorder_datatable
  end
end

Rails.application.routes.draw do
  mount EffectiveDatatables::Engine => '/', :as => 'effective_datatables'
end
