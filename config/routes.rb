Rails.application.routes.draw do
  resource :schedules, controller: 'schedules', only: [], defaults: { format: :json } do
    get :list
    get :list_by_date
    get :list_by_number_room
    get :list_by_date_and_number_room
    get :find_schedule
    post :create_schedule
    put :update_schedule
    delete :destroy_schedule
  end
end
