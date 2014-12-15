#!/usr/bin/env ruby
# coding: utf-8
##############################################################################
#
# Copyright (c) 2014 Camera Bits, Inc.  All rights reserved.
#
# Developed by Hayo Baan
#
##############################################################################

TEMPLATE_DISPLAY_NAME = "Facebook"

##############################################################################

class FacebookConnectionSettings < OAuthConnectionSettings
  include PM::ConnectionSettingsTemplate # This also registers the class as Connection Settings
  
  def client
    @client ||= FacebookClient.new(@bridge)
  end
end

module FacebookPrivacy
  include PM::Dlg
  def facebook_privacy_items
    [ "Self", "Friends of Friends", "All Friends", "Everyone" ]
  end

  def facebook_privacy_from_item(item)
    '{ "value":"' + item.to_s.upcase.gsub(" ","_") + '"}'
  end

  def create_facebook_privacy_controls(dlg, persist=true)
    create_control(:facebook_privacy_static,    Static,      dlg, :label => "Privacy:")
    create_control(:facebook_privacy_combo,     ComboBox,    dlg, :items => facebook_privacy_items, :sorted=>false, :persist=>persist)
  end

  def layout_facebook_privacy_controls(c, x, y, w1, w2)
    sh, eh = 20, 24
    c << @facebook_privacy_static.layout(x, y+3, w1, sh)
    c << @facebook_privacy_combo.layout(c.prev_right, y, w2, eh)
  end
end

class FacebookNewAlbumDialogUI < Dlg::DynModalChildDialog
  include PM::Dlg
  include CreateControlHelper
  include FacebookPrivacy

  def initialize(connection, callback, privacy)
    @connection = connection
    @privacy = privacy
    @callback = callback
    super()
  end

  def connection
    @connection
  end

  def init_dialog
    dlg = self
    dlg.set_window_position_key("#{TEMPLATE_DISPLAY_NAME}NewAlbumDialog")
    dlg.set_window_position(100, 200, 500, 215)
    dlg.set_window_title("Create new #{TEMPLATE_DISPLAY_NAME} album")

    create_control(:album_name_static,    Static,      dlg, :label=>"Album name:")
    create_control(:album_name_edit,      EditControl, dlg, :value=>"", :persist=>false)
    create_control(:album_message_static, Static,      dlg, :label=>"Album description:")
    create_control(:album_message_edit,   EditControl, dlg, :value=>"", :multiline=>true, :persist=>false)
    create_facebook_privacy_controls(dlg, false)
    create_control(:create_button, Button,             dlg, :label=>"Create", :does=>"ok")
    create_control(:cancel_button, Button,             dlg, :label=>"Cancel", :does=>"cancel")

    @create_button.on_click { create_new_album }
    @cancel_button.on_click { closebox_clicked }

    layout_controls
    instantiate_controls
    @facebook_privacy_combo.set_selected_item(@privacy)
    @album_name_edit.set_focus
    show(true)
  end

  def layout_controls
    sh, eh = 20, 24

    dlg = self
    client_width, client_height = dlg.get_clientrect_size
    c = LayoutContainer.new(0, 0, client_width, client_height)
    c.inset(10, 10, -10, -10)

    c << @album_name_static.layout(0, c.base, -1, sh)
    c.pad_down(0).mark_base
    c << @album_name_edit.layout(0, c.base, -1, eh)
    c.pad_down(5).mark_base     
    c << @album_message_static.layout(0, c.base, -1, sh)
    c.pad_down(0).mark_base
    c << @album_message_edit.layout(0, c.base, -1, eh*3)
    layout_facebook_privacy_controls(c, 0, -eh, 80, 200)
    bw = 80
    c << @create_button.layout(-(2*bw+3), -eh, bw, eh)
    c << @cancel_button.layout(-bw, -eh, bw, eh)
  end

  protected

  def create_new_album
    name = @album_name_edit.get_text.strip
    message = @album_message_edit.get_text
    if name.empty?
      Dlg::MessageBox.ok("Please enter a non-blank album name.", Dlg::MessageBox::MB_ICONEXCLAMATION)
      return
    end

    begin
      query = connection.create_query_string_from_hash({ "name" => name,
                                                          "message" => message,
                                                          "privacy" => facebook_privacy_from_item(@facebook_privacy_combo.get_selected_item)
                                                        })
      response = connection.post('me/albums' + query)
      connection.require_server_success_response(response)
      @callback.call(name)
      end_dialog(IDOK)
    rescue StandardError => e
      Dlg::MessageBox.ok("Failed to create album:\n#{e}", Dlg::MessageBox::MB_ICONEXCLAMATION)
    end
  end
end

