module RequestHelpers
  def json_response
    JSON.parse(response.body)
  end

  def session_cookie_for(user)
    post "/test/sign_in/#{user.id}"
    response.headers.fetch("Set-Cookie")
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
