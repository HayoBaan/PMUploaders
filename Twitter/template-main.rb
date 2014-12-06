#!/usr/bin/env ruby
##############################################################################
# Copyright (c) 2014 Camera Bits, Inc.  All rights reserved.
#
# Additional development by Hayo Baan
#
##############################################################################

TEMPLATE_DISPLAY_NAME = "Twitter"

##############################################################################

class TwitterConnectionSettingsUI

  include PM::Dlg
  include AutoAccessor
  include CreateControlHelper

  def initialize(pm_api_bridge)
    @bridge = pm_api_bridge
  end

  def create_controls(parent_dlg)
    dlg = parent_dlg
    create_control(:setting_name_static,      Static,       dlg, :label=>"Your Accounts:")
    create_control(:setting_name_combo,       ComboBox,     dlg, :editable=>false, :sorted=>true, :persist=>false)
    create_control(:setting_delete_button,    Button,       dlg, :label=>"Delete Account")
    create_control(:setting_add_button,       Button,       dlg, :label=>"Add/Replace Account")
    create_control(:add_account_instructions, Static,       dlg, :label=>"Note on ading an account: If you have an active Twitter session in your browser, Twitter will authorize Photo Mechanic for the account associated with that session. Otherwise, Twitter will prompt you to login.\nAfter authorizing Photo Mechanic, please enter the verification code below and press the Verify Code button. The account name will be determined automatically from your Twitter user name.")
    create_control(:code_group_box,           GroupBox,    dlg, :label=>"Verification code:")
    create_control(:code_edit,                EditControl, dlg, :value=>"Enter verification code", :persist=>false, :enabled=>false)
    create_control(:code_verify_button,       Button,      dlg, :label=>"Verify Code", :enabled=>false)
  end

  def layout_controls(container)
    sh, eh = 20, 24
    c = container
    c.set_prev_right_pad(5).inset(10,10,0,-10).mark_base
    c << @setting_name_static.layout(0, c.base, -1, sh)
    c.pad_down(0).mark_base
    c << @setting_name_combo.layout(0, c.base, -1, eh)
    c.pad_down(5).mark_base
    c << @setting_delete_button.layout(0, c.base, "50%-5", eh)
    c << @setting_add_button.layout("-50%+5", c.base, -1, eh)
    c.pad_down(5).mark_base
    c << add_account_instructions.layout(0, c.base, -1, 6*sh)
    c.pad_down(15).mark_base
    container.layout_with_contents(@code_group_box, 0, c.base, -1, -1) do |cc|
      cc.set_prev_right_pad(5).inset(15,20,-20,-5).mark_base
      cc << @code_edit.layout(0, cc.base, -125, eh)
      cc << @code_verify_button.layout(cc.prev_right+5, cc.base, 120, eh)
      cc.pad_down(5).mark_base
      cc.mark_base.size_to_base
    end
    c.pad_down(5).mark_base
    c.mark_base.size_to_base
  end
end

