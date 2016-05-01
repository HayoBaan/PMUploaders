#!/usr/bin/env ruby
##############################################################################
# Copyright (c) 2006-2013 Camera Bits, Inc.  All rights reserved.
##############################################################################


TEMPLATE_DISPLAY_NAME = "SmugMug"  # must be same for uploader and conn. settings


##############################################################################
## Connection Settings template

class SmugMugConnectionSettingsUI

  include PM::Dlg
  include AutoAccessor
  include CreateControlHelper

  def initialize(pm_api_bridge)
    @bridge = pm_api_bridge
  end

  def create_controls(parent_dlg)
    dlg = parent_dlg
    create_control(:setting_name_static,    Static,       dlg, :label=>"SmugMug Connection Setting Name:")
    # the combo/edit/buttons are arranged in tab order
    create_control(:setting_name_combo,     ComboBox,     dlg, :editable=>true, :sorted=>true, :persist=>false)
    create_control(:login_edit,             EditControl,  dlg, :value=>"", :persist=>false)
    create_control(:password_edit,          EditControl,  dlg, :value=>"", :password=>true, :persist=>false)
    create_control(:setting_new_btn,        Button,       dlg, :label=>"New")
    create_control(:setting_delete_btn,     Button,       dlg, :label=>"Delete")
    create_control(:login_static,           Static,       dlg, :label=>"SmugMug email or nick name:")
    create_control(:password_static,        Static,       dlg, :label=>"Password:")
  end
  
  def layout_controls(container)
    sh, eh = 20, 24
    c = container
    c.set_prev_right_pad(5).inset(10,10,-10,-10).mark_base
    c << @setting_name_static.layout(0, c.base, -1, sh)
    c.pad_down(0).mark_base
    c << @setting_name_combo.layout(0, c.base, -150, eh)
      c << @setting_new_btn.layout(-140, c.base, -80, eh)
        c << @setting_delete_btn.layout(-70, c.base, -1, eh)
    c.pad_down(15).mark_base
    c << @login_static.layout(0, c.base, 200, sh)
      c << @password_static.layout(210, c.base, 70, sh)
    c.pad_down(0).mark_base
    c << @login_edit.layout(0, c.base, 200, eh)
      c << @password_edit.layout(210, c.base, 120, eh)
    c.pad_down(0).mark_base
  end
end


