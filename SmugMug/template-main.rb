#!/usr/bin/env ruby
# coding: utf-8
##############################################################################
#
# Copyright (c) 2018 Camera Bits, Inc.  All rights reserved.
#
##############################################################################

TEMPLATE_DISPLAY_NAME = "SmugMug"

# API Version v2 (beta)
SMUG_VER        = "v2"
MAX_CHILD_COUNT = "500"
IMG_LINK_URL    = "http://www.smugmug.com/"
BASE_URL        = "https://api.smugmug.com/services/"
CALLBACK_URL    = "https://auth.camerabits.com/oauth/verifier/SmugMug"
API_V2_HOST     = "https://api.smugmug.com/api/v2/"
UPLOAD_HOST     = "https://upload.smugmug.com/"
API_KEY         = "cPvZR25P5pJB9XJ2DqwzCg89rsCGX3n5"
SHARED_SECRET   = "TX54ZkcTHHDjZMtS25zcxqqcXcDJT6fTHkg45JVDx3XnkWbj9FTXqpcddHxM7SKr"

STATIC_TEXT_HEIGHT = 20
EDIT_FIELD_HEIGHT = 24
COLOR_BUTTON_HEIGHT = 24
RIGHT_PAD = 5


class SmugMugConnectionSettings < OAuthConnectionSettings
  include PM::ConnectionSettingsTemplate # This also registers the class as Connection Settings

  def client
    @client ||= SmugMugAuthClient.new(@bridge)
  end
end # SmugMugConnectionSettings


class SmugMugFileUploaderUI < OAuthFileUploaderUI
  def metadata_safe?
    true
  end

  def enable_rename?
    true
  end

  def valid_file_types
    [ "JPEG", "PNG", "GIF" ]
  end

  def create_controls(dlg)
    create_control(:dest_account_group_box,               GroupBox,       dlg, :label=>"Destination #{TEMPLATE_DISPLAY_NAME} Account:")
    create_control(:dest_account_static,                  Static,         dlg, :label=>"Account:", :align=>"right")
    create_control(:dest_account_combo,                   ComboBox,       dlg, :sorted=>true, :persist=>false)
    create_control(:dest_path_static,                     Static,         dlg, :label=>"Destination UrlPath:", :align=>"right")
    create_control(:dest_path_show_static,                Static,         dlg, :label=>"")

    create_control(:folder_browser_group_box,             GroupBox,       dlg, :label=>"Upload Preferences:")
    create_control(:folder_browser_tree_text,             Static,         dlg, :label=>"View:", :align=>"left")
    create_control(:folder_browser_reload,                Button,         dlg, :label=>"Reload")
    create_control(:folder_browser_create_folder_button,  Button,         dlg, :label=>"New Folder...")
    create_control(:folder_browser_create_album_button,   Button,         dlg, :label=>"New Gallery...")
    create_control(:folder_browser_column_browser,        SmugMugBrowser::ColumnBrowser, dlg)

    create_processing_controls(dlg)
  end

  def layout_controls(container)
    sh = STATIC_TEXT_HEIGHT
    eh = EDIT_FIELD_HEIGHT
    ch = COLOR_BUTTON_HEIGHT
    rp = RIGHT_PAD

    container.inset(15, 5, -15, -5)
    container.layout_with_contents(@dest_account_group_box, 0, container.base, -1, -1) do |c|
      c.set_prev_right_pad(rp).inset(10,25,-10,-5).mark_base

      c.layout_subgroup(0, c.base, "100%-5", -1) do |cl|
        cl.set_prev_right_pad(rp)
        cl << @dest_account_static.layout(0, cl.base+3, 120, sh)
        cl << @dest_account_combo.layout(cl.prev_right, cl.base, "30%", eh)
        cl.pad_down(5).mark_base
        cl << @dest_path_static.layout(0, cl.base+3, 120, sh)
        cl << @dest_path_show_static.layout(cl.prev_right, cl.base+3, "100%", sh)
        cl.pad_down(5).mark_base.size_to_base
      end

      c.pad_down(0).mark_base
      c.pad_down(5).mark_base.size_to_base
    end
    container.pad_down(5).mark_base

    container.inset(15, 5, -15, -5)
    container.layout_with_contents(@folder_browser_group_box, 0, container.base, -1, -1) do |c|
      c.set_prev_right_pad(rp).inset(10,25,-10,-5).mark_base

      w1 = 150
      c << @folder_browser_reload.layout("100%-120", c.base, 120, eh)
      c << @folder_browser_create_folder_button.layout(0, c.base, 160, 24)
      c << @folder_browser_create_album_button.layout(c.prev_right, c.base, 160, 24)
      c.pad_down(10).mark_base
      c << @folder_browser_column_browser.layout(5, c.base, -5, 200)
      c.pad_down(5).mark_base

      c.pad_down(5).mark_base.size_to_base
    end
    container.pad_down(5).mark_base

    layout_processing_controls(container)
    container.pad_down(20).mark_base
  end