class FacebookFileUploaderUI < OAuthFileUploaderUI
  include FacebookPrivacy
  
  def valid_file_types
    [ "JPEG", "GIF", "PNG", "TIFF" ] # all file types are valid
  end

  def ip_warning?
    true # Warn users about giving away ip rights
  end

  def create_controls(dlg)
    super

    create_control(:facebook_group_box,         GroupBox,    dlg, :label => "Facebook:")
    create_control(:facebook_albums_check,      CheckBox,    dlg, :label => "Use Album?:", :checked=>true)
    create_control(:facebook_albums_combo,      ComboBox,    dlg, :items =>[], :sorted=>true, :persist=>true)
    create_control(:facebook_albums_new_button, Button,      dlg, :label=> "Create new album...")
    create_control(:facebook_message_static,    Static,      dlg, :label => "Message:")
    create_control(:facebook_message_edit,      EditControl, dlg, :value => "{caption} – uploaded via Photo Mechanic", :multiline=>true, :persist=>true)
    create_control(:facebook_story_check,       CheckBox,    dlg, :label => "Include in story feed?")
    create_facebook_privacy_controls(dlg)
    
    create_processing_controls(dlg)
  end

  def layout_controls(container)
    super
    
    sh, eh = 20, 24

    container.layout_with_contents(@facebook_group_box, 0, container.base, -1, -1) do |c|
      c.set_prev_right_pad(5).inset(10,20,-10,-5).mark_base
      c << @facebook_albums_check.layout(0, c.base+1, 120, sh)
      c << @facebook_albums_combo.layout(c.prev_right, c.base, 400, eh)
      c << @facebook_albums_new_button.layout(-200, c.base, 200, eh)
      c.pad_down(5).mark_base     
      c << @facebook_message_static.layout(0, c.base, -1, sh)
      c.pad_down(0).mark_base
      c << @facebook_message_edit.layout(0, c.base, -1, eh*3)
      c.pad_down(5).mark_base
      c << @facebook_story_check.layout(0, c.base+2, 200, sh)
      c.pad_down(5).mark_base
      layout_facebook_privacy_controls(c, 0, c.base, 80, 200)
      c.pad_down(5).mark_base
      c.mark_base.size_to_base
    end

    container.pad_down(5).mark_base
    container.mark_base.size_to_base

    layout_processing_controls(container)
  end
end

class FacebookBackgroundDataFetchWorker < OAuthBackgroundDataFetchWorker
  def initialize(bridge, dlg)
    @client = FacebookClient.new(@bridge)
    super
  end
end

class FacebookFileUploader < OAuthFileUploader
  include PM::FileUploaderTemplate  # This also registers the class as File Uploader
  include FacebookPrivacy

  def self.file_uploader_ui_class
    FacebookFileUploaderUI
  end
  
  def self.conn_settings_class
    FacebookConnectionSettings
  end

  def self.upload_protocol_class
    FacebookUploadProtocol
  end

  def self.background_data_fetch_worker_manager
    FacebookBackgroundDataFetchWorker
  end

  def restore_state(serializer)
    settings_data = serializer.instance_variable_get("@data")
    @previous_album = settings_data[:facebook_albums_combo][:selected] if settings_data[:facebook_albums_combo]
    super
  end

  def initialize(pm_api_bridge, num_files, dlg_status_bridge, conn_settings_serializer)
    super
    @account_permissions = {}
    @account_albums = {}
    @previous_album = nil
  end

  def create_controls(dlg)
    super
    @ui.facebook_albums_check.on_click { adjust_album_controls }
    @ui.facebook_albums_combo.on_sel_change { handle_album_change }
    @ui.facebook_albums_new_button.on_click { handle_new_album }
  end
  
  def upload_files(global_spec, progress_dialog)
    raise "Please authorize Photo Mechanic to publish on your behalf" unless @account_permissions['publish_actions']
    super
  end

  def imglink_url
    "https://www.facebook.com/"
  end

  protected

  def build_additional_upload_spec(spec, ui)
    spec.facebook_messages = get_messages
    spec.facebook_privacy = facebook_privacy_from_item @ui.facebook_privacy_combo.get_selected_item
    spec.facebook_no_story = !@ui.facebook_story_check
    if @ui.facebook_albums_check.checked? && !@account_albums.empty? && @account_permissions['user_photos']
      spec.album_id = @account_albums[@ui.facebook_albums_combo.get_selected_item]['id']
    else
      spec.album_id = 'me'
    end
  end

  def get_messages
    # Expand variables in messages for each image
    message = @ui.facebook_message_edit.get_text
    messages = {}
    @num_files.times do |i|
      unique_id = @bridge.get_item_unique_id(i+1)
      messages[unique_id] = @bridge.expand_vars(message, i+1)
    end
    messages
  end

  def handle_album_change
    @previous_album = @ui.facebook_albums_combo.get_selected_item
  end

  def handle_new_album
    account = current_account_settings
    return if !account

    connection = FacebookConnection.new(@bridge)
    connection.set_tokens(account.access_token, account.access_token_secret)
    callback = lambda do |name|
      account_parameters_changed
      @ui.facebook_albums_combo.set_selected_item(name) if @ui.facebook_albums_check.checked?
    end
    cdlg = FacebookNewAlbumDialogUI.new(connection, callback, @ui.facebook_privacy_combo.get_selected_item)
    cdlg.instantiate!
    cdlg.request_deferred_modal
  end

  def adjust_album_controls
    @ui.facebook_albums_combo.reset_content

    if @account_albums.empty?
      @ui.facebook_albums_check.enable(false)
      @ui.facebook_albums_check.checked(false)
      @ui.facebook_albums_combo.enable(false)
      @ui.facebook_albums_combo.add_item(@account_permissions['publish_actions'] ?
                                           (@account_permissions['user_photos'] ?
                                              "No albums created" :
                                              "Account not authorised for user photos") + ", using default album" :
                                           "Account not authorized to publish!")
    else
      @ui.facebook_albums_combo.enable(@ui.facebook_albums_check.checked?)
      if @ui.facebook_albums_check.checked?
        @account_albums.each_key { | a | @ui.facebook_albums_combo.add_item(a) }
      else
        @ui.facebook_albums_combo.add_item("Using default album")
      end
    end
    @ui.facebook_albums_new_button.enable(@account_permissions['publish_actions'] && @account_permissions['user_photos'])
    @ui.facebook_albums_combo.set_selected_item(@previous_album) if @previous_album && @account_albums[@previous_album]
  end

  def account_parameters_changed
    super
    @account_permissions = {}
    @account_albums = {}

    account = current_account_settings
    if !account
      @dlg.set_status_text("Please select an account, or create one with the Connections button.")
      return
    end
 
    connection = FacebookConnection.new(@bridge)
    connection.set_tokens(account.access_token, account.access_token_secret)
    
    # See what permissions we have
    @account_permissions = connection.get_permissions

    set_status_text("Warning: this account is not authorised to publish. Please authorize it using the Connections button.") unless @account_permissions['publish_actions']

    # Fill albums
    if @account_permissions['user_photos']
      @account_albums = connection.get_albums
    end
    adjust_album_controls
  end