class SmugMugConnectionSettings

  # must include PM::FileUploaderTemplate so that
  # the template manager can find our class in
  # ObjectSpace
  include PM::ConnectionSettingsTemplate

  DLG_SETTINGS_KEY = :connection_settings_dialog

  def self.template_display_name  # template name shown in dialog list box
    TEMPLATE_DISPLAY_NAME
  end

  def self.template_description  # shown in dialog box
    "SmugMug Connection Settings"
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
    attr_accessor :login, :password
    
    def initialize(login, password)
      @login = login
      @password = password
    end
    
    def appears_valid?
      ! ( @login.nil?  ||  @password.nil?  ||
          @login.to_s.strip.empty?  ||  @password.to_s.strip.empty? )
    end
    
    # Convert a hash of SettingsData, to a hash of
    # arrays, and encrypt the password along the way.
    #
    # NOTE: We ditch the SettingsData, because its module
    # name would end up being written out with the YAML, but
    # templates are in a sandbox whose module name includes
    # their disk path. If the user later moved their templates
    # folder, their old settings data wouldn't deserialize
    # because the module name would no longer match up.  So we
    # are converting to just plain data types (hash of arrays.)
    def self.serialize_settings_hash(settings)
      bridge = Thread.current[:sandbox_bridge]
      out = {}
      settings.each_pair do |key, dat|
        password = dat.password
        pass_crypt = password.nil? ? nil : bridge.encrypt(password)
        out[key] = [dat.login, pass_crypt]
      end
      out
    end

    # Convert a hash of arrays, to a hash of SettingsData,
    # and decrypt the password along the way.
    def self.deserialize_settings_hash(input)
      bridge = Thread.current[:sandbox_bridge]
      settings = {}
      input.each_pair do |key, dat|
        login, pass_crypt = *input[key]
        password = pass_crypt.nil? ? nil : bridge.decrypt(pass_crypt)
        settings[key] = SettingsData.new(login, password)
      end
      settings
    end
    

  end

  def initialize(pm_api_bridge)
    @bridge = pm_api_bridge
    @prev_selected_settings_name = nil
    @settings = {}
  end

  def create_controls(parent_dlg)
    @ui = SmugMugConnectionSettingsUI.new(@bridge)
    @ui.create_controls(parent_dlg)

    @ui.setting_name_combo.on_edit_change { handle_rename_selected }
    @ui.setting_name_combo.on_sel_change { handle_sel_change }
    @ui.setting_new_btn.on_click { handle_new_button }
    @ui.setting_delete_btn.on_click { handle_delete_button }
  end

  def layout_controls(container)
    @ui.layout_controls(container)
  end
  
  def destroy_controls
    @ui = nil
  end

  def save_state(serializer)
    return unless @ui
    cur_selected_name = save_current_values_to_settings
    self.class.store_settings_data(serializer, @settings)
    serializer.store(DLG_SETTINGS_KEY, :selected_item, cur_selected_name)
  end  

  def restore_state(serializer)
    @settings = self.class.fetch_settings_data(serializer)
    load_combo_from_settings
    @prev_selected_settings_name = serializer.fetch(DLG_SETTINGS_KEY, :selected_item)
    if @prev_selected_settings_name
      @ui.setting_name_combo.set_selected_item(@prev_selected_settings_name)
    end

    # if we have items in the settings combo but none ended up being selected,
    # just select the 1st one
    if @ui.setting_name_combo.get_selected_item.empty?  &&  @ui.setting_name_combo.num_items > 0
      @ui.setting_name_combo.set_selected_item( @ui.setting_name_combo.get_item_at(0) )
    end

    @prev_selected_settings_name = @ui.setting_name_combo.get_selected_item
    @prev_selected_settings_name = nil if @prev_selected_settings_name.empty?

    load_current_values_from_settings
  end

  def periodic_timer_callback
  end

  protected

  def load_combo_from_settings
    @ui.setting_name_combo.reset_content( @settings.keys )
  end

  def save_current_values_to_settings(params={:name=>nil, :replace=>true})
    cur_name = params[:name]
    cur_name = @ui.setting_name_combo.get_selected_item_text.to_s unless cur_name
    if cur_name.to_s.empty?
      return "" unless current_values_worth_saving?
      cur_name = find_non_colliding_name("Untitled")
    else
      cur_name = find_non_colliding_name(cur_name) unless params[:replace]
    end
    @settings[cur_name] = SettingsData.new(@ui.login_edit.get_text, @ui.password_edit.get_text)
    cur_name
  end

  def load_current_values_from_settings
    cur_name = @ui.setting_name_combo.get_selected_item_text.to_s
    data = @settings[cur_name]
    if data
      @ui.login_edit.set_text data.login
      @ui.password_edit.set_text data.password
    end
  end

  def current_values_worth_saving?
    # i guess, if they've filled in any field, save it
    ! ( @ui.setting_name_combo.get_selected_item_text.to_s.empty?  &&
        @ui.login_edit.get_text.empty?  &&
        @ui.password_edit.get_text.empty? )
  end
  
  def find_non_colliding_name(want_name)
    i = 1  # first rename attempt will be "blah blah 2"
    new_name = want_name
    while @ui.setting_name_combo.has_item? new_name
      i += 1
      new_name = "#{want_name} #{i}"
    end
    new_name
  end

  def rename_in_settings(old_name, new_name)
    data = @settings[old_name]
    @settings.delete old_name
    @settings[new_name] = data
  end

  def delete_in_settings(name)
    @settings.delete name
  end

  def handle_rename_selected
    had_prev = ! @prev_selected_settings_name.nil?
    cur_name = @ui.setting_name_combo.get_text.to_s
    if cur_name != @prev_selected_settings_name
      if had_prev
        @ui.setting_name_combo.remove_item @prev_selected_settings_name
      end

      return "" if cur_name.strip.empty? && !current_values_worth_saving?
      cur_name = "Untitled" if cur_name.strip.empty?
      new_name = find_non_colliding_name(cur_name)

      if had_prev
        rename_in_settings(@prev_selected_settings_name, new_name)
      else
        saved_name = save_current_values_to_settings(:name=>new_name, :replace=>true)
        return "" unless !saved_name.empty?
      end
      @ui.setting_name_combo.add_item new_name
      @prev_selected_settings_name = new_name
      cur_name = new_name
    end
    cur_name
  end

  def save_or_rename_current_settings
    worth_saving = current_values_worth_saving?
    if @prev_selected_settings_name.nil?
      # dbgprint "save_or_rename: prev was nil (saving if worth it)"
      if worth_saving
        # dbgprint "save_or_rename: current worth saving"
        name = save_current_values_to_settings(:replace=>false)
        @ui.setting_name_combo.add_item(name) unless @ui.setting_name_combo.has_item? name
      end
    else
      # dbgprint "save_or_rename: prev NOT nil (renaming)"
      new_name = handle_rename_selected
      if worth_saving
        # dbgprint "save_or_rename: current worth saving (after rename)"
        save_current_values_to_settings(:name=>new_name, :replace=>true)
      end
    end
  end

  def handle_sel_change
    # NOTE: We rely fully on the prev. selected name here, because the
    # current selected name has already changed.
    if @prev_selected_settings_name
      save_current_values_to_settings(:name=>@prev_selected_settings_name, :replace=>true)
    end
    load_current_values_from_settings
    @prev_selected_settings_name = @ui.setting_name_combo.get_selected_item_text
  end

  def clear_settings
    @ui.setting_name_combo.set_text ""
    @ui.login_edit.set_text ""
    @ui.password_edit.set_text ""
  end

  def handle_new_button
    save_or_rename_current_settings
    @prev_selected_settings_name = nil
    clear_settings
  end
  
  def handle_delete_button
    cur_name = @ui.setting_name_combo.get_selected_item_text
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


##############################################################################
## Uploader template


class SmugMugCreateGalleryDialog < Dlg::DynModalChildDialog

  include PM::Dlg
  include CreateControlHelper

  def initialize(api_bridge, prot, categories, dialog_end_callback)
    @bridge = api_bridge
    @prot = prot
    @categories = categories
    @dialog_end_callback = dialog_end_callback
    @created_gallery_name = nil
    super()
  end

  def init_dialog
    # this will be called by c++ after DoModal()
    # calls InitDialog.
    dlg = self
    dlg.set_window_position_key("SmugMugCreateGalleryDialog")
    dlg.set_window_position(50, 100, 500, 200)
    title = "Create New Gallery"
    dlg.set_window_title(title)
    
    parent_dlg = dlg
    create_control(:descrip_gallery_static, Static,         parent_dlg, :label=>"Create new SmugMug gallery:", :align=>"left")
    create_control(:category_static,        Static,         parent_dlg, :label=>"Category:", :align=>"left")
    create_control(:category_combo,         ComboBox,       parent_dlg, :sorted=>true, :persist=>false)
    create_control(:new_gallery_static,     Static,         parent_dlg, :label=>"New gallery name:", :align=>"left")
    create_control(:new_gallery_edit,       EditControl,    parent_dlg, :value=>"", :persist=>false)
    create_control(:create_button,          Button,         parent_dlg, :label=>"Create")
    create_control(:cancel_button,          Button,         parent_dlg, :label=>"Cancel")

    @create_button.on_click { create_gallery }
    @cancel_button.on_click { closebox_clicked }

    names = @categories.map {|cat| cat.name}
    @category_combo.reset_content names
    if @category_combo.num_items > 0
      @category_combo.set_selected_item( "Other" )
    end

    layout_controls
    instantiate_controls
    show(true)
  end        

  def destroy_dialog!
    if @prot
      @prot.close rescue nil
      @prot = nil
    end
    super
    (@dialog_end_callback.call(@created_gallery_name) if @dialog_end_callback) rescue nil
  end

  def layout_controls
    sh = 20
    eh = 24
    bh = 28
    dlg = self
    client_width, client_height = dlg.get_clientrect_size