end # SmugMugFileUploaderUI


class SmugMugCreateDialog < Dlg::DynModalChildDialog

  include PM::Dlg
  include CreateControlHelper

  def initialize(api_bridge, type, parent_node_id, dialog_end_callback)
    @bridge = api_bridge
    @node_id = parent_node_id
    @dialog_end_callback = dialog_end_callback
    @type = type
    @success = false
    super()
  end

  def init_dialog
    # this will be called by c++ after DoModal()
    # calls InitDialog.
    dlg = self
    dlg.set_window_position_key("SmugMugCreateDialog")
    dlg.set_window_position(50, 100, 500, 200)
    title = "Create New #{@type}"
    dlg.set_window_title(title)
    
    parent_dlg = dlg
    create_control(:descrip_gallery_static, Static,         parent_dlg, :label=>"Create new #{TEMPLATE_DISPLAY_NAME} #{@type}:", :align=>"left")
    create_control(:privacy_static,         Static,         parent_dlg, :label=>"Privacy:", :align=>"left")
    create_control(:privacy_combo,          ComboBox,       parent_dlg, :items=>["Private", "Unlisted", "Public"], :selected=>"Private")
    create_control(:new_item_static,        Static,         parent_dlg, :label=>"New #{@type} name:", :align=>"left")
    create_control(:new_item_edit,          EditControl,    parent_dlg, :value=>"", :persist=>false)
    create_control(:create_button,          Button,         parent_dlg, :label=>"Create")
    create_control(:cancel_button,          Button,         parent_dlg, :label=>"Cancel")

    @create_button.on_click { create_item }
    @cancel_button.on_click { closebox_clicked }
    
    layout_controls
    instantiate_controls
    show(true)
  end        

  def destroy_dialog!
    super
    (@dialog_end_callback.call(@success) if @dialog_end_callback) rescue nil
  end

  def layout_controls
    sh = 20
    eh = 24
    bh = 28
    dlg = self
    client_width, client_height = dlg.get_clientrect_size
    c = LayoutContainer.new(0, 0, client_width, client_height)
    c.inset(16, 10, -16, -10)
    c << @descrip_gallery_static.layout(0, c.base, -1, sh)
    c.pad_down(20).mark_base
    
    w1 = 150
    c << @privacy_static.layout(0, c.base, w1, sh)
      c << @new_item_static.layout(c.prev_right + 20, c.base, -1, sh)
    c.pad_down(0).mark_base
    c << @privacy_combo.layout(0, c.base, w1, eh)
      c << @new_item_edit.layout(c.prev_right + 20, c.base, -1, eh)
    c.pad_down(5).mark_base
    
    bw = 80
    c << @create_button.layout(-(bw*2+10), -bh, bw, bh)
      c << @cancel_button.layout(-bw, -bh, bw, bh)
  end

  protected

  def connection
    @connection ||= SmugMugAPI.new
  end
  
  def create_item
    name = @new_item_edit.get_text.strip
    privacy = @privacy_combo.get_selected_item
    parent_node_id = @node_id

    if name.empty?
      Dlg::MessageBox.ok("Please enter a non-blank #{@type} name.", Dlg::MessageBox::MB_ICONEXCLAMATION)
      return
    end

    begin
      if (@type == "Gallery")
        connection.create_gallery(privacy, name, parent_node_id)
      else
        connection.create_folder(privacy, name, parent_node_id)
      end
      @success = true
    rescue StandardError => ex
      dbglog ex.message
      dbglog ex.backtrace
      Dlg::MessageBox.ok("Failed to create #{@type} #{name} on server.\nError: #{ex.message}", Dlg::MessageBox::MB_ICONEXCLAMATION)
    ensure
      end_dialog(IDOK)
    end 
  end
