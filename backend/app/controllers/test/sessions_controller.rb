module Test
  class SessionsController < ActionController::API
    include ActionController::Cookies

    def create
      session[:user_id] = params[:user_id]
      head :no_content
    end
  end
end