# dbgprint "GCAD: clientrect: #{client_width}, #{client_height}"
    c = LayoutContainer.new(0, 0, client_width, client_height)
    c.inset(16, 10, -16, -10)
    c << @descrip_gallery_static.layout(0, c.base, -1, sh)
    c.pad_down(20).mark_base
    
    w1 = 250
    c << @category_static.layout(0, c.base, w1, sh)
      c << @new_gallery_static.layout(c.prev_right + 20, c.base, -1, sh)
    c.pad_down(0).mark_base
    c << @category_combo.layout(0, c.base, w1, eh)
      c << @new_gallery_edit.layout(c.prev_right + 20, c.base, -1, eh)
    c.pad_down(5).mark_base
    
    bw = 80
    c << @create_button.layout(-(bw*2+10), -bh, bw, bh)
      c << @cancel_button.layout(-bw, -bh, bw, bh)
  end

  protected
  
  def create_gallery
    gal_name = @new_gallery_edit.get_text.strip
    if gal_name.empty?
      Dlg::MessageBox.ok("Please enter a non-blank gallery name.", Dlg::MessageBox::MB_ICONEXCLAMATION)
      return
    end

    cat_name = @category_combo.get_selected_item
    cat_id = @categories.name_to_id( cat_name )
    unless cat_id || cat_name.empty?
      Dlg::MessageBox.ok("Couldn't find id for category #{cat_name}.", Dlg::MessageBox::MB_ICONEXCLAMATION)
      return
    end

    begin
      @prot.create_album(gal_name, cat_id)
      @created_gallery_name = gal_name
    rescue StandardError => ex
      Dlg::MessageBox.ok("Failed to create gallery #{gal_name} on server.\nError: #{ex.message}", Dlg::MessageBox::MB_ICONEXCLAMATION)
    ensure
      end_dialog(IDOK)
    end 
  end
end


class SmugMugFileUploaderUI

  include PM::Dlg
  include AutoAccessor
  include CreateControlHelper
  include ImageProcessingControlsCreation
  include ImageProcessingControlsLayout
  include OperationsControlsCreation
  include OperationsControlsLayout

  SOURCE_RAW_LABEL = "Use the RAW"
  SOURCE_JPEG_LABEL = "Use the JPEG"

  DEST_EXISTS_UPLOAD_ANYWAY_LABEL = "Upload file anyway (files of same name can safely coexist)"
  DEST_EXISTS_RENAME_LABEL = "Rename file before uploading"
  DEST_EXISTS_SKIP_LABEL = "Skip file (do not upload)"

  def initialize(pm_api_bridge)
    @bridge = pm_api_bridge
  end

  def create_controls(parent_dlg)
    dlg = parent_dlg

    create_control(:dest_account_group_box,     GroupBox,       dlg, :label=>"Destination SmugMug Account:")
    create_control(:dest_account_static,        Static,         dlg, :label=>"Account:", :align=>"right")
    create_control(:dest_account_combo,         ComboBox,       dlg, :sorted=>true, :persist=>false)
    create_control(:dest_gallery_static,        Static,         dlg, :label=>"Gallery:", :align=>"right")
    create_control(:dest_gallery_combo,         ComboBox,       dlg, :sorted=>true, :persist=>false)
    create_control(:create_gallery_button,      Button,         dlg, :label=>"Create New Gallery...")

    create_control(:transmit_group_box,         GroupBox,       dlg, :label=>"Transmit:")
    create_control(:send_original_radio,        RadioButton,    dlg, :label=>"Original Photos", :checked=>true)
    create_control(:send_jpeg_radio,            RadioButton,    dlg, :label=>"Saved as JPEG")
    RadioButton.set_exclusion_group(@send_original_radio, @send_jpeg_radio)
    create_control(:send_desc_edit,             EditControl,    dlg, :value=>"Note: SmugMug only accepts JPEG, PNG, and GIF. Even if you have chosen to transmit Original Photos, formats other than JPEG, PNG, and GIF will be saved as JPEG before being uploaded.", :multiline=>true, :readonly=>true, :persist=>false)
    #------------------------------------------
    create_jpeg_controls(dlg)
    #------------------------------------------
    create_image_processing_controls(dlg)
    #------------------------------------------
    create_operations_controls(dlg)
    #------------------------------------------
  end

  STATIC_TEXT_HEIGHT = 20
  EDIT_FIELD_HEIGHT = 24
  COLOR_BUTTON_HEIGHT = 24
  RIGHT_PAD = 5
  def layout_controls(container)
    sh = STATIC_TEXT_HEIGHT
    eh = EDIT_FIELD_HEIGHT
    ch = COLOR_BUTTON_HEIGHT
    rp = RIGHT_PAD

    container.inset(15, 5, -15, -5)
    container.layout_with_contents(@dest_account_group_box, 0, 0, -1, -1) do |c|
      c.set_prev_right_pad(rp).inset(10,25,-10,-5).mark_base

      oldbase = c.base
      c.layout_subgroup(0, c.base, "45%-5", -1) do |cl|
        cl.set_prev_right_pad(rp)
        cl << @dest_account_static.layout(0, cl.base+3, 120, sh)
        cl << @dest_account_combo.layout(cl.prev_right, cl.base, -1, eh)
        cl.pad_down(5).mark_base
        cl << @dest_gallery_static.layout(0, cl.base+3, 120, sh)
        cl << @dest_gallery_combo.layout(cl.prev_right, cl.base, -1, eh)
        cl.pad_down(5).mark_base.size_to_base
      end      

      c.pad_down(0).mark_base

      c.layout_subgroup("45%+10", oldbase, -1, c.base - oldbase) do |cl|
        cl << @create_gallery_button.layout(0, cl.base+eh+1, 150, 28)
        cl.pad_down(0).mark_base
      end

      c.pad_down(5).mark_base.size_to_base
    end

    container.pad_down(5).mark_base

    container.layout_with_contents(@transmit_group_box, 0, container.base, "50%-5", -1) do |xmit_container|
      c = xmit_container
      c.set_prev_right_pad(rp).inset(10,25,-10,-5).mark_base

      c << @send_original_radio.layout(0, c.base, 120, eh)
      save_right, save_base = c.prev_right, c.base
      c.pad_down(5).mark_base
      c << @send_jpeg_radio.layout(0, c.base, 120, eh)
        c << @send_desc_edit.layout(save_right+5, save_base, -1, 76)
      c.pad_down(7).mark_base

      layout_jpeg_controls(c, eh, sh)

      c.layout_with_contents(@imgproc_group_box, 0, c.base, -1, -1) do |c|
        c.set_prev_right_pad(rp).inset(10,25,-10,-5).mark_base

        w1, w2 = 70, 182
        w1w = (w2 - w1)
        layout_image_processing_controls(c, eh, sh, w1, w2, w1w)
      end
      c = xmit_container

      c.pad_down(5).mark_base
      c.mark_base.size_to_base
    end

    # container.pad_down(5).mark_base
    layout_operations_controls(container, eh, sh, rp)

    container.pad_down(20).mark_base
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


