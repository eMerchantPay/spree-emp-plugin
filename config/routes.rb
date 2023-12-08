Spree::Core::Engine.routes.draw do
  get 'emerchantpay_threeds/:unique_id/:checksum' => :index, controller: :emerchantpay_threeds,
      as: :emerchantpay_threeds_form

  namespace :api do
    namespace :v2 do
      namespace :storefront do

        post 'emerchantpay_notification' => :index, controller: :emerchantpay_notification,
             as: :emerchantpay_notification

        post 'emerchantpay_threeds/status' => :callback_handler, controller: :emerchantpay_threeds,
             as: :emerchantpay_threeds_callback_handler

        get 'emerchantpay_threeds/status/:unique_id' => :callback_status, controller: :emerchantpay_threeds,
            as: :emerchantpay_threeds_callback_status

        post 'emerchantpay_threeds/method_continue' => :method_continue, controller: :emerchantpay_threeds,
             as: :emerchantpay_threeds_secure_continue

      end
    end
  end
end
