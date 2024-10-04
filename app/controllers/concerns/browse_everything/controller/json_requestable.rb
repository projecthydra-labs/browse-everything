# frozen_string_literal: true

module BrowseEverything
  module Controller
    module JsonRequestable
      extend ActiveSupport::Concern

      private

        # Determines if the Controller received a JSON API request
        def json_api_request?
          mime_type = Mime::Type.lookup_by_extension(:json_api)
          request.content_type == mime_type.to_s
        end

        def json_api_params
          return unless json_api_request?

          request.body.rewind
          body_content = request.body.read
          payload = JSON.parse(body_content)
          ActionController::Parameters.new(payload)
        end

        def resource_json_api_attributes
          data_params = json_api_params[:data]
          return unless data_params

          data_params[:attributes]
        end
    end
  end
end
