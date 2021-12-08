EffectiveDatatables::Engine.routes.draw do
  scope :module => 'effective' do
    match 'datatables/:id(.:format)', to: 'datatables#show', via: [:get, :post], as: :datatable
    match 'datatables/:id/reorder(.:format)', to: 'datatables#reorder', via: [:post], as: :reorder_datatable
    match 'datatables/:id/download(.:format)', to: 'datatables#download', via: :get, as: :download_datatable
  end
end

Rails.application.routes.draw do
  mount EffectiveDatatables::Engine => '/', :as => 'effective_datatables'
end
