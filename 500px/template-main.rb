#!/usr/bin/env ruby
# coding: utf-8
##############################################################################
#
# Copyright (c) 2014 Camera Bits, Inc.  All rights reserved.
#
# Developed by Hayo Baan
#
##############################################################################

TEMPLATE_DISPLAY_NAME = "500px"

##############################################################################

class U500pxConnectionSettings < OAuthConnectionSettings
  include PM::ConnectionSettingsTemplate # This also registers the class as Connection Settings
  
  def client
    @client ||= U500pxClient.new(@bridge)
  end
end

class U500pxFileUploaderUI < OAuthFileUploaderUI
  def metadata_safe?
    true
  end

  def valid_file_types
    [ "JPEG" ]
  end

  def initial_control
    @meta_name_edit
  end

  def create_controls(dlg)
    super
    create_control(:gallery_group_box,         GroupBox,    dlg, :label=>"Create new 500px Gallery:")
    create_control(:gallery_name_static,       Static,      dlg, :label=>"Gallery Name:")
    create_control(:gallery_name_edit,         EditControl, dlg, :value=>"", :multiline=>false)
    create_control(:gallery_privacy_check,     CheckBox,    dlg, :label=>"Privacy")
    create_control(:gallery_create_btn,        Button,      dlg, :label=>"Create Gallery")
    create_control(:gallery_status_static,     Static,      dlg, :label=>"")
    
    create_control(:meta_left_group_box,       GroupBox,    dlg, :label=>"500px Metadata:")
    create_control(:meta_gallery_static,       Static,      dlg, :label=>"Gallery:")
    create_control(:meta_gallery_combo,        ComboBox,    dlg, :items=>[])
    create_control(:meta_category_static,      Static,      dlg, :label=>"Category:")
    create_control(:meta_category_combo,       ComboBox,    dlg, :items=>[
                     "00 - Uncategorized",
                     "10 - Abstract",
                     "11 - Animals",
                     "05 - Black and White",
                     "01 - Celebrities",
                     "09 - City and Architecture",
                     "15 - Commercial",
                     "16 - Concert",
                     "20 - Family",
                     "14 - Fashion",
                     "02 - Film",
                     "24 - Fine Art",
                     "23 - Food",
                     "03 - Journalism",
                     "08 - Landscapes",
                     "12 - Macro",
                     "18 - Nature",
                     "04 - Nude",
                     "07 - People",
                     "19 - Performing Arts",
                     "17 - Sport",
                     "06 - Still Life",
                     "21 - Street",
                     "26 - Transportation",
                     "13 - Travel",
                     "22 - Underwater",
                     "27 - Urban Exploration",
                     "25 - Wedding"
                   ], :selected=>"00 - Uncategorized", :sorted=>false, :persist=>true)
    create_control(:meta_nsfw_check,           CheckBox,    dlg, :label=>"NotSafeForWork")
    create_control(:meta_license_type_static,  Static,      dlg, :label=>"License:")
    create_control(:meta_license_type_combo,   ComboBox,    dlg, :items=>[
                     "00 - 500px License",
                     "04 - Attribution 3.0",
                     "05 - Attribution-NoDerivs 3.0",
                     "06 - Attribution-ShareAlike 3.0",
                     "01 - Attribution-NonCommercial 3.0",
                     "02 - Attribution-NonCommercial-NoDerivs 3.0",
                     "03 - Attribution-NonCommercial-ShareAlike 3.0"
                     # Names in api documentation:
                     # "00 - Standard 500px License",
                     # "04 - Creative Commons License Attribution",
                     # "05 - Creative Commons License No Derivatives",
                     # "06 - Creative Commons License Share Alike",
                     # "01 - Creative Commons License Non Commercial Attribution",
                     # "02 - Creative Commons License Non Commercial No Derivatives",
                     # "03 - Creative Commons License Non Commercial Share Alike"
                   ], :selected=>"00 - Standard 500px License", :sorted=>false, :persist=>true)
    create_control(:meta_privacy_check,        CheckBox,    dlg, :label=>"Privacy")
    create_control(:meta_name_static,          Static,      dlg, :label=>"Name:")
    create_control(:meta_name_edit,            EditControl, dlg, :value=>"{headline}", :multiline=>true)
    create_control(:meta_description_static,   Static,      dlg, :label=>"Description:")
    create_control(:meta_description_edit,     EditControl, dlg, :value=>"{caption}", :multiline=>true)
    create_control(:meta_tags_static,          Static,      dlg, :label=>"Tags:")
    create_control(:meta_tags_edit,            EditControl, dlg, :value=>"{keywords}", :multiline=>true)

    create_control(:meta_right_group_box,      GroupBox,    dlg, :label=>"500px Metadata:")
    create_control(:meta_camera_static,        Static,      dlg, :label=>"Camera:")
    create_control(:meta_camera_edit,          EditControl, dlg, :value=>"{model}", :multiline=>false)
    create_control(:meta_lens_static,          Static,      dlg, :label=>"Lens:")
    create_control(:meta_lens_edit,            EditControl, dlg, :value=>"{lenstype}", :multiline=>false)
    create_control(:meta_focal_length_static,  Static,      dlg, :label=>"Focal length:")
    create_control(:meta_focal_length_edit,    EditControl, dlg, :value=>"{lens}", :multiline=>false)
    create_control(:meta_aperture_static,      Static,      dlg, :label=>"Aperture:")
    create_control(:meta_aperture_edit,        EditControl, dlg, :value=>"{aperture}", :multiline=>false)
    create_control(:meta_shutter_speed_static, Static,      dlg, :label=>"Shutter:")
    create_control(:meta_shutter_speed_edit,   EditControl, dlg, :value=>"{shutter}", :multiline=>false)
    create_control(:meta_iso_static,           Static,      dlg, :label=>"ISO:")
    create_control(:meta_iso_edit,             EditControl, dlg, :value=>"{iso}", :multiline=>false)
    create_control(:meta_taken_at_static,      Static,      dlg, :label=>"Taken at")
    create_control(:meta_taken_at_edit,        EditControl, dlg, :value=>"{day0}/{month0}/{year4} {time}", :multiline=>false)
    create_control(:meta_latitude_static,      Static,      dlg, :label=>"Latitude:")
    create_control(:meta_latitude_edit,        EditControl, dlg, :value=>"{latitude}", :multiline=>false)
    create_control(:meta_longitude_static,     Static,      dlg, :label=>"Longitude:")
    create_control(:meta_longitude_edit,       EditControl, dlg, :value=>"{longitude}", :multiline=>false)

    create_processing_controls(dlg)
  end

  def layout_controls(container)
    super
    
    sh, eh = 20, 24

    container.layout_with_contents(@gallery_group_box, 0, container.base, -1, -1) do |c|
      c.set_prev_right_pad(5).inset(10,20,-10,-5).mark_base
      c << @gallery_name_static.layout(0, c.base+3, 80, sh)
      c << @gallery_name_edit.layout(c.prev_right, c.base, "50%-15", eh)
      c << @gallery_privacy_check.layout("50%+15", c.base, -1, sh)
      c.pad_down(5).mark_base
      c << @gallery_create_btn.layout(80+5, c.base, 120, eh)
      c << @gallery_status_static.layout(c.prev_right+5, c.base+3, -1, sh)
      c.pad_down(5).mark_base
      
      c.mark_base.size_to_base
    end

    container.pad_down(5).mark_base
    container.mark_base.size_to_base
       
    container.layout_with_contents(@meta_left_group_box, 0, container.base, "50%-5", -1) do |c|
      c.set_prev_right_pad(5).inset(10,20,-10,-5).mark_base
      c << @meta_gallery_static.layout(0, c.base+3, 80, sh)
      c << @meta_gallery_combo.layout(c.prev_right, c.base, -1, eh)
      c.pad_down(5).mark_base
      
      c << @meta_category_static.layout(0, c.base+3, 80, sh)
      c << @meta_category_combo.layout(c.prev_right, c.base, 193, eh)
      c << @meta_nsfw_check.layout(c.prev_right+10, c.base, -1, sh)
      c.pad_down(5).mark_base

      c << @meta_license_type_static.layout(0, c.base+3, 80, sh)
      c << @meta_license_type_combo.layout(c.prev_right, c.base, 193, eh)
      c << @meta_privacy_check.layout(c.prev_right+10, c.base, -1, sh)
      c.pad_down(5).mark_base

      c.pad_down(1).mark_base # Not sure why this one is neceassary to line up left and right...

      c << @meta_name_static.layout(0, c.base, 80, sh)
      c << @meta_name_edit.layout(c.prev_right, c.base, -1, eh*2+4) # Again, 4 instead of 5 to make it line-up perfectly...
      c.pad_down(5).mark_base

      c << @meta_description_static.layout(0, c.base, 80, sh)
      c << @meta_description_edit.layout(c.prev_right, c.base, -1, eh*4+12) # And again, 11 instead of 10 to make it line-up perfectly...
      c.pad_down(5).mark_base

      c << @meta_tags_static.layout(0, c.base, 80, sh)
      c << @meta_tags_edit.layout(c.prev_right, c.base, -1, eh*2+5)
      c.pad_down(5).mark_base

      c.mark_base.size_to_base
    end

    container.layout_with_contents(@meta_right_group_box, "-50%+5", container.base, -1, -1) do |c|
      c.set_prev_right_pad(5).inset(10,20,-10,-5).mark_base

      # Not sure why this one is neceassary to line up left and right...
      c.pad_down(1).mark_base

      c << @meta_camera_static.layout(0, c.base, 80, sh)
      c << @meta_camera_edit.layout(c.prev_right, c.base, -1, eh)
      c.pad_down(5).mark_base
      c << @meta_lens_static.layout(0, c.base, 80, sh)
      c << @meta_lens_edit.layout(c.prev_right, c.base, -1, eh)
      c.pad_down(5).mark_base
      c << @meta_focal_length_static.layout(0, c.base, 80, sh)
      c << @meta_focal_length_edit.layout(c.prev_right, c.base, -1, eh)
      c.pad_down(5).mark_base
      c << @meta_aperture_static.layout(0, c.base, 80, sh)
      c << @meta_aperture_edit.layout(c.prev_right, c.base, -1, eh)
      c.pad_down(5).mark_base
      c << @meta_shutter_speed_static.layout(0, c.base, 80, sh)
      c << @meta_shutter_speed_edit.layout(c.prev_right, c.base, -1, eh)
      c.pad_down(5).mark_base
      c << @meta_iso_static.layout(0, c.base, 80, sh)
      c << @meta_iso_edit.layout(c.prev_right, c.base, -1, eh)
      c.pad_down(5).mark_base
      c << @meta_taken_at_static.layout(0, c.base, 80, sh)
      c << @meta_taken_at_edit.layout(c.prev_right, c.base, -1, eh)
      c.pad_down(5).mark_base
      c << @meta_latitude_static.layout(0, c.base, 80, sh)
      c << @meta_latitude_edit.layout(c.prev_right, c.base, -1, eh)
      c.pad_down(5).mark_base
      c << @meta_longitude_static.layout(0, c.base, 80, sh)
      c << @meta_longitude_edit.layout(c.prev_right, c.base, -1, eh)
      c.pad_down(5).mark_base
      c.pad_down(eh*2+9).mark_base # And again, 4 extra to get it to line-up
      c.mark_base.size_to_base
    end

    container.pad_down(5).mark_base
    container.mark_base.size_to_base

    layout_processing_controls(container)
  end