class SmugMugBackgroundDataFetchWorker
  def initialize(bridge, dlg)
    @bridge = bridge
    @dlg = dlg
  end

  # called periodically (by BackgroundDataFetchWorkerManager)
  def do_task
    return unless @dlg.account_parameters_dirty
    #dbgprint "do_task running"
    acct = @dlg.current_account_settings
    if acct.nil?
      @dlg.set_status_text("Please select an account, or create one with the Connections button.")
    elsif ! acct.appears_valid?
      @dlg.set_status_text("Some account settings appear invalid or missing. Please click the Connections button.")
    else
      @dlg.set_status_text("Opening connection...")
      username = acct.login
      password = acct.password
      begin
        prot = SmugMugFileUploaderProtocol.new(@bridge)
        begin
          prot.login(username, password)
          @dlg.set_status_text("Fetching categories...")
          @dlg.cur_categories = prot.get_categories
          @dlg.set_status_text("Fetching galleries...")
          galleries = prot.get_albums
          @dlg.cur_galleries = galleries
          @dlg.adjust_controls
          gallery_titles = galleries.map {|gal| gal.unique_title}
        ensure
          prot.close
        end
        #dbgprint "updating gallery titles..."
        @dlg.update_combo(:dest_gallery_combo, gallery_titles)
        @dlg.set_status_text("Ready.")
      rescue StandardError => ex
        @dlg.set_status_text(ex.message)
        #dbgprint ex.message
        #dbgprint ex.backtrace
      end
    end
    @dlg.account_parameters_dirty = false
  end
end


class SmugMugFileUploader

  # must include PM::FileUploaderTemplate so that
  # the template manager can find our class in
  # ObjectSpace
  include PM::FileUploaderTemplate
  include ImageProcessingControlsLogic
  include OperationsControlsLogic
  include RenamingControlsLogic
  include JpegSizeEstimationLogic
  include UpdateComboLogic
  include FormatBytesizeLogic
  include PreflightWaitAccountParametersLogic

  attr_accessor :account_parameters_dirty
  attr_accessor :cur_galleries, :cur_categories

  DLG_SETTINGS_KEY = :upload_dialog  # don't worry, won't conflict with other templates

  def self.template_display_name  # template name shown in dialog list box
    TEMPLATE_DISPLAY_NAME
  end

  def self.template_description  # shown in dialog box
    "Upload images to SmugMug"
  end

  def self.conn_settings_class
    SmugMugConnectionSettings
  end

  def initialize(pm_api_bridge, num_files, dlg_status_bridge, conn_settings_serializer)
    @bridge = pm_api_bridge
    @num_files = num_files
    @dlg_status_bridge = dlg_status_bridge
    @conn_settings_ser = conn_settings_serializer
    @last_status_txt = nil
    @cur_galleries = nil
    @cur_categories = nil
    @account_parameters_dirty = false
    @data_fetch_worker = nil
  end

  def upload_files(global_spec, progress_dialog)
# dbgprint "in upload_files..."
    raise "upload_files called with no @ui instantiated" unless @ui