end

class FacebookConnection < OAuthConnection
  def initialize(pm_api_bridge)
    @base_url = 'https://graph.facebook.com/'
    @api_key = '847826438602773'
    @api_secret = 'N/A' # Not required!
    @callback_url = 'https://auth.camerabits.com/oauth/verifier/Facebook'
    super
  end

  def set_tokens_from_post(path, verifier=nil)
    # Facebook's token is not set from the post, but directly retrieved from as verification code
    raise "Program error: set_tokens_from_post called for #{TEMPLATE_DISPLAY_NAME}"
  end

  def get_permissions
    set_tokens(access_token, "N/A") if access_token

    # See what permissions we have
    permissions = {}
    begin
      response = get('me/permissions');
      require_server_success_response(response)
      result = JSON::parse(response.body)
      result['data'].each { | p | permissions[p['permission']] = p['status'] == 'granted' }
    rescue
      # Ignore any errors
    end
    permissions
  end

  def get_albums
    # See what permissions we have
    albums = {}
    begin
      response = get('me/albums');
      require_server_success_response(response)
      result = JSON::parse(response.body)
      result['data'].each { | a | albums[a['name']] = a }    
    rescue
      # Ignore any errors
    end
    albums
  end

  def add_authentication(path)
    if @access_token
      path += (path =~ /\?/) ? "&" : "?"
      path += "access_token=" + URI.escape(@access_token)
    end
    path
  end

  def get(path, params = {})
    path = add_authentication(path)
    super(path, params)
  end

  def put(path, params = {}, upload_headers = {})
    path = add_authentication(path)
    super(path, params, upload_headers)
  end

  def post(path, params = {}, upload_headers = {})
    path = add_authentication(path)
    super(path, params, upload_headers)
  end 

  protected

  def request_headers(method, url, params = {}, signature_params = params)
    # Facebook doesn't use headers for authentication
    {}
  end
end

class FacebookClient < OAuth2Client
  def connection
    @connection ||= FacebookConnection.new(@bridge)
  end
  
  def authorization_url
    "https://www.facebook.com/dialog/oauth" +
      connection.create_query_string_from_hash({
                                                 "response_type" => "token",
                                                 "client_id" => connection.api_key,
                                                 "redirect_uri" => connection.callback_url,
                                                 "scope" => "public_profile,user_photos,publish_actions"
                                               })
  end

  def get_account_name(verifier)
    response = connection.get('me')
    connection.require_server_success_response(response)
    result = JSON::parse(response.body)
    result['name']
  end

  def get_access_token(verifier)
    # Verifier is actually the user access_token...
    connection.set_tokens(verifier, "N/A")
    @name = get_account_name(verifier)
    [ connection.access_token, connection.access_token_secret, @name ]
  end
end

class FacebookUploadProtocol < OAuthUploadProtocol
  def connection
    @connection ||= FacebookConnection.new(@bridge)
  end  
  
  def upload(fname, remote_filename, spec)
    fcontents = @bridge.read_file_for_upload(fname)
    mime = MimeMultipart.new
    mime.add_field("message", spec.facebook_messages[spec.unique_id])
    mime.add_field("no_story", spec.facebook_no_story)
    mime.add_field("privacy", spec.facebook_privacy)
    mime.add_image("source", remote_filename, fcontents, "application/octet-stream")
    data, headers = mime.generate_data_and_headers

    begin
      connection.unmute_transfer_status
      response = connection.post("#{spec.album_id}/photos", data, headers)
      connection.require_server_success_response(response)
    ensure
      connection.mute_transfer_status
    end
  end
end
