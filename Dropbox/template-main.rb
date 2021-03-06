#!/usr/bin/env ruby
# coding: utf-8
##############################################################################
#
# Copyright (c) 2017 Camera Bits, Inc.  All rights reserved.
#
# Developed by Hayo Baan and Kirk A. Baker
#
##############################################################################

TEMPLATE_DISPLAY_NAME = "Dropbox"

API_KEY     = __OAUTH_API_KEY__
API_SECRET  = __OAUTH_API_SECRET__

##############################################################################

class DropboxConnectionSettings < OAuthConnectionSettings
  include PM::ConnectionSettingsTemplate # This also registers the class as Connection Settings

  def client
    @client ||= DropboxClient.new(@bridge)
  end
end

class DropboxFileUploaderUI < OAuthFileUploaderUI
  def metadata_safe?
    true
  end

  def enable_rename?
    true
  end

  def send_original_default?
    true
  end

  def valid_file_types
    [] # all file types are valid
  end

  def initial_control
    @dropbox_foldername_edit
  end

  def create_controls(dlg)
    super

    create_control(:dropbox_group_box,         GroupBox,    dlg, :label=> "Dropbox:")
    create_control(:dropbox_folder_static,     Static,      dlg, :label=> "Dropbox folder name:")
    create_control(:dropbox_foldername_static, Static,      dlg, :label=> "/", :align=>'right')
    create_control(:dropbox_foldername_edit,   EditControl, dlg, :value=> "", :multiline=>false, :persist=>true)
    create_control(:dropbox_overwrite_check,   CheckBox,    dlg, :label=> "Overwrite existing files", :checked=>true)
    create_control(:dropbox_autorename_check,  CheckBox,    dlg, :label=> "Auto resolve filename conflicts")

    create_processing_controls(dlg)
  end

  def layout_controls(container)
    super

    sh, eh, w = 20, 24, 180

    container.layout_with_contents(@dropbox_group_box, 0, container.base, -1, -1) do |c|
      c.set_prev_right_pad(5).inset(10,20,-10,-5).mark_base
      c << @dropbox_folder_static.layout(0, c.base+2, w-30, sh )
      c << @dropbox_foldername_static.layout(c.prev_right, c.base+2, 30, sh)
      c << @dropbox_foldername_edit.layout(c.prev_right, c.base, -1, eh)
      c.pad_down(5).mark_base
      c << @dropbox_overwrite_check.layout(0, c.base, -1, sh)
      c.pad_down(5).mark_base
      c << @dropbox_autorename_check.layout(0, c.base, -1, sh)

      c.pad_down(5).mark_base
      c.mark_base.size_to_base
    end

    container.pad_down(5).mark_base
    container.mark_base.size_to_base

    layout_processing_controls(container)
  end
end

class DropboxBackgroundDataFetchWorker < OAuthBackgroundDataFetchWorker
  def initialize(bridge, dlg)
    @client = DropboxClient.new(@bridge)
    super
  end
end

class DropboxFileUploader < OAuthFileUploader
  include PM::FileUploaderTemplate  # This also registers the class as File Uploader

  def initialize(pm_api_bridge, num_files, dlg_status_bridge, conn_settings_serializer)
    @bridge = pm_api_bridge
    super(pm_api_bridge, num_files, dlg_status_bridge, conn_settings_serializer)
  end

  def self.file_uploader_ui_class
    DropboxFileUploaderUI
  end

  def self.conn_settings_class
    DropboxConnectionSettings
  end

  def self.upload_protocol_class
    DropboxUploadProtocol
  end

  def self.background_data_fetch_worker_manager
    DropboxBackgroundDataFetchWorker
  end

  def create_controls(dlg)
    super
    @ui.dropbox_overwrite_check.on_click { adjust_controls }
  end

  def imglink_url
    "https://www.dropbox.com/"
  end

  protected

  def adjust_controls
    super
    @ui.dropbox_autorename_check.enable(!@ui.dropbox_overwrite_check.checked?)
  end

  def build_additional_upload_spec(spec, ui)
    spec.dropbox_folders = get_folders
    spec.dropbox_overwrite = @ui.dropbox_overwrite_check.checked? ? "true" : "false"
    spec.dropbox_autorename = @ui.dropbox_autorename_check.checked? ? "true" : "false"
  end

  def get_folders
    # Expand variables in foldername for each image
    foldername = @ui.dropbox_foldername_edit.get_text
    folders = {}
    @num_files.times do |i|
      unique_id = @bridge.get_item_unique_id(i+1)
      folder = "/" + @bridge.expand_vars(foldername, i+1) + "/" # Make sure path is delimited by /
      folders[unique_id] = folder.gsub(/\/{2,}/, "/") # Merge delimiters
    end
    folders
  end