# dbgprint "before build_upload_spec"
    acct = current_account_settings
    raise "Failed to load settings for current account. Please click the Connections button." unless acct
    spec = build_upload_spec(acct, @ui)
    # @bridge.kickoff_photoshelter_upload(spec.__to_hash__)
    @bridge.kickoff_template_upload(spec, SmugMugFileUploaderProtocol)
  end

  def preflight_settings(global_spec)
    raise "preflight_settings called with no @ui instantiated" unless @ui

    acct = current_account_settings
    raise "Failed to load settings for current account. Please click the Connections button." unless acct
    raise "Some account settings appear invalid or missing. Please click the Connections button." unless acct.appears_valid?

    preflight_renaming_controls
    preflight_operations_controls
    preflight_jpeg_controls

    preflight_wait_account_parameters_or_timeout

    if @ui.dest_gallery_combo.num_items <= 0 || @ui.dest_gallery_combo.get_selected_item.empty?
      raise "No gallery selected for upload."
    end

    # NOTE: not checking @cur_categories here as we don't technically
    # need them to perform the upload
    @cur_galleries or raise("Have not received gallery list from server.")

    spec = build_upload_spec(acct, @ui)
    # TODO: ???
  end

  def create_controls(parent_dlg)
    @ui = SmugMugFileUploaderUI.new(@bridge)
    @ui.create_controls(parent_dlg)
    
    @ui.send_original_radio.on_click {adjust_controls}
    @ui.send_jpeg_radio.on_click {adjust_controls}

    @ui.dest_account_combo.on_sel_change {account_parameters_changed}

    @ui.create_gallery_button.on_click {run_create_gallery_dialog}

    add_jpeg_controls_event_hooks
    add_operations_controls_event_hooks
    add_renaming_controls_event_hooks
    add_image_processing_controls_event_hooks
    set_seqn_static_to_current_seqn

    @last_status_txt = nil

    create_data_fetch_worker
  end

  def layout_controls(container)
    @ui.layout_controls(container)
  end
  
  def destroy_controls
    destroy_data_fetch_worker
    @ui = nil
  end

  def save_state(serializer)
    return unless @ui
    serializer.store(DLG_SETTINGS_KEY, :selected_account, @ui.dest_account_combo.get_selected_item)
    serializer.store(DLG_SETTINGS_KEY, :selected_gallery, @ui.dest_gallery_combo.get_selected_item)
  end

  def restore_state(serializer)
    data = fetch_conn_settings_data
    @ui.dest_account_combo.reset_content( data.keys )

    prev_selected_account = serializer.fetch(DLG_SETTINGS_KEY, :selected_account)
    @ui.dest_account_combo.set_selected_item(prev_selected_account) if prev_selected_account

    # if we have items in the accounts combo but none ended up being selected,
    # just select the 1st one
    if @ui.dest_account_combo.get_selected_item.empty?  &&  @ui.dest_account_combo.num_items > 0
      @ui.dest_account_combo.set_selected_item( @ui.dest_account_combo.get_item_at(0) )
    end

    # We don't persist the dest gallery combo, so it will be empty at this
    # point.  So, when restoring the prev selected gallery, make it the only
    # item in the combo for now.  When the background data fetch worker
    # fully populates the combo, this selection will be retained if possible.
    prev_selected_gallery = serializer.fetch(DLG_SETTINGS_KEY, :selected_gallery)
    unless prev_selected_gallery.to_s.empty?
      update_combo(:dest_gallery_combo, [prev_selected_gallery])
    end

    account_parameters_changed
    adjust_controls
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

  def imglink_button_spec
    { :filename => "logo.tif", :bgcolor => "ffffff" }
  end

  def imglink_url
    "http://www.smugmug.com/"
  end

  # Called by the framework after user has brought up the Connection Settings
  # dialog.
  def connection_settings_edited(conn_settings_serializer)
    @conn_settings_ser = conn_settings_serializer

    data = fetch_conn_settings_data
    @ui.dest_account_combo.reset_content( data.keys )
    selected_settings_name = SmugMugConnectionSettings.fetch_selected_settings_name(@conn_settings_ser)
    if selected_settings_name
      @ui.dest_account_combo.set_selected_item( selected_settings_name )
    end

    # if selection didn't take, and we have items in the list, just pick the 1st one
    if @ui.dest_account_combo.get_selected_item.empty?  &&  @ui.dest_account_combo.num_items > 0
      @ui.dest_account_combo.set_selected_item( @ui.dest_account_combo.get_item_at(0) )
    end

    account_parameters_changed
  end

  protected

  def create_data_fetch_worker
    qfac = lambda { @bridge.create_queue }
    @data_fetch_worker = BackgroundDataFetchWorkerManager.new(SmugMugBackgroundDataFetchWorker, qfac, [@bridge, self])
  end

  def destroy_data_fetch_worker
    if @data_fetch_worker
      @data_fetch_worker.terminate
      @data_fetch_worker = nil
    end
  end

  def run_create_gallery_dialog
    # these sanity checks really shouldn't be necessary, as
    # the create button is in theory disabled if they are false
    unless @cur_categories && @cur_galleries
      Dlg::MessageBox.ok("Can't create gallery, still awaiting required information from SmugMug server.", Dlg::MessageBox::MB_ICONEXCLAMATION)
      account_parameters_changed  # set dirty to force attempt to re-fetch galleries
      return
    end
    acct = current_account_settings
    unless acct && acct.appears_valid?
      Dlg::MessageBox.ok("Account settings appear missing or invalid. Please Please click the Connections button.", Dlg::MessageBox::MB_ICONEXCLAMATION)
      return
    end
    begin
      prot = get_prot_with_login(acct)
    rescue StandardError => ex
      Dlg::MessageBox.ok("Unable to login to SmugMug server. Please Please click the Connections button.\nError: #{ex.message}", Dlg::MessageBox::MB_ICONEXCLAMATION)
      return
    end
    set_status_text "Ready to create gallery."
    dialog_end_callback = lambda {|new_gal_name| handle_new_gallery_created(new_gal_name)}
    cdlg = SmugMugCreateGalleryDialog.new(@bridge, prot, @cur_categories, dialog_end_callback)
    cdlg.instantiate!
    cdlg.request_deferred_modal
  end

  def handle_new_gallery_created(new_gal_name)
    if new_gal_name
      # just blow away the galleries combobox contents with the
      # new name... we'll be forcing a reload, and the new selection
      # will be preserved when the data is reloaded
      @ui.dest_gallery_combo.reset_content( [new_gal_name] )
      @ui.dest_gallery_combo.set_selected_item(new_gal_name)
    end
    account_parameters_changed
  end
  
  def get_prot_with_login(acct)
    username = acct.login
    password = acct.password
    prot = nil
    begin
      # statproc = lambda {|msg| set_status_text(msg)}
      prot = SmugMugFileUploaderProtocol.new(@bridge)
      prot.login(username, password)
    rescue Exception
      (prot.close if prot) rescue nil
      raise
    end
    prot
  end

  def adjust_controls
    sending_originals = @ui.send_original_radio.checked?
    @ui.jpeg_qlty100_slider.enable( !sending_originals )
    @ui.jpeg_chroma_check.enable( !sending_originals )
    adjust_image_processing_controls
    adjust_operations_controls
    adjust_renaming_controls

    acct = current_account_settings
    can_create = @cur_categories && @cur_galleries && acct && acct.appears_valid?
    @ui.create_gallery_button.enable( can_create )
  end

  def build_upload_spec(acct, ui)
    spec = AutoStruct.new

    # string displayed in upload progress dialog title bar:
    spec.upload_display_name  = "smugmug.com:#{acct.login}"
    # string used in logfile name, should have NO spaces or funky characters:
    spec.log_upload_type      = TEMPLATE_DISPLAY_NAME.tr('^A-Za-z0-9_-','')
    # account string displayed in upload log entries:
    spec.log_upload_acct      = spec.upload_display_name

    spec.num_files = @num_files
    spec.max_concurrent_uploads = 1 # %TEMPFIX: added because multiple uploads with slight timeouts causes failures

    spec.smugmug_login        = acct.login
    spec.smugmug_password     = acct.password
    spec.smugmug_gallery      = ui.dest_gallery_combo.get_selected_item
    # we aren't supposed to raise exceptions while building the
    # spec (because the jpeg sizing thread wants a best effort)
    # so it will be up to preflight to verify we got the gallery_id
    if @cur_galleries
      spec.smugmug_gallery_id   = @cur_galleries.unique_title_to_id( spec.smugmug_gallery )
    end

    # NOTE: upload_queue_key should be unique for a given protocol,
    #       and a given upload "account".
    #       Rule of thumb: If file A requires a different 
    #       login than file B, they should have different
    #       queue keys.
    #       Thus here for photoshelter, we use login/password/org,
    #       because these affect how we login to transfer the file.
    #       But we don't include the archive folder in the key,
    #       because we can upload to different archive folders
    #       on a given login.
    spec.upload_queue_key = [
      "SmugMug",
      spec.smugmug_login
    ].join("\t")

    spec.upload_processing_type = ui.send_original_radio.checked? ? "originals_gif_jpeg_png_only" : "save_as_jpeg"
    spec.send_incompatible_originals_as = "JPEG"
    spec.send_wav_files = false

    build_jpeg_spec(spec, ui)
    build_image_processing_spec(spec, ui)
    build_operations_spec(spec, ui)
    build_renaming_spec(spec, ui)

    spec
  end

  def fetch_conn_settings_data
    SmugMugConnectionSettings.fetch_settings_data(@conn_settings_ser)
  end

  def current_account_settings
    acct_name = @ui.dest_account_combo.get_selected_item
    data = fetch_conn_settings_data
    settings = data ? data[acct_name] : nil
  end

  def account_parameters_changed
    @account_parameters_dirty = true
  end

  def __run_tests__
    SmugMugFileUploaderTests.new(self).run
  end
  public :__run_tests__