end

class U500pxBackgroundDataFetchWorker < OAuthBackgroundDataFetchWorker
  def connection
    @connection ||= U500pxConnection.new(@bridge)
  end
   
  def initialize(bridge, dlg)
    @client = U500pxClient.new(@bridge)
    super
  end
end

class U500pxFileUploader < OAuthFileUploader
  include PM::FileUploaderTemplate  # This also registers the class as File Uploader

  def self.file_uploader_ui_class
    U500pxFileUploaderUI
  end
  
  def self.conn_settings_class
    U500pxConnectionSettings
  end

  def self.upload_protocol_class
    U500pxUploadProtocol
  end

  def self.background_data_fetch_worker_manager
    U500pxBackgroundDataFetchWorker
  end

  def imglink_url
    "https://www.500px.com/"
  end

  def create_controls(dlg)
    super
    @ui.gallery_create_btn.on_click { handle_create_gallery }
  end

  protected

  def connection
    dbglog("connection")
    if @connection.nil?
      @connection = U500pxConnection.new(@bridge)
      connection.set_tokens(account.access_token, account.access_token_secret)
    end
    @connection
  end

  def set_gallery_status_text(txt)
    @ui.gallery_status_static.set_text(txt)
  end

  def handle_create_gallery
    name = @ui.gallery_name_edit.get_text
    privacy = @ui.gallery_privacy_check.checked? ? "1" : "0"
    set_gallery_status_text("")
    if (name.empty?)
      set_gallery_status_text("To create a new gallery, enter a gallery name")
    elsif (galleries.has_key?(name))
      set_gallery_status_text("Gallery #{name} already exists, choose a new name")
    else
      begin
        response = connection.post("users/#{userid}/galleries" + connection.create_query_string_from_hash({ "name" => name, "kind" => 4, "privacy" => privacy }))
        connection.require_server_success_response(response)
        set_gallery_status_text("Gallery #{name} succesfully created")
        update_gallery_combo
      rescue StandardError => ex
        set_gallery_status_text("Unable to create new gallery: #{ex.message}")
      end
    end
  end

  def userid
    if @userid.nil?
      response = connection.get('users')
      connection.require_server_success_response(response)
      response_body = JSON.parse(response.body)
      @userid = response_body['user']['id']
    end
    @userid
  end

  def galleries
    @galleries ||= get_galleries
  end

  def get_galleries
      response = connection.get("users/#{userid}/galleries?privacy=both")
      connection.require_server_success_response(response)
      response_body = JSON.parse(response.body)
      gallery_info = response_body['galleries']
      @galleries = {}
      gallery_info.each { |g| @galleries[g['name']] = g['id'] }
      @galleries
  end

  def update_gallery_combo
    get_galleries
    names = @galleries.keys
    names.sort!
    names.insert(0, "— Select a Gallery (optional)  —")
    @ui.meta_gallery_combo.reset_content(names)
  end
    
   
  def account_parameters_changed
    super
    if account.nil? || !account.appears_valid?
      return
    end
    begin
      userid = nil
      update_gallery_combo
    rescue StandardError => ex
      set_status_text("Error fetching Galleries for account: #{ex.message}")
    end
  end


  def build_additional_upload_spec(spec, ui)
    spec.userid = userid
    spec.galleryid = @galleries["#{@ui.meta_gallery_combo.get_selected_item_text}"]
    metadata = {
      "category" => @ui.meta_category_combo.get_selected_item.to_i.to_s,
      "nsfw" => @ui.meta_nsfw_check.checked? ? "1" : "0",
      "license_type" => @ui.meta_license_type_combo.get_selected_item.to_i.to_s,
      "privacy" => @ui.meta_privacy_check.checked? ? "1" : "0"
    }
    [ "name", "description", "shutter_speed", "focal_length", "aperture", "iso", "camera", "lens", "taken_at", "latitude", "longitude", "tags" ].each do |item|
      itemvalue = eval "@ui.meta_#{item}_edit.get_text"
      metadata[item] = itemvalue
    end
    spec.metadata = {}
    @num_files.times do |i|
      fname = @bridge.expand_vars("{folderpath}{filename}", i+1)
      unique_id = @bridge.get_item_unique_id(i+1)
      spec.metadata[unique_id] = {}
      metadata.each_pair do |item, value|
        interpreted_value = @bridge.expand_vars(value, i+1)
        interpreted_value = convert_gps_coordinate(interpreted_value) if !(item =~ /^(long|lat)itude$/).nil?
        spec.metadata[unique_id][item] = interpreted_value
      end
    end
  end