end

class DropboxConnection < OAuthConnection
  def initialize(pm_api_bridge)
    @bridge = pm_api_bridge
    @api_key = API_KEY
    @api_secret = API_SECRET
    @base_url = 'https://api.dropboxapi.com/'
    @callback_url = 'https://auth.camerabits.com/oauth/verifier/Dropbox'
    super
  end

  # TODO: can this be moved to OAuth2Connection?
  def set_tokens_from_post(path, verifier=nil)
    query = create_query_string_from_hash({
                                            "code" => verifier,
                                            "grant_type" => "authorization_code",
                                            "redirect_uri" => callback_url
                                          })
    response = post(path+query)
    require_server_success_response(response)
    result = JSON::parse(response.body)
    # We only get an access token with OAuth2 so we set the
    # access_token_secret to N/A so authenticated checks don't break
    set_tokens(result['access_token'].to_s, "N/A")
    raise "Unable to verify code" unless !@verifier.nil? || authenticated?
    result
  end

  protected

  # TODO: can this be moved to OAuth2Connection?
  def oauth_auth_header(method, uri, params = {})
    if !authenticated?
      auth = 'Basic ' + [@api_key + ':' + @api_secret].pack('m').chomp("\n")
    else
      auth = 'Bearer ' + @access_token
    end
    auth
  end
end

class DropboxClient < OAuth2Client
  def connection
    @connection ||= DropboxConnection.new(@bridge)
  end

  def authorization_url
    "https://www.dropbox.com/oauth2/authorize" +
      connection.create_query_string_from_hash({
                                                 "response_type" => "code",
                                                 "client_id" => connection.api_key,
                                                 "redirect_uri" => connection.callback_url
                                               })
  end

  def get_account_name(result)
    uid = result['uid']
    response = connection.post('2/users/get_current_account')
    connection.require_server_success_response(response)
    begin
      result = JSON::parse(response.body)
      dbgprint "account name data #{result.inspect}"
      result['name']['display_name']
    rescue JSON::ParserError => err
      "ERROR: couldn't get name due to JSON ParserError"
    rescue
      "ERROR: couldn't get name"
    end
  end

  # TODO: can this be moved to OAuth2Client?
  def get_access_token(verifier)
    result = connection.set_tokens_from_post('oauth2/token', verifier)
    @name = get_account_name(result)
    [ connection.access_token, connection.access_token_secret, @name ]
  end
end

class DropboxConnectionImageUpload < DropboxConnection
  def initialize(pm_api_bridge)
    super
    @base_url = 'https://content.dropboxapi.com/'
  end
end

class DropboxUploadProtocol < OAuthUploadProtocol
  def connection
    @connection ||= DropboxConnectionImageUpload.new(@bridge)
  end

  def upload(fname, remote_filename, spec)
    fcontents = @bridge.read_file_for_upload(fname)

    begin
      connection.unmute_transfer_status
      destination_path = spec.dropbox_folders[spec.unique_id]+remote_filename
      mode_str = spec.dropbox_overwrite ? "overwrite" : "add"
      headers = {
        "Content-Length" => fcontents.length.to_s,
        "Authorization" => "Bearer " + connection.access_token,
        "Dropbox-API-Arg" => %<{"path": "#{destination_path}", "mode": "#{mode_str}", "autorename": #{spec.dropbox_autorename}, "mute": false }>,
        "Content-Type" => "application/octet-stream"
      }
      dbglog "Uploading, headers are #{headers.inspect}"
      response = connection.post('2/files/upload', fcontents, headers)
      connection.require_server_success_response(response)
      result = JSON::parse(response.body)
      actual_destination_path = result['path_display']
      dbglog "Uploaded file #{destination_path} renamed to #{actual_destination_path}" if actual_destination_path != destination_path
    ensure
      connection.mute_transfer_status
    end
  end
end