end # SmugMugCreateDialog


class SmugMugBackgroundDataFetchWorker < OAuthBackgroundDataFetchWorker
  def initialize(bridge, dlg)
    @client = SmugMugAuthClient.new(@bridge)
    super
  end

  # called periodically (by BackgroundDataFetchWorkerManager)
  def do_task
    return unless @dlg.account_parameters_dirty
    acct = @dlg.current_account_settings
    if acct.nil?
      @dlg.set_status_text("Please select an account, or create one with the Connections button.")
    elsif ! acct.appears_valid?
      @dlg.set_status_text("Some account settings appear invalid or missing. Please click the Connections button.")
    else
      begin
        @dlg.disable_send_button
        @dlg.set_status_text("Fetching items from server...")
        SmugMugAPI.set_acct_name(acct.account_name)
        @dlg.set_browser_theme
        @dlg.load_column_zero

        if @dlg.is_gallery && @dlg.url_path && @dlg.node_id
          @dlg.send_button(true)
        else
          @dlg.send_button(false)
        end
      rescue StandardError => ex
        @dlg.set_status_text(ex.message)
        dbglog ex.message
        dbglog ex.backtrace
      end
    end
    @dlg.account_parameters_dirty = false
  end
end # SmugMugBackgroundDataFetchWorker