end


# SmugMug documentation is here:
#    http://wiki.smugmug.net/display/SmugMug/API
#
REST_URL = "https://api.smugmug.com/services/api/rest/1.2.2/"
API_KEY = "aTfv4bmtsqd3YiL2IcYkAXivYGldaCrN"
SMUG_VER = '1.2.2'


SmugMugCategory = Struct.new(:category_id, :name)

class SmugMugCategoryList
  include Enumerable

  def initialize(bridge, xml_resp, sub_xml_resp)
    @bridge = bridge
    @categories = []
    # doc = REXML::Document.new(xml_resp)
    #dbgprint "SmugMugCategoryList, xml_resp: #{xml_resp}"
    doc = @bridge.xml_document_parse(xml_resp)
    root = doc.get_elements("rsp/Categories").first
    root or raise("bad server response - categories root element missing")
    parse_categories(root)
    #dbgprint "SmugMugSubCategoryList, sub_xml_resp: #{sub_xml_resp}"
    doc = @bridge.xml_document_parse(sub_xml_resp)
    root = doc.get_elements("rsp/SubCategories").first
    root or raise("bad server response - subcategories root element missing")
    parse_sub_categories(root)
  end
  
  def count
    @categories.length
  end

  def find_by_id(id)
    @categories.find {|cat| cat.id == id}
  end

  def find_by_name(name)
    @categories.find {|cat| cat.name == name}
  end

  def name_to_id(name)
    cat = find_by_name(name)
    cat ? cat.category_id : nil
  end
  
  def values
    @categories
  end

  def each
    values.each {|cat| yield cat}
  end

  private

  def parse_categories(parent_node)
    children = parent_node.get_elements("Category")
    children.each do |node|
      cat = construct_category(node, "")
      @categories << cat
    end
  end

  def parse_sub_categories(parent_node)
    children = parent_node.get_elements("SubCategory")
    children.each do |node|
      fromcat = node.get_elements("Category").first
      #dbgprint "Found #{#{node.attribute('Name')} node.attribute('id')} from #{fromcat.attribute('Name')} #{fromcat.attribute('id')}"
      subcat = construct_category(node, fromcat.attribute('Name').to_s + "/")
      @categories << subcat
    end
  end

  def construct_category(node, parent_path)
    category_id = node.attribute('id').to_s
    name = parent_path + node.attribute('Name').to_s
    cat = SmugMugCategory.new(category_id, name)
  end