class TwitterConnectionSettings
  include PM::ConnectionSettingsTemplate

  DLG_SETTINGS_KEY = :connection_settings_dialog

  def self.template_display_name  # template name shown in dialog list box
    TEMPLATE_DISPLAY_NAME
  end

  def self.template_description  # shown in dialog box
    "Twitter Connection Settings"
  end

  def self.fetch_settings_data(serializer)
    dat = serializer.fetch(DLG_SETTINGS_KEY, :settings) || {}
    SettingsData.deserialize_settings_hash(dat)
  end

  def self.store_settings_data(serializer, settings)
    settings_dat = SettingsData.serialize_settings_hash(settings)
    serializer.store(DLG_SETTINGS_KEY, :settings, settings_dat)
  end

  def self.fetch_selected_settings_name(serializer)
    serializer.fetch(DLG_SETTINGS_KEY, :selected_item)  # might be nil
  end

  class SettingsData
    attr_accessor :auth_token, :auth_token_secret

    def initialize(name, token, token_secret)
      @account_name = name
      @auth_token = token
      @auth_token_secret = token_secret
      self
    end

    def appears_valid?
      return ! (@account_name.nil? || @account_name.empty? || @auth_token.nil? || @auth_token.empty? || @auth_token_secret.nil? || @auth_token_secret.empty?)
    rescue
      false
    end

    def self.serialize_settings_hash(settings)
      out = {}
      settings.each_pair do |key, dat|
        out[key] = [dat.auth_token, dat.auth_token_secret]
      end
      out
    end

    def self.deserialize_settings_hash(input)
      settings = {}
      input.each_pair do |key, dat|
        token, token_secret = dat
        settings[key] = SettingsData.new(key, token, token_secret)
      end
      settings
    end

  end

  def initialize(pm_api_bridge)
    @bridge = pm_api_bridge
    @prev_selected_settings_name = nil
    @settings = {}
  end

  def settings_selected_item
    serializer.fetch(DLG_SETTINGS_KEY, :selected_item)
  end

  def create_controls(parent_dlg)
    @ui = TwitterConnectionSettingsUI.new(@bridge)
    @ui.create_controls(parent_dlg)
    add_event_handlers
  end

  def add_event_handlers
    @ui.setting_name_combo.on_sel_change { handle_sel_change }
    @ui.setting_delete_button.on_click { handle_delete_button }
    @ui.setting_add_button.on_click { handle_add_account }
    @ui.code_verify_button.on_click { handle_code_verification }
  end

  def layout_controls(container)
    @ui.layout_controls(container)
  end

  def destroy_controls
    @ui = nil
  end

  def save_state(serializer)
    return unless @ui
    self.class.store_settings_data(serializer, @settings)
    serializer.store(DLG_SETTINGS_KEY, :selected_item, current_account_name)
  end

  def restore_state(serializer)
    @settings = self.class.fetch_settings_data(serializer)
    load_combo_from_settings
    select_previously_selected_account(serializer)
    select_first_account_if_none_selected
    store_selected_account
    load_current_values_from_settings
  end

  def select_previously_selected_account(serializer)
    @prev_selected_settings_name = serializer.fetch(DLG_SETTINGS_KEY, :selected_item)
    if @prev_selected_settings_name
      @ui.setting_name_combo.set_selected_item(@prev_selected_settings_name)
    end
  end

  def select_first_account_if_none_selected
    if @ui.setting_name_combo.get_selected_item.empty?  &&  @ui.setting_name_combo.num_items > 0
      @ui.setting_name_combo.set_selected_item( @ui.setting_name_combo.get_item_at(0) )
    end
  end

  def store_selected_account
    @prev_selected_settings_name = @ui.setting_name_combo.get_selected_item
    @prev_selected_settings_name = nil if @prev_selected_settings_name.empty?
  end

  def periodic_timer_callback
  end

  protected

  def load_combo_from_settings
    @ui.setting_name_combo.reset_content( @settings.keys )
  end

  def save_current_values_to_settings(params={:name=>nil, :replace=>true})
    key = params[:name] || current_account_name

    if key && key === String
      @settings[key] ||= SettingsData.new(key, nil, nil)
      key
    end
  end

  def current_account_name
    @ui.setting_name_combo.get_selected_item_text.to_s
  end

  def load_current_values_from_settings
    data = @settings[current_account_name]
  end

  def delete_in_settings(name)
    @settings.delete name
    @deleted = true
  end

  def add_account_to_dropdown(name = nil)
    save_current_values_to_settings(:name => name.to_s, :replace=>true)
    @ui.setting_name_combo.add_item(name.to_s)
    @ui.setting_name_combo.set_selected_item(name.to_s)
  end

  def handle_sel_change
    # NOTE: We rely fully on the prev. selected name here, because the
    # current selected name has already changed.
    if @prev_selected_settings_name
      save_current_values_to_settings(:name=>@prev_selected_settings_name, :replace=>true)
    end
    load_current_values_from_settings
    @prev_selected_settings_name = current_account_name
  end

  def clear_settings
    @ui.setting_name_combo.set_text ""
  end

  def client
    @client ||= TwitterClient.new(@bridge)
  end

  def handle_add_account
    # Enable code entry, disable delete and add
    @ui.code_verify_button.enable(true)
    @ui.code_edit.enable(true)
    @ui.code_edit.set_text("")
    @ui.code_edit.set_focus
    @ui.setting_delete_button.enable(false)
    @ui.setting_add_button.enable(false)
    client.reset!
    client.fetch_request_token
    client.launch_application_authorization_in_browser
    @prev_selected_settings_name = nil
  end

  def handle_code_verification
    code = @ui.code_edit.get_text.strip
    Dlg::MessageBox.ok("Please enter a non-blank code.", Dlg::MessageBox::MB_ICONEXCLAMATION) and return if code.empty?

    begin
      result = client.get_access_token(code)
      @settings[client.name]  = SettingsData.new(client.name, client.access_token, client.access_token_secret)
      add_account_to_dropdown(client.name)
    rescue
      # Note: A failed verification requires a complete new round of authorisation!
      Dlg::MessageBox.ok("Failed to verify code, please retry to add the account.", Dlg::MessageBox::MB_ICONEXCLAMATION)
    end

    # Disable code entry, enable delete and add
    @ui.code_verify_button.enable(false)
    @ui.code_edit.enable(false)
    @ui.code_edit.set_text("Verified #{client.name}")
    @ui.setting_delete_button.enable(true)
    @ui.setting_add_button.enable(true)
  end

  def handle_delete_button
    cur_name = current_account_name
    @ui.setting_name_combo.remove_item(cur_name) if @ui.setting_name_combo.has_item? cur_name
    delete_in_settings(cur_name)
    @prev_selected_settings_name = nil
    if @ui.setting_name_combo.num_items > 0
      @ui.setting_name_combo.set_selected_item( @ui.setting_name_combo.get_item_at(0) )
      handle_sel_change
    else
      clear_settings
    end
  end
