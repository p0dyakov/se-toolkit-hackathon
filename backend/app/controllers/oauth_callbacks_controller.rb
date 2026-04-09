class OauthCallbacksController < ApplicationController
  def google
    auth = request.env["omniauth.auth"]

    if auth.blank?
      redirect_to failure_redirect_url("missing_oauth_payload"), allow_other_host: true
      return
    end

    user = User.find_or_initialize_by(google_uid: auth.uid)
    user.assign_attributes(
      email: auth.info.email,
      name: auth.info.name.presence || auth.info.email,
      avatar_url: auth.info.image
    )
    user.save!

    session[:user_id] = user.id

    redirect_to success_redirect_url, allow_other_host: true
  end

  def failure
    redirect_to failure_redirect_url(params[:message] || "oauth_failed"), allow_other_host: true
  end

  private

  def success_redirect_url
    frontend_url = ENV.fetch("FRONTEND_URL", "http://localhost:5173")
    "#{frontend_url}/auth/success"
  end

  def failure_redirect_url(message)
    frontend_url = ENV.fetch("FRONTEND_URL", "http://localhost:5173")
    "#{frontend_url}/auth/error?message=#{CGI.escape(message.to_s)}"
  end
end