end


SmugMugAlbum = Struct.new(:album_id, :album_key, :title, :category_id, :category_name, :unique_title)

class SmugMugAlbumList
  include Enumerable

  def initialize(bridge, xml_resp)
    @bridge = bridge
    @albums = []
    @by_uniq_title = {}
    # doc = REXML::Document.new(xml_resp)
    doc = @bridge.xml_document_parse(xml_resp)
    root = doc.get_elements("rsp/Albums").first
    root or raise("bad server response - albums root element missing")
    parse_albums(root)
    @albums.each {|album| @by_uniq_title[album.unique_title] = album}
  end
  
  def count
    @albums.length
  end

  def find_by_unique_title(title)
    @by_uniq_title[title]
  end

  def unique_title_to_id(title)
    album = find_by_unique_title(title)
    album ? album.album_id : nil
  end

  def values
    @albums
  end

  def each
    values.each {|album| yield album}
  end

  private

  def parse_albums(parent_node)
    children = parent_node.get_elements("Album")
    children.each do |node|
      album = construct_album(node)
      @albums << album
    end
  end

  def construct_album(node)
    album_id = node.attribute('id').to_s
    album_key = node.attribute('Key').to_s
    title = node.attribute('Title').to_s
    cat = node.get_elements("Category").first
    if cat
      cat_id = cat.attribute('id').to_s
      cat_name = cat.attribute('Name').to_s
    else
      cat_id = "0"
      cat_name = "Other"
    end
    uniq_title = ensure_unique_name(@by_uniq_title, title)
    album = SmugMugAlbum.new(album_id, album_key, title, cat_id, cat_name, uniq_title)
  end

  # def get_child_text(node, child_name)
  #   child_node = node.get_elements(child_name).first
  #   txt = child_node ? child_node.text : ""
  # end
  
  def ensure_unique_name(uniq, orig_name)
    i = 2
    name = orig_name
    while uniq.has_key? name
      name = "#{orig_name} (#{i})"
      i += 1
    end
    uniq[name] = true
    name
  end
end


class SmugMugFileUploaderProtocol

  def initialize(pm_api_bridge)
    @bridge = pm_api_bridge
    @http = nil
    @cookies = {}
    # we may make multiple requests while uploading a file, and 
    # don't want the progress bar to jump around until we get
    # to the actual upload
    @mute_transfer_status = true
    close
  end

  def close
    if @http
      @http.finish rescue nil
      @http = nil
    end
    @session_id = nil
  end

  def image_upload(local_filepath, remote_filename, is_retry, spec)
#dbgprint "smugmug: image_upload: func_enter: #{remote_filename}"
    @mute_transfer_status = true
    if @session_id.nil?
      @bridge.set_status_message "Logging in to account #{spec.smugmug_login}..."
      login(spec.smugmug_login, spec.smugmug_password)
    end

    @bridge.set_status_message "Uploading via secure connection..."

    gallery_name = spec.smugmug_gallery
    gallery_id = spec.smugmug_gallery_id

    if gallery_id.to_s.empty?
      raise "Could not obtain SmugMug gallery id for #{gallery_name}. Does the gallery exist?"
    end

    upload(local_filepath, remote_filename, gallery_id)
#dbgprint "smugmug: image_upload: func_exit: #{remote_filename}"

    final_remote_filename = [gallery_name, remote_filename].join("/")
  end

  def reset_transfer_status
    (h = @http) and h.reset_transfer_status
  end

  # return [bytes_to_write, bytes_written]
  def poll_transfer_status
#dbgprint "poll_transfer_status mute is: #{@mute_transfer_status}"
    if (h = @http)  &&  ! @mute_transfer_status
#dbgprint "poll_transfer_status returning [#{h.bytes_to_write}, #{h.bytes_written}]"
      [h.bytes_to_write, h.bytes_written]
    else