end

class TwitterFileUploaderUI

  include PM::Dlg
  include AutoAccessor
  include CreateControlHelper
  include ImageProcessingControlsCreation
  include ImageProcessingControlsLayout
  include OperationsControlsCreation
  include OperationsControlsLayout

  SOURCE_RAW_LABEL = "Use the RAW"
  SOURCE_JPEG_LABEL = "Use the JPEG"

  def initialize(pm_api_bridge)
    @bridge = pm_api_bridge
  end

  def operations_enabled?
    false
  end

  def create_controls(parent_dlg)
    dlg = parent_dlg

    create_control(:dest_account_group_box,     GroupBox,       dlg, :label=>"Destination Twitter Account:")
    create_control(:dest_account_static,        Static,         dlg, :label=>"Account")
    create_control(:dest_account_combo,         ComboBox,       dlg, :sorted=>true, :persist=>false)

    create_control(:tweet_group_box,            GroupBox,       dlg, :label=> "Tweet:")
    #    create_control(:tweet_static,               Static,         dlg, :label=> "Compose Tweet:", :align => 'right')
    create_control(:tweet_edit,                 EditControl,    dlg, :value=> "Tweeted with PhotoMechanic of @CameraBits", :multiline=>true, :persist=> true, :align => 'right')
    create_control(:tweet_length_static,        Static,         dlg, :label=> "140", :align => 'right')

    create_control(:transmit_group_box,        GroupBox,    dlg, :label=>"Transmit:")
    create_control(:send_original_radio,       RadioButton, dlg, :label=>"Original Photos")
    create_control(:send_jpeg_radio,           RadioButton, dlg, :label=>"Saved as JPEG", :checked=>true)
    RadioButton.set_exclusion_group(@send_original_radio, @send_jpeg_radio)
    create_control(:send_desc_edit,             EditControl,    dlg, :value=>"Note: Twitter's supported image formats are PNG, JPG and GIF. Twitter removes all EXIF and IPTC data from uploaded images. If you'd like to retain credit, we recommend considering a watermark when sharing images on social media.", :multiline=>true, :readonly=>true, :persist=>false)
    create_jpeg_controls(dlg)
    create_image_processing_controls(dlg)
    #create_operations_controls(dlg)
  end

  def layout_controls(container)
    sh, eh = 20, 24

    container.inset(15, 5, -5, -5)

    container.layout_with_contents(@dest_account_group_box, 0, 0, -1, -1) do |c|
      c.set_prev_right_pad(5).inset(10,20,-10,-5).mark_base

      c << @dest_account_static.layout(0, c.base+3, 80, sh)
      c << @dest_account_combo.layout(c.prev_right, c.base, 200, eh)

      c.pad_down(5).mark_base
      c.mark_base.size_to_base
    end

    container.pad_down(5).mark_base

    container.layout_with_contents(@tweet_group_box, 0, container.base, -1, -1) do |c|
      c.set_prev_right_pad(5).inset(10,20,-10,-5).mark_base
      # c << @tweet_static.layout(0, c.base + 8, 100, sh)
      c << @tweet_edit.layout(0, c.base, "100%", eh*2)
      c.pad_down(2).mark_base
      c << @tweet_length_static.layout(-80, c.base, 80, sh)

      c.pad_down(5).mark_base
      c.mark_base.size_to_base
    end

    container.pad_down(5).mark_base
    container.mark_base.size_to_base

    container.layout_with_contents(@transmit_group_box, 0, container.base, "100%", -1) do |c|
      c.set_prev_right_pad(5).inset(10,20,-10,-5).mark_base

      c << @send_original_radio.layout(0, c.base, 120, eh)
      c << @send_jpeg_radio.layout(0, c.base+eh+5, 120, eh)
      c << @send_desc_edit.layout(c.prev_right+5, c.base, -1, 2*eh)
      c.pad_down(5).mark_base

      layout_jpeg_controls(c, eh, sh)
      c.pad_down(5).mark_base

      c.layout_with_contents(@imgproc_group_box, 0, c.base, -1, -1) do |cc|
        cc.set_prev_right_pad(5).inset(10,20,-10,-5).mark_base

        layout_image_processing_controls(cc, eh, sh, 80, 200, 120)

        cc.pad_down(5).mark_base
        cc.mark_base.size_to_base
      end

      c.pad_down(5).mark_base
      c.mark_base.size_to_base
    end

    container.pad_down(5).mark_base
    container.mark_base.size_to_base
  end

  def have_source_raw_jpeg_controls?
    defined?(@source_raw_jpeg_static) && defined?(@source_raw_jpeg_combo)
  end

  def raw_jpeg_render_source
    src = "JPEG"
    if have_source_raw_jpeg_controls?
      src = "RAW" if @source_raw_jpeg_combo.get_selected_item == SOURCE_RAW_LABEL
    end
    src
  end