end

class U500pxConnection < OAuthConnection
  def initialize(pm_api_bridge)
    @base_url = 'https://api.500px.com/v1/'
    @api_key = 'w7c3g81Jm0Adz8xKaQKYmptq6TQgpMCB8RRcBb8H'
    @api_secret = 'FOt5VAtOD1DZ3rzZa25lU8V1pAufkzXg9scjk65z'
    @callback_url = 'https://auth.camerabits.com/oauth/verifier/500px'
    super
  end
end

class U500pxClient < OAuthClient
  def connection
    @connection ||= U500pxConnection.new(@bridge)
  end
  
  def get_account_name(result)
    # Now we get the name from the user record on 500px
    @verifier = nil
    response = connection.get('users')
    connection.require_server_success_response(response)
    response_body = JSON.parse(response.body)
    name = "#{response_body['user']['username']} (#{response_body['user']['fullname']})"
    name
  end
end

class U500pxConnectionImageUpload < U500pxConnection
  def initialize(pm_api_bridge)
    super
    @base_url = 'https://upload.500px.com/v1/'
  end
end

    
class U500pxUploadProtocol < OAuthUploadProtocol
  def connection
    @connection ||= U500pxConnection.new(@bridge)
  end

  def connection_image_upload
    @connection_image_upload ||= U500pxConnectionImageUpload.new(@bridge)
  end
  
  def upload(fname, remote_filename, spec)
    fcontents = @bridge.read_file_for_upload(fname)
    mime = MimeMultipart.new
    mime.add_image("file", remote_filename, fcontents, "application/octet-stream")
    data, headers = mime.generate_data_and_headers

    begin
      connection.unmute_transfer_status
      # Get upload_key & photo_id
      response = connection.post('photos' + connection.create_query_string_from_hash(spec.metadata[spec.unique_id]))
      connection.require_server_success_response(response)
      response_body = JSON.parse(response.body)
      upload_qstr = connection.create_query_string_from_hash(
        { "upload_key" => response_body["upload_key"],
          "photo_id" => response_body["photo"]["id"],
          "consumer_key" => connection.api_key,
          "access_key" => spec.token
        })
      # Image itself is uploaded to domain upload.500px.com instead of the normal api.500px.com!
      connection_image_upload.post('upload' + upload_qstr, data, headers)
      connection.require_server_success_response(response)
      # Add photo to gallery
      if (!spec.galleryid.nil?) then
        jsonparam = JSON.generate( { "add" => { "photos" => [ response_body["photo"]["id"] ] } } )
        response = connection.put("users/#{spec.userid}/galleries/#{spec.galleryid}/items", jsonparam)
        connection.require_server_success_response(response)
      end
    ensure
      connection.mute_transfer_status
    end
  end
end