class SmugMugFileUploader < OAuthFileUploader
  include PM::FileUploaderTemplate  # This also registers the class as File Uploader

  attr_reader :create_dlg_busy, :url_path, :node_id, :is_gallery

  def self.file_uploader_ui_class
    SmugMugFileUploaderUI
  end

  def self.conn_settings_class
    SmugMugConnectionSettings
  end

  def self.upload_protocol_class
    SmugMugUploadProtocol
  end

  def self.background_data_fetch_worker_manager
    SmugMugBackgroundDataFetchWorker
  end

  def imglink_url
    IMG_LINK_URL
  end

  def create_controls(dlg)
    super
    @file_upload_dialog = dlg.parent_dlg

    @ui.folder_browser_reload.on_click { handle_browser_reload }
    @ui.folder_browser_column_browser.on_click { adjust_browser_controls }
    @ui.folder_browser_create_album_button.on_click { handle_create_gallery_dialog }
    @ui.folder_browser_create_folder_button.on_click { handle_create_folder_dialog }
  end

  def save_state(serializer)
    return unless @ui
    serializer.store(DLG_SETTINGS_KEY, :selected_account, @ui.dest_account_combo.get_selected_item)
    serializer.store(DLG_SETTINGS_KEY, :selected_url_path, url_path)
    serializer.store(DLG_SETTINGS_KEY, :selected_node_id, node_id)
    serializer.store(DLG_SETTINGS_KEY, :selected_is_gallery, is_gallery)
  end

  def restore_state(serializer)
    reset_account_combo_from_settings
    select_previous_account(serializer)
    select_first_available_if_present
    select_previous_node_id(serializer)
    select_previous_url_path(serializer)
    select_previous_is_gallery(serializer)

    account_parameters_changed
    adjust_controls
  end

  def preflight_settings(global_spec)
    super
    raise("Create Folder/Gallery dialog is open!") if create_dlg_busy
  end

  def send_button(enable)
    if enable
      if num_files == 0
        set_status_text("No images selected.")
      else
        set_status_text("You are ready to upload your " + (num_files > 1 ? "#{num_files} images." : "image."))
        @file_upload_dialog.enable_send_button
      end
    else
      @file_upload_dialog.disable_send_button
      if num_files == 0
        set_status_text("No images selected.")
      else
        set_status_text("No Gallery selected.")
      end
    end
  end

  protected

  def select_previous_node_id(serializer)
    @node_id = serializer.fetch(DLG_SETTINGS_KEY, :selected_node_id)
  end

  def select_previous_url_path(serializer)
    prev_selected_url_path = serializer.fetch(DLG_SETTINGS_KEY, :selected_url_path)
    if prev_selected_url_path
      @url_path = prev_selected_url_path
      @ui.dest_path_show_static.set_text(url_path)
    end
  end

  def select_previous_is_gallery(serializer)
    @is_gallery = serializer.fetch(DLG_SETTINGS_KEY, :selected_is_gallery)
  end

  def adjust_browser_controls
    return unless column_browser_instantiated?
    @url_path = @ui.folder_browser_column_browser.selected_url_path
    @node_id = @ui.folder_browser_column_browser.selected_id
    @is_gallery = @ui.folder_browser_column_browser.gallery_selected? ? true : false
    @ui.dest_path_show_static.set_text(url_path)
    send_button(is_gallery)
  end

  def connection
    if @connection.nil?
      @connection = SmugMugConnectionClient.new(@bridge)
      @connection.set_tokens(account.access_token, account.access_token_secret)
    end
    @connection
  end

  def handle_browser_reload
    send_button(false)
    reload_column_browser
  end

  def create_dialog(is_gallery)
    return unless column_browser_instantiated?
    type = is_gallery ? "Gallery" : "Folder"
    begin
      gal_selected = @ui.folder_browser_column_browser.gallery_selected?
      raise("Unable to create a new #{type} in Gallery. Please choose a Folder.") if gal_selected

      parent_node_id = node_id

      unless parent_node_id # is root
        conn = SmugMugAPI.new
        user_node_id = conn.user_node_id
        parent_node_id = user_node_id
      end
      raise("Unable to get NodeId.") unless parent_node_id

      set_status_text("Ready to create #{type}.")
      dialog_end_callback = lambda {|success| handle_new_gallery_created(success)}
      cdlg = SmugMugCreateDialog.new(@bridge, type, parent_node_id, dialog_end_callback)
      cdlg.instantiate!
      cdlg.request_deferred_modal
      @create_dlg_busy = true
    rescue StandardError => ex
      dbglog ex.message
      dbglog ex.backtrace
      Dlg::MessageBox.ok("Error: #{ex.message}", Dlg::MessageBox::MB_ICONEXCLAMATION)
    end
  end

  def handle_create_gallery_dialog
    create_dialog(true)
  end

  def handle_create_folder_dialog
    create_dialog(false)
  end

  def handle_new_gallery_created(success)
    @create_dlg_busy = false
    if success
      refresh_column_browser_last_column
      send_button(false)
    end
  end

  def column_browser_instantiated?
    @ui.folder_browser_column_browser.instantiated?
  end
  
  def reload_column_browser
    return unless column_browser_instantiated?
    @ui.folder_browser_column_browser.reload
    adjust_browser_controls
  end

  def refresh_column_browser_last_column
    return unless column_browser_instantiated?
    @ui.folder_browser_column_browser.refresh_column
  end

  def account_parameters_changed
    super
    @connection = nil
    SmugMugAPI.account_parameters_changed
    if account.nil? || !account.appears_valid?
      return
    end
    SmugMugAPI.set_connection(connection)
  end

  def build_additional_upload_spec(spec, ui)
    conn = SmugMugAPI.new
    unless node_id # is root
      @node_id = conn.user_node_id
    end
    spec.album_key = conn.get_album_key(node_id)
  end
end # SmugMugFileUploader


class SmugMugConnection < OAuthConnection
  def initialize(pm_api_bridge)
    @base_url = BASE_URL
    @api_key = API_KEY
    @api_secret = SHARED_SECRET
    @callback_url = CALLBACK_URL
    super
  end
end # SmugMugConnection