end

class TwitterBackgroundDataFetchWorker
  def initialize(bridge, dlg)
    @bridge = bridge
    @dlg = dlg
    @client = TwitterClient.new(@bridge)
  end

  def do_task
    return unless @dlg.account_parameters_dirty

    acct = @dlg.current_account_settings
    if acct.nil?
      @dlg.set_status_text("Please select an account, or create one with the Connections button.")
    elsif ! acct.appears_valid?
      @dlg.set_status_text("Some account settings appear invalid or missing. Please click the Connections button.")
    elsif @dlg.num_files == 0
        @dlg.set_status_text("No images selected!")
    else
      @dlg.set_status_text("You are logged in and ready to upload your " + (@dlg.num_files > 1 ? "#{@dlg.num_files} images." : "image."))
    end
    @dlg.account_parameters_dirty = false
    @dlg.adjust_tweet_length_indicator
  end
end

class TwitterFileUploader
  include PM::FileUploaderTemplate
  include ImageProcessingControlsLogic
  include OperationsControlsLogic
  include RenamingControlsLogic
  include JpegSizeEstimationLogic
  include UpdateComboLogic
  include FormatBytesizeLogic
  include PreflightWaitAccountParametersLogic

  attr_accessor :account_parameters_dirty
  attr_reader :num_files, :ui, :max_tweet_length

  DLG_SETTINGS_KEY = :upload_dialog

  def self.template_display_name
    TEMPLATE_DISPLAY_NAME
  end

  def self.template_description
    "Tweet an image"
  end

  def self.conn_settings_class
    TwitterConnectionSettings
  end

  def initialize(pm_api_bridge, num_files, dlg_status_bridge, conn_settings_serializer)
    @bridge = pm_api_bridge
    @num_files = num_files
    @dlg_status_bridge = dlg_status_bridge
    @conn_settings_ser = conn_settings_serializer
    @last_status_txt = nil
    @account_parameters_dirty = false
    @data_fetch_worker = nil
    # Twitter doesn't like it when you request the config too often so we hard code this
    # max len = 140 - short url length (we take the https version just to be sure)
    @max_tweet_length = 140-23
  end

  def upload_files(global_spec, progress_dialog)
    raise "upload_files called with no @ui instantiated" unless @ui
    acct = current_account_settings
    raise "Failed to load settings for current account. Please click the Connections button." unless acct
    spec = build_upload_spec(acct, @ui)

    # Expand any variables in the tweet text, per image
    build_tweet_spec(spec, ui)

    @bridge.kickoff_template_upload(spec, TwitterUploadProtocol)
  end

  def preflight_settings(global_spec)
    raise "preflight_settings called with no @ui instantiated" unless @ui

    acct = current_account_settings
    raise "Failed to load settings for current account. Please click the Connections button." unless acct
    raise "Some account settings appear invalid or missing. Please click the Connections button." unless acct.appears_valid?

    preflight_jpeg_controls
    preflight_wait_account_parameters_or_timeout

    build_upload_spec(acct, @ui)
  end

  def create_controls(parent_dlg)
    @ui = TwitterFileUploaderUI.new(@bridge)
    @ui.create_controls(parent_dlg)

    @ui.send_original_radio.on_click { adjust_controls }
    @ui.send_jpeg_radio.on_click { adjust_controls }

    @ui.dest_account_combo.on_sel_change { account_parameters_changed }
    @ui.tweet_edit.on_edit_change { adjust_tweet_length_indicator }

    add_jpeg_controls_event_hooks
    add_image_processing_controls_event_hooks
    #add_operations_controls_event_hooks
    #set_seqn_static_to_current_seqn

    @last_status_txt = nil

    create_data_fetch_worker
  end

  def get_tweet_bodies
    # Expand variables in tweets for each image
    tweet_bodies = {}
    tweet_bodies[0] = tweet_body if @num_files == 0 # default to unexpanded text if no images provided
    @num_files.times do |i|
      unique_id = @bridge.get_item_unique_id(i+1)
      tweet_bodies[unique_id] = @bridge.expand_vars(tweet_body, i+1)
    end
    tweet_bodies
  end

  def adjust_tweet_length_indicator
    tweet_bodies = get_tweet_bodies
    remaining = @max_tweet_length - (tweet_bodies.map { |i, t| t.jsize }).max
    @ui.tweet_length_static.set_text(remaining.to_s)
  end

  def tweet_body
    @ui.tweet_edit.get_text
  end

  def layout_controls(container)
    @ui.layout_controls(container)
  end

  def destroy_controls
    destroy_data_fetch_worker
    @ui = nil
  end

  def reset_active_account
    account_parameters_changed
  end

  def save_state(serializer)
    return unless @ui
    serializer.store(DLG_SETTINGS_KEY, :selected_account, @ui.dest_account_combo.get_selected_item)
  end

  def restore_state(serializer)
    reset_account_combo_from_settings
    select_previous_account(serializer)
    select_first_available_if_present
    account_parameters_changed
    adjust_controls
  end

  def reset_account_combo_from_settings
    data = fetch_conn_settings_data
    @ui.dest_account_combo.reset_content( data.keys )
  end

  def select_previous_account(serializer)
    prev_selected_account = serializer.fetch(DLG_SETTINGS_KEY, :selected_account)
    @ui.dest_account_combo.set_selected_item(prev_selected_account) if prev_selected_account
  end

  def select_first_available_if_present
    if @ui.dest_account_combo.get_selected_item.empty?  &&  @ui.dest_account_combo.num_items > 0
      @ui.dest_account_combo.set_selected_item( @ui.dest_account_combo.get_item_at(0) )
    end
  end

  def periodic_timer_callback
    return unless @ui
    @data_fetch_worker.exec_messages
    handle_jpeg_size_estimation
  end

  def set_status_text(txt)
    if txt != @last_status_txt
      @dlg_status_bridge.set_text(txt)
      @last_status_txt = txt
    end
  end

  def update_account_combo_list
    data = fetch_conn_settings_data
    @ui.dest_account_combo.reset_content( data.keys )
  end

  def select_active_account
    selected_settings_name = TwitterConnectionSettings.fetch_selected_settings_name(@conn_settings_ser)
    if selected_settings_name
      @ui.dest_account_combo.set_selected_item( selected_settings_name )
    end

    # If selection didn't take, and we have items in the list, just pick the 1st one
    if @ui.dest_account_combo.get_selected_item.empty? &&  @ui.dest_account_combo.num_items > 0
      @ui.dest_account_combo.set_selected_item( @ui.dest_account_combo.get_item_at(0) )
    end
  end

  # Called by the framework after user has closed the Connection Settings dialog.
  def connection_settings_edited(conn_settings_serializer)
    @conn_settings_ser = conn_settings_serializer

    update_account_combo_list
    select_active_account
    account_parameters_changed
  end

  def account
    @account = current_account_settings
  end

  def account_valid?
    ! (account_empty? || account_invalid?)
  end

  def disable_ui
    @ui.send_button.enable(false)
  end

  def imglink_button_spec
    { :filename => "logo.tif", :bgcolor => "ffffff" }
  end

  def imglink_url
    "https://www.twitter.com/"
  end

  protected

  def create_data_fetch_worker
    qfac = lambda { @bridge.create_queue }
    @data_fetch_worker = BackgroundDataFetchWorkerManager.new(TwitterBackgroundDataFetchWorker, qfac, [@bridge, self])
  end

  def destroy_data_fetch_worker
    if @data_fetch_worker
      @data_fetch_worker.terminate
      @data_fetch_worker = nil
    end
  end

  def display_message_box(text)
    Dlg::MessageBox.ok(text, Dlg::MessageBox::MB_ICONEXCLAMATION)
  end

  def adjust_controls
    adjust_image_processing_controls
  end

  def build_upload_spec(acct, ui)
    spec = AutoStruct.new

    # String displayed in upload progress dialog title bar:
    spec.upload_display_name  = "twitter.com:#{ui.dest_account_combo.get_selected_item}"
    # String used in logfile name, should have NO spaces or funky characters:
    spec.log_upload_type      = TEMPLATE_DISPLAY_NAME.tr('^A-Za-z0-9_-','')
    # Account string displayed in upload log entries:
    spec.log_upload_acct      = spec.upload_display_name

    # Token and secret
    spec.token = account.auth_token
    spec.token_secret = account.auth_token_secret

    # FIXME: we're limiting concurrent uploads to 1 because
    #        end of queue notification happens per uploader thread
    #        and we can still be uploading, causing
    #        partially transmitted files get prematurely
    #        harvested on the server side
    spec.max_concurrent_uploads = 1

    spec.num_files = @num_files

    # NOTE: upload_queue_key should be unique for a given protocol,
    #       and a given upload "account".
    #       Rule of thumb: If file A requires a different
    #       login than file B, they should have different
    #       queue keys.
    spec.upload_queue_key = [
      "Twitter"
    ].join("\t")

    spec.upload_processing_type = ui.send_original_radio.checked? ? "originals_jpeg_only" : "save_as_jpeg"
    spec.send_incompatible_originals_as = "JPEG"
    spec.send_wav_files = false

    spec.apply_stationery_pad = false
    spec.preserve_exif = false
    spec.save_transmitted_photos = false
    spec.do_rename = false
    spec.save_photos_subdir_type = 'specific'

    build_jpeg_spec(spec, ui)
    build_image_processing_spec(spec, ui)

    spec
  end

  def build_tweet_spec(spec, ui)
    spec.tweet_bodies = get_tweet_bodies
    spec.max_tweet_length = @max_tweet_length
  end

  def fetch_conn_settings_data
    TwitterConnectionSettings.fetch_settings_data(@conn_settings_ser)
  end

  def current_account_settings
    acct_name = @ui.dest_account_combo.get_selected_item
    data = fetch_conn_settings_data
    settings = data ? data[acct_name] : nil
  end

  def tokens_present?
    account && account.appears_valid?
  end

  def account_empty?
    if account.nil?
      notify_account_missing
      return true
    else
      return false
    end
  end

  def account_invalid?
    if account && account.appears_valid?
      return false
    else
      notify_account_invalid
      return true
    end
  end

  def notify_account_missing
    set_status_text("Please select an account, or create one with the Connections button.")
  end

  def notify_account_invalid
    set_status_text("You need to authorize your account.")
  end

  def account_parameters_changed
    @account = nil
    @account_parameters_dirty = true
  end
