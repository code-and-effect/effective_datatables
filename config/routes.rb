Rails.application.routes.draw do
  scope :module => 'effective' do
    resources :datatables, :only => [:show]
  end
end
