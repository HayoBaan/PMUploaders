#!/usr/bin/env ruby
# coding: utf-8
##############################################################################
#
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
  def create_controls(dlg)
    super

    create_control(:tweet_group_box,         GroupBox,    dlg, :label=> "Tweet:")
    create_control(:tweet_edit,              EditControl, dlg, :value=> "Tweeted with Photo Mechanic of @CameraBits", :multiline=>true, :persist=> true, :align => 'right')
    create_control(:tweet_length_static,     Static,      dlg, :label=> "140", :align => 'right')
    create_control(:tweet_sensitive_check,   CheckBox,    dlg, :label=> "Possibly sensitive?")
    create_control(:tweet_coordinates_check, CheckBox,    dlg, :label=> "Display excat coordinates?")
    create_control(:tweet_latitude_static,   Static,      dlg, :label=> "Latitude:")
    create_control(:tweet_latitude_edit,     EditControl, dlg, :value=> "{latitude}", :multiline=>false)
    create_control(:tweet_longitude_static,  Static,      dlg, :label=> "Longitude:")
    create_control(:tweet_longitude_edit,    EditControl, dlg, :value=> "{longitude}", :multiline=>false)

    create_processing_controls(dlg)
  end

  def layout_controls(container)
    super
    
    sh, eh, w = 20, 24, 160

    container.layout_with_contents(@tweet_group_box, 0, container.base, -1, -1) do |c|
      c.set_prev_right_pad(5).inset(10,20,-10,-5).mark_base
      c << @tweet_edit.layout(0, c.base, -1, eh*2)
      c.pad_down(2).mark_base
      c << @tweet_length_static.layout(-80, c.base, -1, sh)
      c << @tweet_latitude_static.layout(200, c.base+3, w, sh)
      c << @tweet_longitude_static.layout(c.prev_right+10, c.base+3, w, sh)
      c.pad_down(0).mark_base
      c << @tweet_coordinates_check.layout(0, c.base, 200, sh)
      c << @tweet_latitude_edit.layout(200, c.base, w, eh)
      c << @tweet_longitude_edit.layout(c.prev_right+10, c.base, w, eh)
      c.pad_down(5).mark_base
      c << @tweet_sensitive_check.layout(0, c.base, 200, sh)

      c.pad_down(5).mark_base
      c.mark_base.size_to_base
    end

    container.pad_down(5).mark_base
    container.mark_base.size_to_base

    layout_processing_controls(container)
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

  def self.file_uploader_ui_class
    TwitterFileUploaderUI
  end
  
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

  def create_controls(dlg)
    super
    @ui.tweet_edit.on_edit_change { adjust_tweet_length_indicator }
  end

  def imglink_url
    "https://www.twitter.com/"
  end

  protected

  def build_additional_upload_spec(spec, ui)
    # Twitter doesn't allow concurrent uploads
    spec.max_concurrent_uploads = 1

    spec.tweet_info = get_tweet_info
    spec.tweet_sensitive = @ui.tweet_sensitive_check.checked? ? "true" : "false"
    spec.tweet_coordinates = @ui.tweet_coordinates_check.checked? ? "true" : "false"
    spec.max_tweet_length = @max_tweet_length
  end

  def create_image_tweet_info(body, lat="", long="")
    { "body" => body, "lat" => convert_gps_coordinate(lat), "long" => convert_gps_coordinate(long) }
  end

  def get_tweet_info
    # Expand variables in tweets for each image
    tweet_body = @ui.tweet_edit.get_text
    tweet_latitude = @ui.tweet_latitude_edit.get_text
    tweet_longitude = @ui.tweet_longitude_edit.get_text
    tweet_info = {}
    tweet_info[0] = create_image_tweet_info(tweet_body) if @num_files == 0 # Default to unexpanded text if no images provided
    @num_files.times do |i|
      unique_id = @bridge.get_item_unique_id(i+1)
      tweet_info[unique_id] = create_image_tweet_info(@bridge.expand_vars(tweet_body, i+1), @bridge.expand_vars(tweet_latitude, i+1), @bridge.expand_vars(tweet_longitude, i+1))
    end
    tweet_info
  end

  def adjust_tweet_length_indicator
    tweet_info = get_tweet_info
    remaining = @max_tweet_length - (tweet_info.map { |i, t| t["body"].jsize }).max
    @ui.tweet_length_static.set_text(remaining.to_s)
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
    tweet_body = spec.tweet_info[spec.unique_id]["body"]
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
    mime.add_field("possibly_sensitive", spec.tweet_sensitive)
    mime.add_field("display_coordinates", spec.tweet_coordinates)
    mime.add_field("lat", spec.tweet_info[spec.unique_id]["lat"])
    mime.add_field("long", spec.tweet_info[spec.unique_id]["long"])
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