end

class TwitterClient
  BASE_URL = "https://api.twitter.com/"
  API_KEY = 'n4ymCL7XJjI6d3FnfvRNwUv1X'
  API_SECRET = '9lEB25A6LZGBKK5MY7ZW494jOC0bW0cpxmOjxW4ZTlutLY5YTg'

  attr_accessor :access_token, :access_token_secret, :name

  def initialize(bridge, options = {})
    @bridge = bridge
  end

  def reset!
    @access_token = nil
    @access_token_secret = nil
    @name = nil
  end

  def fetch_request_token
    response = post('oauth/request_token')

    result = CGI::parse(response.body)
    @access_token = result['oauth_token'].to_s
    @access_token_secret = result['oauth_token_secret'].to_s
    @access_token
  end

  def launch_application_authorization_in_browser
    fetch_request_token unless @access_token
    authorization_url = "https://api.twitter.com/oauth/authorize?oauth_token=#{@access_token}"
    @bridge.launch_url(authorization_url)
  end

  def get_access_token(verifier)
    @verifier = verifier
    response = post('oauth/access_token')
    result = CGI::parse(response.body)
    @access_token = result['oauth_token'].to_s
    @access_token_secret = result['oauth_token_secret'].to_s

    raise "Unable to verify code" unless authenticated?

    @name = result['screen_name'].to_s

    [ @access_token, @access_token_secret, @name ]
  end

  def authenticate_from_settings(settings = {})
    @access_token = settings[:token]
    @access_token_secret = settings[:token_secret]
    @name = settings[:name]
  end

  def update_ui
    @dialog.reset_active_account
  end

  def authenticated?
    !(@access_token.nil? || @access_token.empty? || @access_token_secret.nil? || @access_token_secret.empty?)
  end

  def store_settings_data(token, token_secret, name)
    @access_token = token
    @access_token_secret = token_secret
    @name = name
  end

  protected

  def request_headers(method, url, params = {}, signature_params = params)
    {'Authorization' => auth_header(method, url, params, signature_params)}
  end

  def auth_header(method, url, params = {}, signature_params = params)
    oauth_auth_header(method, url, signature_params).to_s
  end

  def oauth_auth_header(method, uri, params = {})
    uri = URI.parse(uri)
    SimpleOAuth::Header.new(method, uri, params, credentials)
  end

  def credentials
    {
      :consumer_key    => API_KEY,
      :consumer_secret => API_SECRET,
      :token           => @access_token,
      :token_secret    => @access_token_secret,
      :verifier        => @verifier,
      :callback        => 'oob'
    }
  end

  # todo: handle timeout
  def ensure_open_http(host, port)
    unless @http
      @http = @bridge.open_http_connection(host, port)
      @http.use_ssl = true
      @http.open_timeout = 60
      @http.read_timeout = 180
    end
  end

  def close_http
    if @http
      @http.finish rescue nil
      @http = nil
    end
  end

  def get(path, params = {})
    headers = request_headers(:get, BASE_URL + path, params, {})
    request(:get, path, params, headers)
  end

  def post(path, params = {}, upload_headers = {})
    uri = BASE_URL + path
    headers = request_headers(:post, uri, params, {})
    headers.merge!(upload_headers)
    request(:post, path, params, headers)
  end

  def request(method, path, params = {}, headers = {})
    url = BASE_URL + path
    uri = URI.parse(url)
    ensure_open_http(uri.host, uri.port)

    if method == :get
      @http.send(method.to_sym, uri.request_uri, headers)
    else
      @http.send(method.to_sym, uri.request_uri, params, headers)
    end
  end

  def require_server_success_response(resp)
    raise(RuntimeError, resp.inspect) unless resp.code == "200"
  end
