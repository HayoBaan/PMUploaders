#!/usr/bin/env ruby
##############################################################################
# Copyright (c) 2014 Camera Bits, Inc.  All rights reserved.
#
# Additional development by Hayo Baan
#
##############################################################################

TEMPLATE_DISPLAY_NAME = "Twitter"

##############################################################################

class TwitterConnectionSettings < OAuthConnectionSettings
  include PM::ConnectionSettingsTemplate # This also registers the class as Connection Settings
  
  def client
    @client ||= TwitterClient.new(@bridge)
  end
end

class TwitterFileUploaderUI < OAuthFileUploaderUI
  def operations_enabled?
    false
  end

  def create_controls(dlg)
    super

    create_control(:tweet_group_box,            GroupBox,       dlg, :label=> "Tweet:")
    create_control(:tweet_edit,                 EditControl,    dlg, :value=> "Tweeted with PhotoMechanic of @CameraBits", :multiline=>true, :persist=> true, :align => 'right')
    create_control(:tweet_length_static,        Static,         dlg, :label=> "140", :align => 'right')

    create_control(:transmit_group_box,        GroupBox,    dlg, :label=>"Transmit:")
    create_control(:send_original_radio,       RadioButton, dlg, :label=>"Original Photos")
    create_control(:send_jpeg_radio,           RadioButton, dlg, :label=>"Saved as JPEG", :checked=>true)
    RadioButton.set_exclusion_group(@send_original_radio, @send_jpeg_radio)
    create_control(:send_desc_edit,             EditControl,    dlg, :value=>"Note: #{TEMPLATE_DISPLAY_NAME}'s supported image formats are PNG, JPG and GIF. #{TEMPLATE_DISPLAY_NAME} removes all EXIF and IPTC data from uploaded images. If you'd like to retain credit, we recommend considering a watermark when sharing images on social media.", :multiline=>true, :readonly=>true, :persist=>false)
    create_jpeg_controls(dlg)
    create_image_processing_controls(dlg)
  end

  def layout_controls(container)
    super
    
    sh, eh = 20, 24

    container.layout_with_contents(@tweet_group_box, 0, container.base, -1, -1) do |c|
      c.set_prev_right_pad(5).inset(10,20,-10,-5).mark_base
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
end

class TwitterBackgroundDataFetchWorker < OAuthBackgroundDataFetchWorker
  def initialize(bridge, dlg)
    @client = TwitterClient.new(@bridge)
    super
  end

  def do_task
    return unless @dlg.account_parameters_dirty

    super
    @dlg.adjust_tweet_length_indicator
  end
end

class TwitterFileUploader < OAuthFileUploader
  include PM::FileUploaderTemplate  # This also registers the class as File Uploader

  def self.conn_settings_class
    TwitterConnectionSettings
  end

  def self.upload_protocol_class
    TwitterUploadProtocol
  end

  def self.background_data_fetch_worker_manager
    TwitterBackgroundDataFetchWorker
  end

  def initialize(pm_api_bridge, num_files, dlg_status_bridge, conn_settings_serializer)
    super
    # Twitter doesn't like it when you request the config too often so we hardcode this
    # max len = 140 - short url length (we take the https version)
    @max_tweet_length = 140-23
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

  def create_controls(dlg)
    @ui = TwitterFileUploaderUI.new(@bridge)
    @ui.create_controls(dlg)

    @ui.send_original_radio.on_click { adjust_controls }
    @ui.send_jpeg_radio.on_click { adjust_controls }

    @ui.dest_account_combo.on_sel_change { account_parameters_changed }
    @ui.tweet_edit.on_edit_change { adjust_tweet_length_indicator }

    add_jpeg_controls_event_hooks
    add_image_processing_controls_event_hooks

    @last_status_txt = nil

    create_data_fetch_worker
  end

  def imglink_url
    "https://www.twitter.com/"
  end

  protected

  def build_additional_upload_spec(spec, ui)
    spec.apply_stationery_pad = false
    spec.preserve_exif = false
    spec.save_transmitted_photos = false
    spec.do_rename = false
    spec.save_photos_subdir_type = 'specific'

    # Twitter doesn't allow concurrent uploads
    spec.max_concurrent_uploads = 1

    spec.tweet_bodies = get_tweet_bodies
    spec.max_tweet_length = @max_tweet_length
  end

  def get_tweet_bodies
    # Expand variables in tweets for each image
    tweet_bodies = {}
    tweet_bodies[0] = tweet_body if @num_files == 0 # Default to unexpanded text if no images provided
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
end

class TwitterConnection < OAuthConnection
  def initialize(pm_api_bridge)
    @base_url = 'https://api.twitter.com/'
    @api_key = 'n4ymCL7XJjI6d3FnfvRNwUv1X'
    @api_secret = '9lEB25A6LZGBKK5MY7ZW494jOC0bW0cpxmOjxW4ZTlutLY5YTg'
    super
  end
end

class TwitterClient < OAuthClient
  def connection
    @connection ||= TwitterConnection.new(@bridge)
  end
  
  def get_account_name(result)
    result['screen_name'].to_s
  end
end

class TwitterUploadProtocol < OAuthUploadProtocol
  def connection
    @connection ||= TwitterConnection.new(@bridge)
  end  
  
  def tweet_body(spec)
    tweet_body = spec.tweet_bodies[spec.unique_id]
    if tweet_body.jsize > spec.max_tweet_length
      body = ""
      i = 0
      tweet_body.each_char { |c| body += c if i < spec.max_tweet_length; i += 1 }
      tweet_body = body
    end
    tweet_body
  end

  def upload(fname, remote_filename, spec)
    fcontents = @bridge.read_file_for_upload(fname)
    mime = MimeMultipart.new
    mime.add_field("status", tweet_body(spec))
    mime.add_field("source", '<a href="http://store.camerabits.com">Photo Mechanic 5</a>')
    mime.add_field("include_entities", "true")
    mime.add_image("media[]", remote_filename, fcontents, "application/octet-stream")
    data, headers = mime.generate_data_and_headers

    begin
      @mute_transfer_status = false
      response = connection.post('1.1/statuses/update_with_media.json', data, headers)
      connection.require_server_success_response(response)
    ensure
      @mute_transfer_status = true
    end
  end
end
