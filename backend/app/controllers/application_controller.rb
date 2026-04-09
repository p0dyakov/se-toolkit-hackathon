class ApplicationController < ActionController::API
  include ActionController::Cookies

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def current_user
    @current_user ||= current_user_from_bearer_token || User.find_by(id: session[:user_id])
  end

  def authenticate_user!
    return if current_user.present?

    render json: { error: "unauthorized" }, status: :unauthorized
  end

  def render_not_found
    render json: { error: "not_found" }, status: :not_found
  end

  def current_user_from_bearer_token
    token = request.authorization.to_s.delete_prefix("Bearer ").strip
    return if token.blank? || token == request.authorization

    User.find_by_api_key(token)
  end
end
