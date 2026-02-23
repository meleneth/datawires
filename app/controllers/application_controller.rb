class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  DEV_USER_ID = "18ed5b72-a961-486e-a6f3-fbdd8c8e2398".freeze

  private

  def current_user
    @current_user ||= User.find_or_create_by!(id: DEV_USER_ID) do |user|
      user.name = "devUser"
      user.avatar_url = "https://api.dicebear.com/7.x/pixel-art/png?seed=devUser"
    end
  end

  helper_method :current_user
end