class SmugMugAuthClient < OAuthClient
  def connection
    @connection ||= SmugMugConnection.new(@bridge)
  end

  def connection_client
    @connection_client ||= SmugMugConnectionClient.new(@bridge)
  end

  def smugmug_api?
    true
  end

  def get_nickname(json_data)
    json_data['Response']['User']['NickName']
  end

  def query_authuser(result)
    connection_client.set_tokens(result['oauth_token'], result['oauth_token_secret'])
    response = connection_client.get("!authuser?_accept=application/json")
    connection_client.require_server_success_response(response)
    response
  end

  def get_account_name(result)
    response = query_authuser(result)
    response_body = response.body
    get_nickname(JSON.parse(response_body))
  end
end # SmugMugAuthClient


class SmugMugConnectionClient < SmugMugConnection
  def initialize(pm_api_bridge)
    super
    @base_url = API_V2_HOST
  end
end # SmugMugConnectionClient


class SmugMugConnectionImageUpload < SmugMugConnection
  def initialize(pm_api_bridge)
    super
    @base_url = UPLOAD_HOST
  end
end # SmugMugConnectionImageUpload


class SmugMugAddPhotoResponse
  def initialize(bridge, json_resp)
    begin
      response_body_json = JSON.parse(json_resp)
    rescue JSON::ParserError => e
      dbglog "JSON::ParserError: #{e.message}"
      dbglog "Server response: #{json_resp}"
      raise("JSON::ParserError - See PM.log file for server response.")
    end 
    raise("Image upload failed - server response: #{response_body_json['message']}") unless (response_body_json["stat"] == "ok")
  end
end # SmugMugAddPhotoResponse


class SmugMugCreateItemResponse
  def initialize(json_resp)
    begin
      response_body_json = JSON.parse(json_resp)
    rescue JSON::ParserError => e  
      dbglog "JSON::ParserError: #{e.message}"
      dbglog "Server response: #{json_resp}"
      raise("JSON::ParserError - See PM.log file for server response.")
    end 
    if response_body_json['Message'] == "Conflict"
      raise("An item with that name already exists.")
    elsif response_body_json['Message'] != "Created"
      raise("Server response: #{response_body_json['Message']}")
    end
  end
end # SmugMugCreateItemResponse


class SmugMugQueryServerResponse
  def initialize(json_resp)
    begin
      response_body_json = JSON.parse(json_resp)
    rescue JSON::ParserError => e
      msg = "JSON::ParserError - See PM.log file for server response."
      dbglog "JSON::ParserError: #{e.message}"
      dbglog "Server response: #{json_resp}"
      Dlg::MessageBox.ok(msg, Dlg::MessageBox::MB_ICONEXCLAMATION)
      raise
    end 
    if response_body_json['Message'].include? "oauth_problem"
      msg = "There is a problem with your connection settings." +
            "\nPlease click the Connections button to reauthorize Photo Mechanic. "
      dbglog "Server response: oauth_problem"
      Dlg::MessageBox.ok(msg, Dlg::MessageBox::MB_ICONEXCLAMATION)
      raise
    elsif response_body_json['Message'] != "Ok"
      msg = "Server response: #{response_body_json['Message']}"
      dbglog msg
      Dlg::MessageBox.ok(msg, Dlg::MessageBox::MB_ICONEXCLAMATION)
      raise
    end
  end
end # SmugMugQueryServerResponse


SmugMugStruct = Struct.new(:type, :name, :node_id, :url_path, :url_name, :has_children)


