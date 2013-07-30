class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_filter :configure_permitted_parameters, if: :devise_controller?

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.html do
        if current_user.nil? # user is unauthorized because he/she is not logged in
          session[:next] = request.fullpath
          redirect_to new_user_session_path, :alert => "Please log in to continue."
        else
          if request.env["HTTP_REFERER"].present?
            redirect_to :back, :alert => exception.message
          else
            render :file => "#{Rails.root}/public/403.html", :status => 403, :layout => false
          end
        end
      end

      format.json do
        # Show authorization error using JSON format
        render json: { status: 403, message: "You are not allowed to access this resource." } , status: :forbidden
      end
    end
  end
 
  protected
 
  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_in) do |u|
    	u.permit(:username, :email)
    end
    devise_parameter_sanitizer.for(:sign_up) do |u|
      u.permit(:name, :email, :password, :password_confirmation)
    end
    devise_parameter_sanitizer.for(:account_update) do |u|
      u.permit(:name, :email, :password, :password_confirmation, :current_password)
    end
  end
end