end

class TwitterUploadProtocol
  BASE_URL = "https://api.twitter.com/"
  API_KEY = 'n4ymCL7XJjI6d3FnfvRNwUv1X'
  API_SECRET = '9lEB25A6LZGBKK5MY7ZW494jOC0bW0cpxmOjxW4ZTlutLY5YTg'

  attr_reader :access_token, :access_token_secret

  def initialize(pm_api_bridge, options = {:connection_settings_serializer => nil, :dialog => nil})
    @bridge = pm_api_bridge
    @shared = @bridge.shared_data
    @http = nil
    @access_token = nil
    @access_token_secret = nil
    @dialog = options[:dialog]
    @connection_settings_serializer = options[:connection_settings_serializer]
    mute_transfer_status
    close
  end

  def mute_transfer_status
    # we may make multiple requests while uploading a file, and
    # don't want the progress bar to jump around until we get
    # to the actual upload
    @mute_transfer_status = true
  end

  def close
    # close_http
  end

  def reset!
    @access_token = nil
    @access_token_secret = nil
  end

  def image_upload(local_filepath, remote_filename, is_retry, spec)
    @bridge.set_status_message "Uploading via secure connection..."

    @access_token = spec.token
    @access_token_secret = spec.token_secret

    upload(local_filepath, remote_filename, spec)

    @shared.mutex.synchronize {
      dat = (@shared[spec.upload_queue_key] ||= {})
      dat[:pending_uploadjob] ||= 0
      dat[:pending_uploadjob] += 1
    }

    remote_filename
  end

  def transfer_queue_empty(spec)
    @shared.mutex.synchronize {
      dat = (@shared[spec.upload_queue_key] ||= {})

      if dat[:pending_uploadjob].to_i > 0
        dat[:pending_uploadjob] = 0
      end
    }
  end

  def reset_transfer_status
    (h = @http) and h.reset_transfer_status
  end

  # return [bytes_to_write, bytes_written]
  def poll_transfer_status
    if (h = @http)  &&  ! @mute_transfer_status
      [h.bytes_to_write, h.bytes_written]
    else
      [0, 0]
    end
  end

  def abort_transfer
    (h = @http) and h.abort_transfer
  end

  def upload(fname, remote_filename, spec)
    fcontents = @bridge.read_file_for_upload(fname)

    tweet_body = spec.tweet_bodies[spec.unique_id]
    if tweet_body.jsize > spec.max_tweet_length
      body = ""
      i = 0
      tweet_body.each_char { |c| body += c if i < spec.max_tweet_length; i += 1 }
      tweet_body = body
    end
    mime = MimeMultipart.new
    mime.add_field("status", tweet_body)
    mime.add_field("source", '<a href="http://store.camerabits.com">Photo Mechanic 5</a>')
    mime.add_field("include_entities", "true")
    mime.add_image("media[]", remote_filename, fcontents, "application/octet-stream")

    data, headers = mime.generate_data_and_headers

    begin
      @mute_transfer_status = false
      resp = post('1.1/statuses/update_with_media.json', data, headers)
      require_server_success_response(resp)
    ensure
      @mute_transfer_status = true
    end
  end

  def authenticate_from_settings(settings = {})
    @access_token = settings[:token]
    @access_token_secret = settings[:token_secret]
  end

  protected

  def request_headers(method, url, params = {}, signature_params = params)
    {'Authorization' => auth_header(method, url, params, signature_params)}
  end

  def auth_header(method, url, params = {}, signature_params = params)
    oauth_auth_header(method, url, signature_params).to_s
  end

  def oauth_auth_header(method, uri, params = {})
    uri = URI.parse(uri)
    SimpleOAuth::Header.new(method, uri, params, credentials)
  end

  def credentials
    {
      :consumer_key    => API_KEY,
      :consumer_secret => API_SECRET,
      :token           => @access_token,
      :token_secret    => @access_token_secret,
      :verifier        => @verifier,
      :callback        => 'oob'
    }
  end

  # todo: handle timeout
  def ensure_open_http(host, port)
    unless @http
      @http = @bridge.open_http_connection(host, port)
      @http.use_ssl = true
      @http.open_timeout = 60
      @http.read_timeout = 180
    end
  end

  def close_http
    if @http
      @http.finish rescue nil
      @http = nil
    end
  end

  def get(path, params = {})
    headers = request_headers(:get, BASE_URL + path, params, {})
    request(:get, path, params, headers)
  end

  def post(path, params = {}, upload_headers = {})
    uri = BASE_URL + path
    headers = request_headers(:post, uri, params, {})
    headers.merge!(upload_headers)
    request(:post, path, params, headers)
  end

  def request(method, path, params = {}, headers = {})
    url = BASE_URL + path
    uri = URI.parse(url)
    ensure_open_http(uri.host, uri.port)

    if method == :get
      @http.send(method.to_sym, uri.request_uri, headers)
    else
      @http.send(method.to_sym, uri.request_uri, params, headers)
    end
  end

  def require_server_success_response(resp)
    raise(RuntimeError, resp.inspect) unless resp.code == "200"
  end
end
