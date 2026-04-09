class OpenapiController < ActionController::Base
  def show
    document = JSON.parse(Rails.root.join("openapi", "v1", "openapi.json").read)
    document["servers"] = [{ "url" => request.base_url }]

    render json: document
  end
end
