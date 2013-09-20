require File.expand_path("config/environment", ENV['RAILS_ROOT'] || File.expand_path("../internal", __FILE__))
require 'rspec/rails'
require 'webmock/rspec'
require 'simplecov'
SimpleCov.start do
  add_filter "/spec/"
end

module BrowserConfigHelper
  def url_options
    {
      protocol: 'http://',
      host: 'browse-everything.example.edu'
    }
  end

  def stub_configuration
    BrowseEverything.configure({
      "file_system" => {
        home: File.expand_path('../fixtures/file_system',__FILE__)
      },
      "box" => {
        client_id: "BoxClientId",
        client_secret: "BoxClientSecret"
      },
      "drop_box" => { 
        app_key: "DropBoxAppKey", 
        app_secret: "DropBoxAppSecret"
      },
      "google_drive" => {
        client_id: "GoogleClientId",
        client_secret: "GoogleClientSecret"
      },
      "sky_drive" => {
        client_id: "SkyDriveClientId",
        client_secret: "SkyDriveClientSecret"
      }
    })
  end

  def unstub_configuration
    BrowseEverything.configure(nil)
  end
end
