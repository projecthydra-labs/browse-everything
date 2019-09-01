require 'google/apis/drive_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'

module BrowseEverything
  class Provider

    # The Providers class for interfacing with Google Drive as a storage provider
    class GoogleDrive < BrowseEverything::Provider

      # Determine whether or not a Google Drive resource is a Folder
      # @return [Boolean]
      def self.folder?(gdrive_file)
        file.mime_type == 'application/vnd.google-apps.folder'
      end

      def find_bytestream(id:)
        batch_request_path(id)
      end

      def find_container(id:)
        batch_request_path(id)
      end

      def root_container
        batch_request_path
      end

      # Provides a URL for authorizing against Google Drive
      # @return [String] the URL
      def authorization_url
        Addressable::URI.parse(authorizer.get_authorization_url)
      end

      # Generate the URL for the API callback
      # Note: this is tied to the routes used for the OAuth callbacks
      # @return [String]
      def callback
        provider_authorize_url(callback_options)
      end

      private

        def build_resource(gdrive_file, bytestream_tree, container_tree)
          location = "key:#{file.id}"
          modified_time = file.modified_time || Time.new

          if self.class.folder?(file)
            bytestream_ids = []
            container_ids = []

            if bytestream_tree.key?(gdrive_file.id)
              bytestream_ids = bytestream_tree[gdrive_file.id]
            end
            if container_tree.key?(gdrive_file.id)
              container_ids = container_tree[gdrive_file.id]
            end

            BrowseEverything::Container.new(
              id: file.id,
              bytestream_ids: bytestream_ids,
              container_ids: container_ids,
              location: location,
              name: file.name,
              mtime: modified_time
            )
          else
            BrowseEverything::Bytestream.new(
              id: file.id,
              location: location,
              name: file.name,
              size: file.size.to_i,
              mtime: modified_time,
              media_type: file.mime_type
            )
          end
        end

        def request_path(drive:, request_params:, path: '')
          resources = []
          container_tree = {}
          bytestream_tree = {}

          drive.list_files(request_params.to_h) do |file_list, error|
            # Raise an exception if there was an error Google API's
            if error.present?
              raise error
            end

            members = file_list.files
            members.map do |gdrive_file|
              # All GDrive Folders have File entries
              if self.class.folder?(gdrive_file)
                container_tree[gdrive_file.id] = []
                bytestream_tree[gdrive_file.id] = []
              end

              if resource_tree.key?(gdrive_file.parents)
                if self.class.folder?(gdrive_file)
                  container_tree[gdrive_file.parents] << gdrive_file.id
                else
                  bytestream_tree[gdrive_file.parents] << gdrive_file.id
                end
              end
            end

            # This ensures that the entire tree is build for the objects
            resources = members.map do |gdrive_file|
              # Here the API responses are parsed into BrowseEverything objects
              build_resource(gdrive_file, bytestream_tree, container_tree)
            end

            request_params.page_token = file_list.next_page_token
          end

          # Recurse if there are more pages of results
          resources += request_path(drive: drive, request_params: request_params, path: path) if request_params.page_token.present?
        end

        def batch_request_path(path = '')
          resources = []

          drive_service.batch do |drive|
            request_params = Auth::Google::RequestParameters.new
            request_params.q += " and '#{path}' in parents " if path.present?
            resources = request_path(drive, request_params, path: path)
          end
          resources
        end

        def config
          values = BrowseEverything.config['google_drive'] || {
            client_id: nil,
            client_secret: nil
          }

          OpenStruct.new(values)
        end

        def client_secrets
          {
            Google::Auth::ClientId::WEB_APP => {
              Google::Auth::ClientId::CLIENT_ID => config.client_id,
              Google::Auth::ClientId::CLIENT_SECRET => config.client_secret
            }
          }
        end

        # Client ID for authorizing against the Google API's
        # @return [Google::Auth::ClientId]
        def client_id
          @client_id ||= Google::Auth::ClientId.from_hash(client_secrets)
        end

        def scope
          Google::Apis::DriveV3::AUTH_DRIVE_READONLY
        end

        # This is required for using the googleauth Gem
        # @see http://www.rubydoc.info/gems/googleauth/Google/Auth/Stores/FileTokenStore FileTokenStore for googleauth
        # @return [Tempfile] temporary file within which to cache credentials
        def file_token_store_path
          Tempfile.new('gdrive.yaml')
        end

        # Token store file used for authorizing against the Google API's
        # (This is fundamentally used to temporarily cache access tokens)
        # @return [Google::Auth::Stores::FileTokenStore]
        def token_store
          Google::Auth::Stores::FileTokenStore.new(file: file_token_store_path)
        end

        def build_user_authorizer
          Google::Auth::UserAuthorizer.new(
            client_id,
            scope,
            token_store,
            callback
          )
        end

        # Authorization Object for Google API
        # @return [Google::Auth::UserAuthorizer]
        def authorizer
          @authorizer ||= build_user_authorizer
        end

        # Provides the user ID for caching access tokens
        # (This is a hack which attempts to anonymize the access tokens)
        # @return [String] the ID for the user
        def user_id
          'browse_everything'
        end

        # The authorization code is retrieved from the session
        # @raise [Signet::AuthorizationError] this error is raised if the authorization is invalid
        def credentials
          authorizer.get_credentials_from_code(user_id: user_id, code: @auth_code)
        end

        # Construct a new object for interfacing with the Google Drive API
        # @return [Google::Apis::DriveV3::DriveService]
        def drive_service
          raise StandardError if auth_code.nil?

          Google::Apis::DriveV3::DriveService.new.tap do |drive_service|
            drive_service.authorization = credentials
          end
        end
    end
  end
end