class SmugMugAPI

  def self.set_connection(connection)
    @@connection = connection
  end

  def self.set_acct_name(name)
    @@acct_name = name
  end

  def self.account_parameters_changed
    @@acct_name = nil
    @@connection = nil
    @user_node_id = nil
  end

  def connection
    @@connection ||= nil
  end

  def acct_name
    @@acct_name ||= nil
  end

  def user_node_id
    raise("acct_name not set!") unless acct_name
    uri_safe_name = URI.encode(acct_name)
    url = "user/#{uri_safe_name}?_accept=application/json"
    @user_node_id = parse_user_data(query_server(url))
  end

  def get_root_list
    return [] unless valid_connection?
    parse_node(query_folder_children(user_node_id))
  end

  def get_node_list(node_id)
    return [] unless (valid_connection? && node_id)
    parse_node(query_folder_children(node_id))
  end

  def create_gallery(privacy, name, parent_node_id)
    create_item(true, privacy, name, parent_node_id)
  end

  def create_folder(privacy, name, parent_node_id)
    create_item(false, privacy, name, parent_node_id)
  end

  def get_album_key(node_id)
    parse_album_data(query_album(node_id))
  end

  protected

  def create_item(is_gallery, privacy, name, parent_node_id)
    raise("Folder NodeId is missing!") if (parent_node_id.nil? || parent_node_id.strip.empty?)
    name = name.gsub('/', '').gsub('\\', '')
    raise("Name is emtpy!") if name.empty?
    url_name = fixed_url_name(name)

    type = is_gallery ? "Album" : "Folder"
    
    mime = MimeMultipart.new
    mime.add_field("Name", name)
    mime.add_field("UrlName", url_name) # first character must be uppercased, no more than 32 characters long, and you should represent spaces with a hyphen
    mime.add_field("Privacy", privacy) # Private, Unlisted, or Public - album will always be set to private if folder is private
    mime.add_field("Type", type)

    data, headers = mime.generate_data_and_headers

    response = connection.post("node/#{parent_node_id}!children?_accept=application/json", data, headers)
    #connection.require_server_success_response(response)
    response_body = response.body
    SmugMugCreateItemResponse.new(response_body)
  end

  def valid_connection?
    ! (acct_name.nil? || connection.nil?)
  end

  def query_server(url)
    response = connection.get(url)
    #connection.require_server_success_response(response)
    response_body = response.body
    SmugMugQueryServerResponse.new(response_body)
    JSON.parse(response_body)
  end

  def query_folder_children(node_id)
    url = "node/#{node_id}!children?_accept=application/json&count=#{MAX_CHILD_COUNT}&_verbosity=1"
    query_server(url)
  end

  def query_album(node_id)
    url = "node/#{node_id}?_accept=application/json"
    query_server(url)
  end

  def parse_album_data(response_body_json)
    uri = response_body_json['Response']['Node']['Uris']['Album']['Uri']
    raise("Album Uri not found.") if (uri.nil? || uri.empty?)
    uri.split("/").last
  end

  def parse_user_data(response_body_json)
    uri = response_body_json['Response']['User']['Uris']['Node']['Uri']
    raise("User Uri not found.") if (uri.nil? || uri.empty?)
    uri.split("/").last
  end

  def parse_node(node_json)
    list = []
    node_json['Response']['Node'].each_with_index do |value, index|
      type = value['Type'] # Folder / Album
      name = value['Name']
      node_id = value['NodeID']
      url_path = value['UrlPath'].sub(/^\//, "").sub(/\/$/, "")
      url_name = value['UrlName']
      has_children = value['HasChildren'] # is bool
      validate_response(type, name, node_id, url_path, url_name, has_children)
      list << SmugMugStruct.new(type, name, node_id, url_path, url_name, has_children)
    end unless node_json['Response']['Node'].nil?
    list
  end

  def validate_response(type, name, node_id, url_path, url_name, has_children)
    raise("Name not found.") if (name.nil? || name.empty?)
    raise("NodeID not found.") if (node_id.nil? || node_id.empty?)
    raise("UrlPath not found.") if (url_path.nil? || url_path.empty?)
    raise("UrlName not found.") if (url_name.nil? || url_name.empty?)
    raise("HasChildren not found.") if has_children.nil? # is bool
  end

  def fixed_url_name(name)
    raise("Album name must be 1 to 32 characters.") unless (1..32).include?(name.size)
    name.capitalize.gsub(/\s+/, '-').gsub('_', '')
  end
end # SmugMugAPI


module SmugMugBrowser
  class ColumnBrowser < PM::Dlg::ColumnBrowser
    attr_reader :selected_col, :is_leaf, :selected_id, :color, :selected_url_path

    def connection
      @connection ||= SmugMugAPI.new
    end

    def post_init
      set_ui_theme
      load_on_query_num
      load_on_display_cell
      
      # ColumnBrowser delegate method.  Do not make bridge calls to the browser control in this method!
      self.on_click do |row, col, full_selpath|
        begin
          node = @collection[col][row]
          return unless node
          @gallery_selected = (node.type == "Album")
          @selected_id = node.node_id
          @selected_url_path = node.url_path
          @selected_col = col
          @is_leaf = !node.has_children
        rescue Exception => ex
          dbglog("ColumnBrowser:on_click exception: #{ex.inspect}\n#{ex.backtrace_to_s}")
          raise ex
        end
      end
    end

    def load_on_query_num
      on_query_num_rows_in_column do |col, selected_path|
        query_num_rows_in_column(col, selected_path)
      end
    end

    def load_on_display_cell
      on_will_display_cell_at_row_col do |row, col, selected_path|
        display_cell_at_row_col(row, col, selected_path)
      end
    end

    def query_num_rows_in_column(col, selected_path)
      @collection ||= {}
      selected_node_id = nil
      begin
        if col.zero?
          # get root children
          @collection[col] = connection.get_root_list
          @collection[col].count
        else
          select_col = col - 1
          selected_row = get_selected_path[select_col]
          selected_node_id = @collection[select_col][selected_row].node_id unless @collection[select_col].nil?
          # get selected node's children
          @collection[col] = connection.get_node_list(selected_node_id)
          @collection[col].count
        end
      rescue Exception => ex
        dbglog("ColumnBrowser:on_query_num_rows_in_column exception: #{ex.inspect}\n#{ex.backtrace_to_s}")
        raise
      end
    end

    def display_cell_at_row_col(row, col, selected_path)
      begin
        node = nil
        node = @collection[col][row] unless @collection[col].nil?

        generate_cell_data(node)
      rescue Exception => ex
        dbglog("ColumnBrowser:on_will_display_cell_at_row_col exception: #{ex.inspect}\n#{ex.backtrace_to_s}")
        raise
      end
    end

    def generate_cell_data(node)
      result = {}
      if node
        name = node.name
        leaf = !node.has_children
        is_bold = (node.type == "Folder")

        result = {
          "text" => name,
          "is_leaf" => leaf,
          "is_bold" => is_bold,
          "text_color" => color
        }
      end
      result
    end

    def set_ui_theme(style = nil)
      if style == "DarkUI"
        @color = 0xffffff
      else
        @color = 0x333333
      end
    end

    def refresh_column
      if is_leaf || selected_id.nil?
        reload_column(selected_col)
      else
        reload_column(selected_col + 1)
      end
    end

    def reload
      @collection = {}
      @gallery_selected = false
      @is_leaf = false
      @selected_id = nil
      @selected_url_path = nil
      @selected_col = 0
      load_column_zero
    end

    def gallery_selected?
      @gallery_selected
    end
  end
end # SmugMugBrowser


class SmugMugUploadProtocol < OAuthUploadProtocol
  def connection
    @connection ||= SmugMugConnectionImageUpload.new(@bridge)
  end

  def upload(fname, remote_filename, spec)
    imgdat = @bridge.read_file_for_upload(fname)
    headers = { 'Content-Length' => imgdat.length.to_s,
                'Content-MD5' => Digest::MD5.hexdigest(imgdat).to_s,
                'Content-Type' => 'image/jpeg',
                'X-Smug-Version' => SMUG_VER,
                'X-Smug-ResponseType' => "JSON",
                #'X-Smug-AlbumID' => spec.album_key,
                'X-Smug-AlbumUri' => "/api/#{SMUG_VER}/album/#{spec.album_key}",
                'X-Smug-FileName' => remote_filename,
                'User-Agent' => 'Photo Mechanic'
              }

    begin
      connection.unmute_transfer_status
      response = connection.post("", imgdat, headers)
      connection.require_server_success_response(response)
      response_body = response.body
      SmugMugAddPhotoResponse.new(@bridge, response_body)
    ensure
      connection.mute_transfer_status
    end
  end
end # SmugMugUploadProtocol