#dbgprint "poll_transfer_status returning [0, 0]"
      [0, 0]
    end
  end

  def abort_transfer
    (h = @http) and h.abort_transfer
  end
  
  def login(uname, pass)
    @mute_transfer_status = true
    params = { "method" => "smugmug.login.withPassword",
               "EmailAddress" => uname,
               "Password" => pass,
               "APIKey" => API_KEY
             }
    headers = { "User-Agent" => "PM5" }
    body = get(params,headers).body

    if body !~ /invalid login/ and body =~ /Session id=\"([^\"]*)\"/
      @session_id = $1
    else
      raise "Unable to login to SmugMug account. Please check connection settings."
    end
  end

  def get_categories
    @mute_transfer_status = true
    @session_id or raise("get_categories: no session_id (not logged in?)")
    params = { "method" => 'smugmug.categories.get',
               "SessionID" => @session_id
             }
    headers = { "User-Agent" => "PM5" }
    resp = get(params, headers).body

    params = { "method" => 'smugmug.subcategories.getAll',
               "SessionID" => @session_id
             }
    headers = { "User-Agent" => "PM5" }
    sub_resp = get(params, headers).body

    categories = SmugMugCategoryList.new(@bridge, resp, sub_resp)
  end

  def get_albums
    #dbgprint "getting albums"
    @mute_transfer_status = true
    @session_id or raise("get_albums: no session_id (not logged in?)")
    params = { "method" => 'smugmug.albums.get',
               "SessionID" => @session_id
             }
    headers = { "User-Agent" => "PM5" }
    resp = get(params, headers).body

    albums = SmugMugAlbumList.new(@bridge, resp)
  end

  def create_album(name, category_id)
    @mute_transfer_status = true
    @session_id or raise("get_albums: no session_id (not logged in?)")
    params = { "method" => 'smugmug.albums.create',
               "SessionID" => @session_id,
               "Title" => name,
             }
    if (category_id)
      params["CategoryID"] = category_id
    end

    headers = { "User-Agent" => "PM5" }
    resp = get(params, headers).body
    (resp =~ /<rsp\s[^>]*stat\s*=[\s"]*ok/m) or raise("smugmug.albums.create failed for #{name.inspect}, category #{category_id.inspect}")
  end

  def upload(fname, remote_filename, album_id)
    @mute_transfer_status = true
    @session_id or raise("upload: no session_id (not logged in?)")

    url = "http://upload.smugmug.com/photos/xmlrawadd.mg"  # %TEMPFIX: using http instead of https because https connections are getting refused lately.
    uri = URI.parse(url)

#dbgprint "smugmug: upload local read_file begin: #{remote_filename}"
    fdata = @bridge.read_file_for_upload(fname)
#dbgprint "smugmug: upload local read_file end: #{remote_filename}"

    # Very elaborate http header
    headers = { 'Content-Length' => fdata.length.to_s,
                'Content-MD5' => Digest::MD5.hexdigest(fdata).to_s,
                'X-Smug-SessionID' => @session_id,
                'X-Smug-Version' => SMUG_VER,
                'X-Smug-ResponseType' => "REST",
                'X-Smug-AlbumID' => album_id,
                'X-Smug-FileName' => remote_filename,
                'User-Agent' => 'PM5'
              }
#dbgprint "smugmug: upload ensure_open_http begin: #{remote_filename}"
    ensure_open_http(uri.host, uri.port)
#dbgprint "smugmug: upload ensure_open_http end: #{remote_filename}"
    begin
      @mute_transfer_status = false
#dbgprint "smugmug: upload post begin: #{remote_filename}"
      resp = @http.post(uri.request_uri, fdata, headers)
#dbgprint "smugmug: upload post end: #{remote_filename}"
      require_server_success_response(resp)
    ensure
      #@mute_transfer_status = true
    end
#dbgprint "smugmug: upload **END**"
    true
  end
  
  protected

  def ensure_open_http(host, port)
    need_new_conection = false
    if @http
      need_new_connection = [@http.address, @http.port] != [host, port]
    else
      need_new_connection = true
    end
    if need_new_connection
      @http = @bridge.open_http_connection(host, port)
      @http.use_ssl = true if port == 443
      @http.open_timeout = 60
      @http.read_timeout = 180
    end
  end

  def gen_client_cookie(server_cookie_raw)
    sk = ServerCookie.new(server_cookie_raw)
    new_cookies_raw = sk.reject {|k| k =~ /deleted/}
    new_cookies = new_cookies_raw.map {|k| k.split(/;/)[0].strip}
    new_cookies.each do |k|
      key, val = k.split(/=/) # /
      @cookies[key.strip] = val.to_s.strip
    end
    baked = []
    @cookies.keys.sort.each do |key|
      baked << "#{key}=#{@cookies[key]}"
    end
    baked.join("; ")
  end
  
  def get(params, headers)
    vars = params.map{|k,v| "#{k}=#{CGI.escape(v)}"}.join('&')
    url = "#{REST_URL}?#{vars}"
    uri = URI.parse(url)
    ensure_open_http(uri.host, uri.port)
    headers['Cookie'] = "_su=" + @cookies["_su"] if @cookies["_su"]
    res = @http.get(uri.request_uri, headers)
    
    gen_client_cookie(res['set-cookie'])

    res
  end

  def require_server_success_response(resp)
    raise(RuntimeError, resp.inspect) unless resp.code == "200"
  end
end

# cookie =
#   "ID=867.5309; path=/; domain=site.com, " +
#   "SESS_mem=deleted; expires=Mon, 24 Jan 2005 19:48:10 GMT; path=/; domain=.site.com, " +
#   "SESS_mem=deleted; expires=Mon, 24-Jan-2005 19:48:10 GMT; path=/; domain=.site.com, " +
#   "SESS_mem=xyzzy-plugh-plover; path=/; domain=.site.com"

class ServerCookie
  include Enumerable

  class << self
    def parse(raw_cookie)
      dat = raw_cookie.gsub(/(expires\s*=\s*\w{3}),( \d{2}[ -]\w{3}[ -]\d{4} \d\d:\d\d:\d\d GMT)/i, '\1 \2')
      cookies = dat.split(/,/)
      cookies   # we could do further parsing, but Array#each + /regexp/ will get us through for now
    end
  end
  
  def initialize(raw_cookie)
#dbgprint "ServerCookie.initialize()"
    @raw = raw_cookie
    @cookies = ServerCookie.parse(raw_cookie)
  end
  
  def each
    raise "need block" unless block_given?
    @cookies.each do |k|
      yield k
    end
  end
end
