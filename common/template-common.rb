# coding: utf-8

FileSkippedException = PM::FileSkippedException

module ImageProcessingControlsCreation
  include PM::Dlg
  include CreateControlHelper

  SOURCE_RAW_LABEL = "Use the RAW"
  SOURCE_JPEG_LABEL = "Use the JPEG"
  RENDER_RAW_LABEL = "Render RAW if possible"
  USE_EMBEDDED_LABEL = "Use embedded preview"

  protected
  def create_image_processing_controls(parent_dlg)
    dlg = parent_dlg
    create_control(:imgproc_group_box,          GroupBox,       dlg, :label=>"Image Processing:")
    create_control(:cropping_static,            Static,         dlg, :label=>"Cropping:")
    create_control(:apply_crop_check,           CheckBox,       dlg, :label=>"Apply")
    create_control(:watermark_check,            CheckBox,       dlg, :label=>"")
    create_control(:watermark_btn,              WatermarkButton,dlg, :label=>"Watermark...")
    create_control(:scaling_static,             Static,         dlg, :label=>"Scaling:")
    create_control(:scale_none_radio,           RadioButton,    dlg, :label=>"no scaling", :checked=>true)
    create_control(:scale_box_radio,            RadioButton,    dlg, :label=>"to fit box:")
    create_control(:scale_percent_radio,        RadioButton,    dlg, :label=>"to percentage:")
    RadioButton.set_exclusion_group(@scale_none_radio, @scale_box_radio, @scale_percent_radio)

    create_control(:scale_box_size_edit,        EditControl,    dlg, :value=>"512")
    create_control(:scale_units_combo,          ComboBox,       dlg, :items => ["pixels", "#{@bridge.get_pixel_resolution_units}"], :selected=>"pixels", :sorted=>false, :persist=>true)
    create_control(:scale_percent_edit,         EditControl,    dlg, :value=>"100", :formatter=>"unsigned")
    create_control(:scale_percent_spin,         SpinControl,    dlg, :min=>1, :max=>100, :value=>100, :buddy=>@scale_percent_edit.ctrl_id)

    create_control(:render_res_static,          Static,         dlg, :label=>"Resolution:")
    create_control(:render_res_edit,            EditControl,    dlg, :value=>"#{@bridge.get_default_resolution}")
    res_label = "pixels per #{@bridge.get_pixel_resolution_unit}"
    create_control(:render_ppi_static,          Static,         dlg, :label=>res_label)

    create_control(:source_raw_jpeg_static,     Static,         dlg, :label=>"Source for RAW+JPEG:")
    create_control(:source_raw_jpeg_combo,      ComboBox,       dlg, :items => [SOURCE_RAW_LABEL, SOURCE_JPEG_LABEL], :selected=>SOURCE_JPEG_LABEL, :sorted=>false, :persist=>true)
    create_control(:when_using_raw_static,      Static,         dlg, :label=>"When using RAW:")
    create_control(:when_using_raw_combo,       ComboBox,       dlg, :items => [RENDER_RAW_LABEL, USE_EMBEDDED_LABEL], :selected=>USE_EMBEDDED_LABEL, :sorted=>false, :persist=>true)

    create_control(:convert_to_sRGB_check,      CheckBox,       dlg, :label=>"Convert to sRGB")
    create_control(:sharpen_check,              CheckBox,       dlg, :label=>"Sharpen")
  end
  
  def create_jpeg_controls(parent_dlg)
    dlg = parent_dlg
    create_control(:jpeg_low_static,            Static,         dlg, :label=>"Quality: Low", :align=>"right")
    create_control(:jpeg_high_static,           Static,         dlg, :label=>"High")
    create_control(:jpeg_size_static,           Static,         dlg, :label=>"", :align=>"right")
    create_control(:jpeg_qlty100_slider,        SliderControl,  dlg, :min=>0, :max=>100, :value=>80)
    create_control(:jpeg_minqlty_slider,        SliderControl,  dlg, :min=>0, :max=>100, :value=>20)
    create_control(:jpeg_chroma_check,          CheckBox,       dlg, :label=>"Subsample Chroma")
    create_control(:jpeg_limit_size_check,      CheckBox,       dlg, :label=>"Limit file size to:")
    create_control(:jpeg_limit_size_edit,       EditControl,    dlg, :value=>"2.0")
    create_control(:jpeg_limit_size_static,     Static,         dlg, :label=>"MB")
  end
end

module RenamingControlsCreation
  include PM::Dlg
  include CreateControlHelper

  protected

  def create_renaming_controls(parent_dlg)
    dlg = parent_dlg
    create_control(:rename_as_check,            CheckBox,       dlg, :label=>"Rename as:")
    create_control(:rename_string_edit,         EditControl,    dlg, :value=>"")
    create_control(:use_seqn_check,             CheckBox,       dlg, :label=>"sequence")
    create_control(:seqn_static,                Static,         dlg, :label=>"")
    create_control(:set_seqn_btn,               SequenceDialogButton, dlg, :label=>"Set {seqn} variable...")
  end
end

module OperationsControlsCreation
  include PM::Dlg
  include CreateControlHelper
  include RenamingControlsCreation

  protected
  
  def create_operations_controls(parent_dlg)
    dlg = parent_dlg  
    create_control(:operations_group_box,       GroupBox,       dlg, :label=>"Operations:")
    create_control(:apply_iptc_check,           CheckBox,       dlg, :label=>"Apply Metadata (IPTC) Template")
    create_control(:stationery_pad_btn,         StationeryPadButton, dlg, :label=>"Metadata (IPTC) Template...")
    create_control(:preserve_exif_check,        CheckBox,       dlg, :label=>"Preserve EXIF information when possible", :checked=>true)
    create_renaming_controls(dlg)

    create_control(:save_copy_check,            CheckBox,       dlg, :label=>"Save a copy of transmitted photos:")
    create_control(:save_copy_subdir_radio,     RadioButton,    dlg, :label=>"In a sub-directory:")
    create_control(:save_copy_userdir_radio,    RadioButton,    dlg, :label=>"In a specified directory:", :checked=>true)
    RadioButton.set_exclusion_group(@save_copy_subdir_radio, @save_copy_userdir_radio)
    create_control(:save_copy_subdir_edit,      EditControl,    dlg, :value=>"sent")
    create_control(:save_copy_choose_userdir_btn, Button,       dlg, :label=>"Choose...")
    create_control(:save_copy_userdir_static,   Static,         dlg, :value=>"", :persist=>true)
  end
end

module ImageProcessingControlsLayout
  protected

  def layout_image_processing_controls(c, eh, sh, w1, w2, w1w)
    c << @cropping_static.layout(0, c.base+2, w1, sh)
      c << @apply_crop_check.layout(w1, c.base, w1w, eh)
        c << @watermark_check.layout(w2, c.base, 18, eh)
          c << @watermark_btn.layout(c.prev_right, c.base, 120, eh)
    c.pad_down(5).mark_base

    c << @scaling_static.layout(0, c.base+2, w1, sh)
      c << @scale_none_radio.layout(w1, c.base, w1w, eh)
      c.pad_down(5).mark_base
      c << @scale_box_radio.layout(w1, c.base, w1w, eh)
        c << @scale_box_size_edit.layout(w2, c.base, 60, eh)
          c << @scale_units_combo.layout(c.prev_right, c.base, 100, eh)
      c.pad_down(5).mark_base
      c << @scale_percent_radio.layout(w1, c.base, w1w, eh)
        c << @scale_percent_edit.layout(w2, c.base, 36, eh)
          c << @scale_percent_spin.layout(c.prev_right-5, c.base, 16, eh)
    c.pad_down(5).mark_base

    c << @render_res_static.layout(0, c.base+2, w1, sh)
      c << @render_res_edit.layout(w1, c.base, 80, eh)
        c << @render_ppi_static.layout(c.prev_right, c.base+2, 100, sh)
    c.pad_down(5).mark_base

    c << @sharpen_check.layout(w1, c.base, 80, eh)
    c << @convert_to_sRGB_check.layout(w2, c.base, 120, eh)
    c.pad_down(5).mark_base

    c << @source_raw_jpeg_static.layout(0, c.base+4, 150, sh)
      c << @source_raw_jpeg_combo.layout(c.prev_right, c.base, 180, eh)
    c.pad_down(5).mark_base
    c << @when_using_raw_static.layout(0, c.base+4, 150, sh)
      c << @when_using_raw_combo.layout(c.prev_right, c.base, 180, eh)
    c.pad_down(5).mark_base

    c.mark_base.size_to_base
  end
  
  def layout_jpeg_controls(c, eh, sh)
      c << @jpeg_low_static.layout(12, c.base+3, 80, sh)
        slider_left = c.prev_right
        c << @jpeg_qlty100_slider.layout(slider_left, c.base, -40, 35)
          x = c.prev_right
          c << @jpeg_high_static.layout(c.prev_right, c.base+3, -1, sh)
      c.pad_down(5).mark_base
      c << @jpeg_chroma_check.layout(slider_left, c.base, 150, sh)
        c << @jpeg_size_static.layout(c.prev_right, c.base, -1, sh)
      c.pad_down(5).mark_base
      c << @jpeg_limit_size_check.layout(slider_left, c.base, 125, eh)
        c << @jpeg_limit_size_edit.layout(c.prev_right, c.base, 50, eh)
          c << @jpeg_limit_size_static.layout(c.prev_right, c.base+5, 35, eh)
      c.pad_down(5).mark_base

      @jpeg_minqlty_slider.bounds = @jpeg_qlty100_slider.bounds.dup
  end
end

module RenamingControlsLayout
  protected

  def layout_renaming_controls(c, eh, sh, w1) 
    c << @rename_as_check.layout(0, c.base, 100, eh)
    c.pad_down(5).mark_base
      c << @rename_string_edit.layout(w1, c.base, -100, eh)
        c << @use_seqn_check.layout(-90, c.base, -1, eh)
      c.pad_down(5).mark_base
      c << @seqn_static.layout(w1+10, c.base+3, 200, sh)
        c << @set_seqn_btn.layout(-170, c.base, -11, eh)
    c.pad_down(5).mark_base
  end
end

module OperationsControlsLayout
  include RenamingControlsLayout

  protected  
  def layout_operations_controls(container, eh, sh, rp)
    container.layout_with_contents(@operations_group_box, "50%+5", container.base, -1, -1) do |c|
      c.set_prev_right_pad(rp).inset(10,25,-10,-5).mark_base

      w1 = 30
      c << @apply_iptc_check.layout(0, c.base, 215, eh)
        c << @stationery_pad_btn.layout(-180, c.base, -11, eh)
      c.pad_down(5).mark_base
      c << @preserve_exif_check.layout(0, c.base, 300, eh)
      c.pad_down(5).mark_base
      layout_renaming_controls(c, eh, sh, w1)

      w2 = 200
      c << @save_copy_check.layout(0, c.base, 300, eh)
      c.pad_down(5).mark_base
        c << @save_copy_subdir_radio.layout(w1, c.base, w2-w1, eh)
          c << @save_copy_subdir_edit.layout(w2, c.base, -11, eh)
        c.pad_down(5).mark_base
        c << @save_copy_userdir_radio.layout(w1, c.base, w2-w1, eh)
          c << @save_copy_choose_userdir_btn.layout(w2, c.base, 100, eh)
      c.pad_down(5).mark_base
      c << @save_copy_userdir_static.layout(w1+20, c.base, -1, sh)
      c.pad_down(5).mark_base

      c.pad_down(5).mark_base.size_to_base
    end
  end
end

module ImageProcessingControlsLogic
  protected

  RENDER_RAW_LABEL = "Render RAW if possible"
  USE_EMBEDDED_LABEL = "Use embedded preview"

  @@g_scale_units_are_pixels = true

  def adjust_image_processing_controls
    sending_originals = @ui.send_original_radio.checked?
    enable_imageproc_controls = !sending_originals

    ctls = [
 #    @ui.jpeg_low_static,
 #    @ui.jpeg_high_static,
 #    @ui.jpeg_size_static,
      @ui.jpeg_qlty100_slider,
      @ui.jpeg_chroma_check,
      @ui.imgproc_group_box,
 #    @ui.cropping_static,
      @ui.apply_crop_check,
      @ui.watermark_check,
      @ui.watermark_btn,
 #    @ui.scaling_static,
      @ui.scale_none_radio,
      @ui.scale_box_radio,
      @ui.scale_percent_radio,
      @ui.scale_box_size_edit,
      @ui.scale_units_combo,
      @ui.scale_percent_edit,
      @ui.scale_percent_spin,
      @ui.render_res_edit,
      @ui.convert_to_sRGB_check,
      @ui.sharpen_check,
 #    @ui.source_raw_jpeg_static,
      @ui.source_raw_jpeg_combo,
 #    @ui.when_using_raw_static,
      @ui.when_using_raw_combo
    ]

    ctls << @ui.preserve_exif_check if @ui.operations_enabled?

    have_jpeg_size_limits = !! @ui.instance_variable_get("@jpeg_limit_size_check")

    if have_jpeg_size_limits
      ctls += [@ui.jpeg_minqlty_slider, @ui.jpeg_limit_size_check, @ui.jpeg_limit_size_edit]
    end

    # because on mac, disabled statics don't dim :(
    @ui.jpeg_size_static.show(enable_imageproc_controls)

    # preserve exif does not apply when disabled (hide/show)
    @ui.preserve_exif_check.show(enable_imageproc_controls) if @ui.operations_enabled?

    ctls.each {|ctl| ctl.enable(enable_imageproc_controls)}

    if have_jpeg_size_limits
      adjust_jpeg_controls(enable_imageproc_controls)
    end

    if ! @bridge.platform_supports_raw_rendering?
      @ui.when_using_raw_combo.set_selected_item(USE_EMBEDDED_LABEL)
    end

    if enable_imageproc_controls
      if @ui.scale_none_radio.checked?
          @ui.scale_box_size_edit.enable(false)
          @ui.scale_units_combo.enable(false)
          @ui.scale_percent_edit.enable(false)
          @ui.scale_percent_spin.enable(false)
      elsif @ui.scale_box_radio.checked?
        @ui.scale_percent_edit.enable(false)
        @ui.scale_percent_spin.enable(false)
      elsif @ui.scale_percent_radio
        @ui.scale_box_size_edit.enable(false)
        @ui.scale_units_combo.enable(false)
      end
      if ! @bridge.platform_supports_raw_rendering?
        @ui.when_using_raw_combo.enable(false)
      end
    end
  end

  def adjust_jpeg_controls(enable_imageproc_controls)
    is_limiting = @ui.jpeg_limit_size_check.checked?
    @ui.jpeg_qlty100_slider.show(! is_limiting)
    @ui.jpeg_minqlty_slider.show(is_limiting)
    if enable_imageproc_controls
      @ui.jpeg_limit_size_edit.enable(is_limiting)
    end
  end

  def preflight_jpeg_controls
    is_limiting = @ui.jpeg_limit_size_check.checked?
    
    if is_limiting
      limit_size = Float(@ui.jpeg_limit_size_edit.get_text) rescue 0
      raise "Please enter a file size limit of at least 0.01 MB." unless limit_size >= 0.01
    end
  end

  def add_image_processing_controls_event_hooks
    @ui.scale_none_radio.on_click {adjust_controls}
    @ui.scale_box_radio.on_click {adjust_controls}
    @ui.scale_percent_radio.on_click {adjust_controls}
    @ui.scale_units_combo.on_sel_change {adjust_scale_units}
  end

  def add_jpeg_controls_event_hooks
    @ui.jpeg_limit_size_check.on_click {adjust_controls}
  end

  def adjust_scale_units
    resolution = @ui.render_res_edit.get_text.to_i
    resolution = 72 if resolution.zero?

    new_units_are_pixels = @ui.scale_units_combo.get_selected_item_text == "pixels"
    if @@g_scale_units_are_pixels != new_units_are_pixels
      if new_units_are_pixels
        # units changed from inches to pixels
        inches = @ui.scale_box_size_edit.get_text.to_f
        pixels = ((inches * resolution) + 0.5).to_i
        @ui.scale_box_size_edit.set_text("#{pixels}")
      else
        # units changed from pixels to inches
        pixels = @ui.scale_box_size_edit.get_text.to_i
        inches = pixels.to_f / resolution.to_f
        @ui.scale_box_size_edit.set_text("#{inches}")
      end
    end
  end

  def build_jpeg_spec(spec, ui)
    if ui.jpeg_limit_size_check.checked?
      spec.jpeg_quality = [100, [0, ui.jpeg_minqlty_slider.getpos].max].min
      spec.jpeg_max_file_size = (1024 * 1024 * ui.jpeg_limit_size_edit.get_text.to_f).to_i
    else
      spec.jpeg_quality = [100, [0, ui.jpeg_qlty100_slider.getpos].max].min
      spec.jpeg_max_file_size = 0
    end
    spec.subsample_chroma = ui.jpeg_chroma_check.checked?
  end

  def build_image_processing_spec(spec, ui)
    spec.imgproc_resolution = ui.render_res_edit.get_text.to_i
    spec.imgproc_resolution = 72 if spec.imgproc_resolution.zero?

    spec.raw_jpeg_render_source = ui.raw_jpeg_render_source
    spec.use_raw_previews = true
    spec.apply_crop = ui.apply_crop_check.checked?
    spec.do_watermark = ui.watermark_check.checked?
    spec.watermark_settings = ui.watermark_btn.settings

    @@g_scale_units_are_pixels = spec.scale_units_are_pixels = ui.scale_units_combo.get_selected_item_text == "pixels"

    spec.convert_to_sRGB = ui.convert_to_sRGB_check.checked?
    spec.sharpen = ui.sharpen_check.checked?
    if ui.scale_box_radio.checked?
      spec.scale_type = "box"
    elsif ui.scale_percent_radio.checked?
      spec.scale_type = "percent"
    else
      spec.scale_type = "none"
    end
    spec.scale_box_size = ui.scale_box_size_edit.get_text
    spec.scale_percent = ui.scale_percent_edit.get_text.to_i
    spec.use_raw_previews = false if ui.when_using_raw_combo.get_selected_item == RENDER_RAW_LABEL
  end
end

module RenamingControlsLogic
  protected

  def add_renaming_controls_event_hooks
    @ui.rename_as_check.on_click {adjust_controls}

    @ui.use_seqn_check.on_click do
      handle_add_remove_seqn_from_rename_edit
      adjust_controls
    end

    @ui.rename_string_edit.on_edit_change { update_use_seqn_check }
    @ui.set_seqn_btn.on_click {set_seqn_static_to_current_seqn}
  end

  def update_use_seqn_check
    has_seqn = @ui.rename_string_edit.get_text.contains_seqn_variable?
    @ui.use_seqn_check.set_check has_seqn
    adjust_renaming_controls
  end

  def handle_add_remove_seqn_from_rename_edit
    add_flag = @ui.use_seqn_check.checked?
    txt = @ui.rename_string_edit.get_text.dup
    if add_flag
      txt << "{seqn}" unless txt =~ /\{(seqn|sequence|auto)\}/
    else
      txt.gsub!(/\{(seqn|sequence|auto)\}/, "")
    end
    @ui.rename_string_edit.set_text txt
  end

  def set_seqn_static_to_current_seqn
    if @num_files > 0
      @num_files.times do |img_idx|
        begin
          txt = @bridge.expand_vars("seqn = {seqn}", img_idx+1)  # index is one-based
          @ui.seqn_static.set_text txt
          break
        rescue StandardError => ex
          dbglog "set_seqn_static_to_current_seqn: expand_vars failed: #{ex.message} - trying next image..."
        end
      end
    end
  end

  def adjust_renaming_controls
    enable_renaming_controls = @ui.rename_as_check.checked?
    ctls = [    
      @ui.rename_string_edit,
      @ui.use_seqn_check,
    ]
    ctls.each {|ctl| ctl.enable(enable_renaming_controls)}

    renaming_and_using_seqn = enable_renaming_controls && @ui.use_seqn_check.checked?
    @ui.set_seqn_btn.enable( renaming_and_using_seqn )
    @ui.seqn_static.enable( renaming_and_using_seqn )
    @ui.seqn_static.show( renaming_and_using_seqn )
  end

  def build_renaming_spec(spec, ui)
    spec.do_rename = ui.rename_as_check.checked?
    spec.rename_string = ui.rename_string_edit.get_text
  end

  def preflight_renaming_controls
    return unless @ui.rename_as_check.checked?
    
    rstr = @ui.rename_string_edit.get_text
    if rstr.strip.empty?
      raise("\"Rename as\" is checked, but renaming field is blank. "+
            "Please enter a valid renaming expression, or "+
            "uncheck the Rename checkbox.")
    end

    need_seqn = (@num_files > 1) && ! @bridge.vars_have_renaming_var?(rstr)
    if need_seqn
      raise("\"Rename as\" is checked, but there are multiple files to "+
            "send, so the renaming expression must include a "+
            "renaming variable or sequence variable, such as {seqn}. "+
            "Please enter a valid renaming expression, or "+
            "uncheck the Rename checkbox.")
    end

    # After evaluating the variable, check to see if we have an empty rename string.
    if @bridge.vars_have_renaming_var?(rstr)
      @num_files.times do |img_idx|
        begin
          txt = @bridge.expand_vars(rstr, img_idx+1)
          raise if txt.strip.empty?
        rescue StandardError => ex
          raise("The variable #{rstr} returned an empty string. "+
                "Please enter a valid renaming expression, or "+
                "uncheck the Rename checkbox.")
        end
      end
    end
  end
end

module OperationsControlsLogic
  protected

  def add_operations_controls_event_hooks
    @ui.save_copy_check.on_click {adjust_controls}

    @ui.save_copy_choose_userdir_btn.on_click do
      handle_choose_save_copy_userdir
    end
    @ui.save_copy_userdir_radio.on_click do
      if @ui.save_copy_userdir_static.get_text.empty?
        path = handle_choose_save_copy_userdir.to_s
        if path.empty?
          @ui.save_copy_subdir_radio.set_check
        end
      end
    end
  end

  def handle_choose_save_copy_userdir
    choose_prompt = "Please select the destination folder for saved photos:"
    allow_create_folders = true
    old_path = @ui.save_copy_userdir_static.get_text
    path = @bridge.choose_directory(old_path, choose_prompt, allow_create_folders)
    @ui.save_copy_userdir_static.set_text(path) if path
    path
  end
  
  def adjust_operations_controls
    enable_save_copy_controls = @ui.save_copy_check.checked?
    ctls = [
      @ui.save_copy_subdir_radio,
      @ui.save_copy_subdir_edit,
      @ui.save_copy_userdir_radio,
      @ui.save_copy_choose_userdir_btn,
      @ui.save_copy_userdir_static,
    ]
    ctls.each {|ctl| ctl.enable(enable_save_copy_controls)}
  end

  def build_operations_spec(spec, ui)
    spec.apply_stationery_pad = ui.apply_iptc_check.checked?
    spec.preserve_exif = ui.preserve_exif_check.checked?
    spec.save_transmitted_photos = ui.save_copy_check.checked?
    spec.save_photos_subdir_type = ui.save_copy_subdir_radio.checked? ? "subdir" : "specific"
    spec.save_photos_subdir = ui.save_copy_subdir_edit.get_text
    spec.save_photos_specific_dir = ui.save_copy_userdir_static.get_text
  end

  def preflight_operations_controls
    if @ui.save_copy_check.checked?
      if @ui.save_copy_subdir_radio.checked?
        if @ui.save_copy_subdir_edit.get_text.strip.empty?
          raise("\"Save a copy of transmitted photos\" is checked, but "+
                "the sub-directory field is empty. Please provide a "+
                "sub-directory name, or change the \"Save a copy...\" options.")
        end
      else
        dir = @ui.save_copy_userdir_static.get_text
        if dir.strip.empty?
          raise("\"Save a copy of transmitted photos\" is checked, but "+
                "the specified directory field is empty. Please choose a "+
                "save directory, or change the \"Save a copy...\" options.")
        elsif ! @bridge.dir_exists?(dir)
          raise("\"Save a copy of transmitted photos\" is checked, but "+
                "the specified directory \"#{dir}\" cannot be found. Please choose a "+
                "save directory, or change the \"Save a copy...\" options.")
        end
      end
    end
  end
end

##############################################################################

module CopyPhotosComboConstants
  COPY_PHOTOS_DIRECT_DEST      = "directly into destination folder"
  COPY_PHOTOS_DEST_DATED       = "into destination with dated folder"
  COPY_PHOTOS_DEST_NAMED       = "into destination with name"
  COPY_PHOTOS_DEST_DATED_NAMED = "into destination with dated folder and name"
  
  def self.label_to_spec(label)
    case label
    when COPY_PHOTOS_DEST_DATED       then "dest_with_dated_folder"
    when COPY_PHOTOS_DEST_NAMED       then "dest_with_name"
    when COPY_PHOTOS_DEST_DATED_NAMED then "dest_with_dated_folder_and_name"
    # default: COPY_PHOTOS_DIRECT_DEST
    else "dest_direct"
    end
  end
end

module CommonDestFolderLogic
  protected
  def compute_dest_folder_path(dest_folder_path, copy_photos_style, folder_name)
    do_dated = do_named = false
    case copy_photos_style
    when CopyPhotosComboConstants::COPY_PHOTOS_DEST_DATED       then do_dated = true
    when CopyPhotosComboConstants::COPY_PHOTOS_DEST_NAMED       then do_named = true
    when CopyPhotosComboConstants::COPY_PHOTOS_DEST_DATED_NAMED then do_dated = do_named = true
    end

    path = dest_folder_path.tr("\\","/")
    if do_dated
      # path = File.join(path, Time.now.strftime("%Y%m%d"))
      path = File.join(path, "{todaysort}")
    end
    if do_named
      path = File.join(path, folder_name.tr("\\","/"))
    end
    path
  end
end

module JpegSizeEstimationLogic
  protected
  def handle_jpeg_size_estimation(recalc=true)
    return unless @ui
    
    have_jpeg_size_limits = !! @ui.instance_variable_get("@jpeg_limit_size_check")

    if have_jpeg_size_limits && @ui.jpeg_limit_size_check.checked?
      handle_limit_size_update
    else
      handle_jpeg_dynamic_size_estimation(recalc)
    end
  end

  def handle_limit_size_update
    @ui.jpeg_size_static.set_text "Min. Quality:#{@ui.jpeg_minqlty_slider.getpos}"    
  end

  def handle_jpeg_dynamic_size_estimation(recalc)
    unless @num_files > 0
      @ui.jpeg_size_static.set_text ""
      return
    end

    if recalc
      acct = self.respond_to?(:current_account_settings, true) ? current_account_settings : cur_account_settings
      if acct
        spec = build_upload_spec(acct, @ui)
        spec = spec.__to_hash__   # can't sent AutoStruct across bridge, but can send plain Hash
        img_idx = 1  # just use 1st selected image
        @bridge.background_compute_jpeg_size(img_idx, spec)
      end
    end

    size = @bridge.fetch_computed_jpeg_size
    size_str = if size.nil?
      "error"
    elsif ! size   # false when "in progress"
      " . . . "
    else
      fmt_bytesize(size)
    end

    @ui.jpeg_size_static.set_text "#{@ui.jpeg_qlty100_slider.getpos}:#{size_str}"    
  end
end

module UpdateComboLogic
  protected
  def update_combo(ctrl_name, new_item_list)
    ctl = @ui.send(ctrl_name)
    if new_item_list.sort != ctl.get_item_list.sort
      prev_sel_item = ctl.get_selected_item
      ctl.reset_content( new_item_list )
      ctl.set_selected_item(prev_sel_item) unless prev_sel_item.empty?
      # if no item was selected, just select the 1st one
      if ctl.get_selected_item.empty?  &&  ctl.num_items > 0
        ctl.set_selected_item( ctl.get_item_at(0) )
      end
    end
  end
end

module FormatBytesizeLogic
  def fmt_bytesize(bytes)
    bytes = bytes.to_f
    if bytes >= 1024**3
      bytes /= 1024**3
      units = "GB"
    elsif bytes >= 1024**2
      bytes /= 1024**2
      units = "MB"
    elsif bytes >= 1024
      bytes /= 1024
      units = "KB"
    else
      units = ""
    end
    sprintf("%2.2f %s", bytes, units)
  end
end

module PreflightWaitAccountParametersLogic
  # this is fairly specialized logic, used by a few of
  # the templates to wait for the background data fetch
  # to complete during the preflight stage
  def preflight_wait_account_parameters_or_timeout(timeout_secs=15)
    tout = Time.now + timeout_secs
    if @account_parameters_dirty
      loop do
        sleep 0.1
        @data_fetch_worker.exec_messages
        break unless @account_parameters_dirty
        raise("Timeout waiting for account parameters from server.") if Time.now >= tout
      end
    end
  end
end


##############################################################################

CrossThreadMessage = Struct.new(:target_obj, :reply_q, :message, :args)

class CrossThreadMessageProxy < BlankSlate
  def initialize(dispatcher, target_obj, queue)
    @dispatcher = dispatcher
    @target_obj = target_obj
    @replyq = queue
  end

  def method_missing(name, *args)
    msg = CrossThreadMessage.new(@target_obj, @replyq, name, args)
    @dispatcher.enqueue_message(msg)
    result = @replyq.pop
    result.kind_of?(Exception) ? raise(result) : result
  end
end

class CrossThreadMessageDispatcher
  def initialize(queue_factory_proc)
    @qfactory = queue_factory_proc
    @msgq = @qfactory.call
  end
  
  def wrap_obj(obj)
    CrossThreadMessageProxy.new(self, obj, @qfactory.call)
  end
  
  def exec_messages
    until @msgq.empty?
      msg = @msgq.pop
      execmsg(msg)
    end
  end
  
  def enqueue_message(msg)
    @msgq.push(msg)
  end
  
  protected
  
  def execmsg(msg)
    res = nil
    begin
      res = msg.target_obj.__send__(msg.message, *msg.args)
    rescue Exception => ex
      dbglog "CrossThreadMessageDispatcher::execmsg: msg=#{msg.message.inspect} exception: #{ex.inspect}\n#{ex.backtrace_to_s}"
      res = ex
    end
    msg.reply_q.push(res)
  end
end

class BackgroundDataFetchWorkerManager
  def initialize(worker_class, queue_factory, worker_args_to_wrap)
    @dispatcher = CrossThreadMessageDispatcher.new(queue_factory)
    wrapped_args = wrap_objs(worker_args_to_wrap)
    @worker_obj = worker_class.new(*wrapped_args)
    @done = false
    @worker_th = Thread.new { run_worker_task }
  end

  def exec_messages
    @dispatcher.exec_messages
  end
  
  def terminate
    @done = true
    if @worker_th
      while @worker_th.alive?
        # can't just join worker thread, because
        # it is likely waiting on a queue which
        # can only be satisfied by exec_messages
        exec_messages rescue nil
      end
      @worker_th = nil
      @worker_obj = nil
      @dispatcher = nil
    end
  end
  
  protected
  
  def wrap_objs(objs)
    objs.map {|o| @dispatcher.wrap_obj(o)}
  end
  
  def run_worker_task
    until @done
      begin
        @worker_obj.do_task
      rescue SignalException, SystemExit => ex
        @done = true
      rescue Exception => ex
        dbglog "BackgroundDataFetchWorkerManager::run_worker_task: caught exception: #{ex.message}\n#{ex.backtrace_to_s}"
      end
      sleep 0.25
    end
  end
end



##############################################################################

MimeMultipart = PM::MimeMultipart
WWWFormUrlencoded = PM::WWWFormUrlencoded



##############################################################################

module TemplateUnitTestAsserts
  def assert(val, msg="assert failed")
    val or raise("#{msg}: #{val.inspect} is not true")
  end
  
  def assert_equal(expected, actual, msg="assert failed")
    (expected == actual) or raise("#{msg}: expected #{expected.inspect}, got #{actual.inspect}")
  end
end


##############################################################################
#
# Super classes with generic functionality for OAuth based uploaders
# See the Twitter and 500px uploaders for implementations examples
#
# Developed by Hayo Baan
#
##############################################################################

class OAuthConnectionSettingsUI
  include PM::Dlg
  include AutoAccessor
  include CreateControlHelper

  def initialize(pm_api_bridge)
    @bridge = pm_api_bridge
  end

  def create_controls(dlg)
    
    
    create_control(:setting_name_static,      Static,       dlg, :label=>"Your Accounts:")
    create_control(:setting_name_combo,       ComboBox,     dlg, :editable=>false, :sorted=>true, :persist=>false)
    create_control(:add_account_instructions, Static,       dlg, :label=>"Note on adding an account: If you have an active #{TEMPLATE_DISPLAY_NAME} session in your browser, #{TEMPLATE_DISPLAY_NAME} will authorize Photo Mechanic for the account associated with that session. Otherwise, #{TEMPLATE_DISPLAY_NAME} will prompt you to login.\nAfter authorizing Photo Mechanic, please enter the verification code below and press the Verify Code button. The account name will be determined automatically from your #{TEMPLATE_DISPLAY_NAME} user name.")
    create_control(:setting_delete_button,    Button,       dlg, :label=>"Delete Account")
    create_control(:setting_add_button,       Button,       dlg, :label=>"Add/Replace Account")
    create_control(:code_group_box,           GroupBox,     dlg, :label=>"Verification code:")
    create_control(:code_edit,                EditControl,  dlg, :value=>"Enter verification code", :persist=>false, :enabled=>false)
    create_control(:code_verify_button,       Button,       dlg, :label=>"Verify Code", :enabled=>false)
  end

  def layout_controls(c)
    sh, eh = 20, 24
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
    c.layout_with_contents(@code_group_box, 0, c.base, -1, -1) do |cc|
      cc.set_prev_right_pad(5).inset(15,20,-20,-5).mark_base
      cc << @code_edit.layout(0, cc.base, -125, eh)
      cc << @code_verify_button.layout(cc.prev_right+5, cc.base, 120, eh)
      cc.pad_down(5).mark_base
      cc.mark_base.size_to_base
    end
    c.pad_down(5).mark_base
    c.mark_base.size_to_base
  end

  def add_event_handlers(connection_settings)
    setting_name_combo.on_sel_change { connection_settings.handle_combo_change }
    setting_delete_button.on_click   { connection_settings.handle_delete_click }
    setting_add_button.on_click      { connection_settings.handle_add_click }
    code_verify_button.on_click      { connection_settings.handle_verify_click }
  end

  def enable_code_entry()
    code_verify_button.enable(true)
    code_edit.enable(true)
    code_edit.set_text("")
    code_edit.set_focus
    setting_delete_button.enable(false)
    setting_add_button.enable(false)
  end

  def disable_code_entry(txt = "Enter verification code")
    code_verify_button.enable(false)
    code_edit.enable(false)
    code_edit.set_text(txt)
    setting_delete_button.enable(true)
    setting_add_button.enable(true)
  end
end # OAuthConnectionSettingsUI


class OAuthConnectionSettings
  DLG_SETTINGS_KEY = :connection_settings_dialog

  def self.template_display_name
    TEMPLATE_DISPLAY_NAME
  end
  
  def self.template_description
    "#{TEMPLATE_DISPLAY_NAME} Connection Settings"
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
    attr_accessor :account_name, :access_token, :access_token_secret

    def initialize(name, token, token_secret)
      @account_name = name
      @access_token = token
      @access_token_secret = token_secret
      self
    end

    def appears_valid?
      return ! (@account_name.nil? || @account_name.empty? || @access_token.nil? || @access_token.empty? || @access_token_secret.nil? || @access_token_secret.empty?)
    rescue
      false
    end

    def self.serialize_settings_hash(settings)
      out = {}
      settings.each_pair do |key, dat|
        out[key] = [dat.access_token, dat.access_token_secret]
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

  def create_controls(dlg)
    @ui = OAuthConnectionSettingsUI.new(@bridge)
    @ui.create_controls(dlg)
    @ui.add_event_handlers(self)
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

  def handle_combo_change
    # NOTE: We rely fully on the prev. selected name here, because the
    # current selected name has already changed.
    if @prev_selected_settings_name
      save_current_values_to_settings(:name=>@prev_selected_settings_name, :replace=>true)
    end
    load_current_values_from_settings
    @prev_selected_settings_name = current_account_name
  end

  def handle_add_click
    begin
dbgprint "handle_add_click"
      client.reset!
dbgprint "client.fetch_request_token"
      client.fetch_request_token
dbgprint "client.launch_application_authorization_in_browser"
      client.launch_application_authorization_in_browser
dbgprint "@ui.enable_code_entry"
      @ui.enable_code_entry
dbgprint "@prev_selected_settings_name = nil"
      @prev_selected_settings_name = nil
    rescue StandardError => e
      msg = "Server error: #{e}"
      dbglog "#{self.class.name}:#{__method__}: #{msg}"
      Dlg::MessageBox.ok(msg, Dlg::MessageBox::MB_ICONEXCLAMATION)
    end
  end

  def handle_delete_click
    cur_name = current_account_name
    @ui.setting_name_combo.remove_item(cur_name) if @ui.setting_name_combo.has_item? cur_name
    delete_in_settings(cur_name)
    @prev_selected_settings_name = nil
    if @ui.setting_name_combo.num_items > 0
      @ui.setting_name_combo.set_selected_item( @ui.setting_name_combo.get_item_at(0) )
      handle_combo_change
    else
      clear_settings
    end
  end

  def handle_verify_click
    code = @ui.code_edit.get_text.strip
    Dlg::MessageBox.ok("Please enter a non-blank code.", Dlg::MessageBox::MB_ICONEXCLAMATION) and return if code.empty?

    begin
      result = client.get_access_token(code)
      @settings[client.name] = SettingsData.new(client.name, client.access_token, client.access_token_secret)
      add_account_to_dropdown(client.name)
      @ui.disable_code_entry("Verified #{client.name}")
    rescue StandardError => e
      msg = "Failed to verify code"
      @ui.disable_code_entry(msg)
      dbglog "#{self.class.name}:#{__method__}: #{msg}: #{e} - #{e.backtrace}"
      # Note: A failed verification requires a complete new round of authorization!
      msg = "Error: #{msg}, please retry to add the account."
      Dlg::MessageBox.ok(msg, Dlg::MessageBox::MB_ICONEXCLAMATION)
    end
  end

  def handle_new_button
    # TODO: Clear connection name and settings
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

  def clear_settings
    @ui.setting_name_combo.set_text ""
  end
end # OAuthConnectionSettings


class OAuthFileUploaderUI
  include PM::Dlg
  include AutoAccessor
  include CreateControlHelper
  include ImageProcessingControlsCreation
  include RenamingControlsCreation 
  include OperationsControlsCreation
  include ImageProcessingControlsLayout

  SOURCE_RAW_LABEL = "Use the RAW"
  SOURCE_JPEG_LABEL = "Use the JPEG"

  def initialize(pm_api_bridge)
    @bridge = pm_api_bridge
  end

  def metadata_safe?
    false # default is to assume metadata is not safe!
  end

  def metadata_warning_text
    "WARNING: #{TEMPLATE_DISPLAY_NAME} removes all EXIF and IPTC data from uploaded images. If you'd like to retain credit, we recommend considering a watermark when sharing images on social media."
  end

  def ip_warning?
    false # default is to assume that you do not implicitly give away ip rights
  end

  def ip_warning_text
    # Text to provide as warning when ip_warning is true
    "WARNING: You grant #{TEMPLATE_DISPLAY_NAME} a non-exclusive, transferable, sub-licensable, royalty-free, worldwide license to use any IP content that you post on or in connection with #{TEMPLATE_DISPLAY_NAME}."
  end

  def enable_rename?
    false # default is to not enable upload file renaming
  end

  def send_original_default?
    false # default is to upload files converted to JPG
  end

  def valid_file_types
    # List of supported file types (JPEG, PNG, TIFF, GIF, WAV) for uploading.
    # An empty list means all files types are supported.
    [ "JPEG" ] # Default is that only jpeg files are supported
  end

  def initial_control
    # Set to the control that should get initial focus
    nil
  end

  def create_controls(dlg)
    create_control(:dest_account_group_box,    GroupBox,    dlg, :label=>"Destination #{TEMPLATE_DISPLAY_NAME} Account:")
    create_control(:dest_account_static,       Static,      dlg, :label=>"Account:")
    create_control(:dest_account_combo,        ComboBox,    dlg, :sorted=>true, :persist=>false)
  end

  def create_processing_controls(dlg)
    create_control(:transmit_group_box,        GroupBox,    dlg, :label=>"Transmit:")
    create_control(:send_original_radio,       RadioButton, dlg, :label=>"Original Photos", :checked=>send_original_default?)
    create_control(:send_jpeg_radio,           RadioButton, dlg, :label=>"Saved as JPEG", :checked=>!send_original_default?)
    RadioButton.set_exclusion_group(@send_original_radio, @send_jpeg_radio)
    create_control(:send_desc_edit,            EditControl, dlg, :value=>"Note: #{TEMPLATE_DISPLAY_NAME}'s supported image format#{valid_file_types.length > 1 ? 's are:' : ' is only:'} #{valid_file_types.join(', ').sub(/, (?!.*,)/, valid_file_types.length > 2 ? ', and ' : ' and ')}. All other image formats are automatically converted to JPEG.", :multiline=>true, :readonly=>true, :persist=>false)
    create_jpeg_controls(dlg)
    create_image_processing_controls(dlg)
    create_control(:ip_warning_edit,           EditControl, dlg, :value=>ip_warning_text, :multiline=>true, :readonly=>true, :persist=>false)
    create_control(:metadata_warning_edit,     EditControl, dlg, :value=>metadata_warning_text, :multiline=>true, :readonly=>true, :persist=>false)
    create_operations_controls(dlg)
  end

  def layout_controls(container)
    sh, eh = 20, 24

    container.inset(15, 5, -15, -5)
    container.layout_with_contents(@dest_account_group_box, 0, 0, -1, -1) do |c|
      c.set_prev_right_pad(5).inset(10,20,-10,-5).mark_base

      c << @dest_account_static.layout(0, c.base+3, 80, sh)
      c << @dest_account_combo.layout(c.prev_right, c.base, 193, eh)

      c.pad_down(5).mark_base
      c.mark_base.size_to_base
    end

    container.pad_down(5).mark_base
  end

  def layout_processing_controls(container)      
    sh, eh = 20, 24

    container.layout_with_contents(@transmit_group_box, 0, container.base, "50%-5", -1) do |c|
      c.set_prev_right_pad(5).inset(10,20,-10,-5).mark_base

      c << @send_original_radio.layout(0, c.base, 120, eh)
      c << @send_jpeg_radio.layout(0, c.base+eh+5, 120, eh)
      c << @send_desc_edit.layout(c.prev_right+5, c.base, -1, 2*eh) if !valid_file_types.empty?
      c.pad_down(5).mark_base

      layout_jpeg_controls(c, eh, sh)

      c.layout_with_contents(@imgproc_group_box, 0, c.base, -1, -1) do |cc|
        cc.set_prev_right_pad(5).inset(10,20,-10,-5).mark_base

        layout_image_processing_controls(cc, eh, sh, 80, 200, 120)

        cc.pad_down(5).mark_base
        cc.mark_base.size_to_base
      end

      c.pad_down(5).mark_base
      c.mark_base.size_to_base
    end

    container.layout_with_contents(@operations_group_box, "50%+5", container.base, -1, -1) do |c|
      c.set_prev_right_pad(5).inset(10,20,-10,-5).mark_base

      if ip_warning?
        c << @ip_warning_edit.layout(0, c.base, -1, 2*eh)
        c.pad_down(5).mark_base
      end

      if metadata_safe?
        c << @apply_iptc_check.layout(0, c.base, "50%-5", eh)
        c << @stationery_pad_btn.layout("-50%+5", c.base, -1, eh)
        c.pad_down(5).mark_base
        c << @preserve_exif_check.layout(0, c.base, -1, eh)
      else
        c << @metadata_warning_edit.layout(0, c.base, -1, 2*eh)
      end
      c.pad_down(5).mark_base

      if enable_rename?
        c << @rename_as_check.layout(0, c.base, 100, eh)
        c.pad_down(5).mark_base
        c << @rename_string_edit.layout(0, c.base, -100, eh)
        c << @use_seqn_check.layout(-90, c.base, -1, eh)
        c.pad_down(5).mark_base
        c << @seqn_static.layout(10, c.base+3, "50%-5", sh)
        c << @set_seqn_btn.layout("-50%+5", c.base, -1, eh)
        c.pad_down(5).mark_base
      end

      c << @save_copy_check.layout(0, c.base, -1, eh)
      c.pad_down(5).mark_base
      c << @save_copy_subdir_radio.layout(30, c.base, "50%-35", eh)
      c << @save_copy_subdir_edit.layout("50%+5", c.base, -1, eh)
      c.pad_down(5).mark_base
      c << @save_copy_userdir_radio.layout(30, c.base, "50%", eh)
      c << @save_copy_choose_userdir_btn.layout("50%+5", c.base, -1, eh)
      c.pad_down(5).mark_base
      c << @save_copy_userdir_static.layout(0, c.base, -1, 2*sh)
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
end # OAuthFileUploaderUI


class OAuthBackgroundDataFetchWorker
  def initialize(bridge, dlg)
    @bridge = bridge
    @dlg = dlg
    @client ||= OAuthClient.new(@bridge)
  end

  def do_task
    return unless @dlg.account_parameters_dirty

    @dlg.account_parameters_dirty = false
  end
end # OAuthBackgroundDataFetchWorker


class OAuthFileUploader
  include ImageProcessingControlsLogic
  include OperationsControlsLogic
  include RenamingControlsLogic
  include JpegSizeEstimationLogic
  include UpdateComboLogic
  include FormatBytesizeLogic
  include PreflightWaitAccountParametersLogic

  attr_accessor :account_parameters_dirty
  attr_reader :num_files, :ui
  attr_accessor :cur_photosets

  DLG_SETTINGS_KEY = :upload_dialog

  def self.template_display_name
    TEMPLATE_DISPLAY_NAME
  end
  
  def self.template_description
    "Upload images to #{TEMPLATE_DISPLAY_NAME}"
  end

  def self.file_uploader_ui_class
    raise "self.file_uploader_ui_class needs to be overridden in #{self.class}"
  end

  def self.conn_settings_class
    raise "self.conn_settings_class needs to be overridden in #{self.class}"
  end

  def self.upload_protocol_class
    raise "self.upload_protocol_class needs to be overridden in #{self.class}"
  end

  def self.background_data_fetch_worker_manager
    raise "self.background_data_fetch_worker_manager needs to be overridden in #{self.class}"
  end

  def initialize(pm_api_bridge, num_files, dlg_status_bridge, conn_settings_serializer)
    @bridge = pm_api_bridge
    @num_files = num_files
    @dlg_status_bridge = dlg_status_bridge
    @conn_settings_ser = conn_settings_serializer
    @last_status_txt = nil
    @account_parameters_dirty = false
    @data_fetch_worker = nil
    @cur_photosets = nil
  end

  def upload_files(global_spec, progress_dialog)
    raise "upload_files called with no @ui instantiated" unless @ui
    acct = current_account_settings
    raise "Failed to load settings for current account. Please click the Connections button." unless acct
    spec = build_upload_spec(acct, @ui)

    build_additional_upload_spec(spec, ui)

    @bridge.kickoff_template_upload(spec, self.class.upload_protocol_class)
  end

  def create_controls(dlg)
    @ui = self.class.file_uploader_ui_class.new(@bridge)
    @ui.create_controls(dlg)

    @ui.send_original_radio.on_click { adjust_controls }
    @ui.send_jpeg_radio.on_click { adjust_controls }
    @ui.dest_account_combo.on_sel_change { account_parameters_changed }

    @file_upload_dialog = dlg.parent_dlg

    add_jpeg_controls_event_hooks
    add_image_processing_controls_event_hooks
    add_operations_controls_event_hooks

    if @ui.enable_rename?
      set_seqn_static_to_current_seqn
      add_renaming_controls_event_hooks
    end

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
    @ui.initial_control.set_focus if !@initialized && @ui.initial_control
    @initialized = true
    handle_jpeg_size_estimation
  end

  def set_status_text(txt)
    if txt != @last_status_txt
      @dlg_status_bridge.set_text(txt)
      @last_status_txt = txt
    end
  end

  def disable_send_button
    @file_upload_dialog.disable_send_button
  end

  def enable_send_button
    @file_upload_dialog.enable_send_button
  end

  def reload_column_browser
    return unless @ui.folder_browser_column_browser.instantiated?
    @ui.folder_browser_column_browser.reload
  end

  def load_column_zero
    return unless @ui.folder_browser_column_browser.instantiated?
    @ui.folder_browser_column_browser.load_column_zero
  end

  def set_browser_theme
    return unless @ui.folder_browser_column_browser.instantiated?
    @ui.folder_browser_column_browser.set_ui_theme(@bridge.get_ui_theme())
  end

  def update_account_combo_list
    data = fetch_conn_settings_data
    @ui.dest_account_combo.reset_content( data.keys )
  end

  def select_active_account
    selected_settings_name = self.class.conn_settings_class.fetch_selected_settings_name(@conn_settings_ser)
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

  def preflight_settings(global_spec)
    raise "preflight_settings called with no @ui instantiated" unless @ui

    acct = current_account_settings
    raise "Failed to load settings for current account. Please click the Connections button." unless acct
    raise "Some account settings appear invalid or missing. Please click the Connections button." unless acct.appears_valid?

    preflight_jpeg_controls
    preflight_renaming_controls if @ui.enable_rename?
    preflight_wait_account_parameters_or_timeout

    build_upload_spec(acct, @ui)
  end

  def imglink_button_spec
    { :filename => "logo.tif", :bgcolor => "ffffff" }
  end

  def imglink_url
    "https://store.camerabits.com/"
  end

  protected

  def create_data_fetch_worker
    qfac = lambda { @bridge.create_queue }
    @data_fetch_worker = BackgroundDataFetchWorkerManager.new(self.class.background_data_fetch_worker_manager, qfac, [@bridge, self])
  end

  def destroy_data_fetch_worker
    if @data_fetch_worker
      @data_fetch_worker.terminate
      @data_fetch_worker = nil
    end
  end

  def adjust_controls
    adjust_image_processing_controls
    adjust_operations_controls
    adjust_renaming_controls
  end

  def convert_gps_coordinate(gpscoordinate)
    gpscoordinate = gpscoordinate.strip
    angle = nil
    if !gpscoordinate.empty?
      if !(gpscoordinate =~ /^[NESW]?[\d.+-]+[NESW]?$/).nil?
        angle = gpscoordinate.tr("NESW","").to_f
      elsif !(gpscoordinate =~ /^[NESW]?\s*([\d.+-]+[°'′"″]){1,3}(\s*[NESW])?$/).nil?
        # Coordinates can be given as numeric or as degrees, minutes, seconds
        angle = 0
        gpscoordinate.scan(/([\d.+-]+)([°'′"″])/) { |n, denominator|
          n = n.to_f
          n /= 60 if denominator != '°' # Minutes or seconds
          n /= 60 if denominator == '"' || denominator == '″' # Seconds
          angle += n
        }
      else
        dbglog "Invalid GPS coordinate specification: #{gpscoordinate}"
      end
    end
    if angle.nil?
      angle = ""
    else
      angle *= (gpscoordinate =~ /[SW]/).nil? ? 1 : -1 # Negative numbers if coordinate in S or W
    end
    "#{angle}"
  end

  def build_upload_spec(acct, ui)
    spec = AutoStruct.new

    # String displayed in upload progress dialog title bar:
    spec.upload_display_name  = "#{TEMPLATE_DISPLAY_NAME}:#{ui.dest_account_combo.get_selected_item}"
    # String used in logfile name, should have NO spaces or funky characters:
    spec.log_upload_type      = TEMPLATE_DISPLAY_NAME.tr('^A-Za-z0-9_-','')
    # Account string displayed in upload log entries:
    spec.log_upload_acct      = spec.upload_display_name

    # Token and secret
    spec.token = account.access_token
    spec.token_secret = account.access_token_secret

    spec.num_files = @num_files

    # NOTE: upload_queue_key should be unique for a given protocol,
    #       and a given upload "account".
    #       Rule of thumb: If file A requires a different
    #       login than file B, they should have different
    #       queue keys.
    spec.upload_queue_key = TEMPLATE_DISPLAY_NAME

    processing_orgs_type = "originals"
    if !ui.valid_file_types.empty?
      [ "GIF", "JPEG", "PNG", "TIFF" ].map { |t|
        processing_orgs_type += "_#{t.downcase}" if ui.valid_file_types.include?(t)
      }
      processing_orgs_type +=  "_only"
    end
    spec.upload_processing_type = ui.send_original_radio.checked? ? processing_orgs_type : "save_as_jpeg"
    spec.send_incompatible_originals_as = "JPEG"
    spec.send_wav_files = ui.valid_file_types.empty? || ui.valid_file_types.include?("WAV")
    
    build_jpeg_spec(spec, ui)
    build_image_processing_spec(spec, ui)
    build_operations_spec(spec, ui)
    if ui.enable_rename?
      build_renaming_spec(spec, ui)
    else
      spec.do_rename = false
    end

    if !@ui.metadata_safe?
      spec.apply_stationery_pad = false
      spec.preserve_exif = false
    end

    spec
  end

  def build_additional_upload_spec
    # Override in subclass to add additional data to the upload spec
  end

  def fetch_conn_settings_data
    self.class.conn_settings_class.fetch_settings_data(@conn_settings_ser)
  end

  def current_account_settings
    acct_name = @ui.dest_account_combo.get_selected_item
    data = fetch_conn_settings_data
    settings = data ? data[acct_name] : nil
  end

  def tokens_present?
    account && account.appears_valid?
  end

  def account_parameters_changed
    @account = nil
    @account_parameters_dirty = true

    account = current_account_settings
    if account.nil?
      set_status_text("Please select an account, or create one with the Connections button.")
    elsif ! account.appears_valid?
      set_status_text("Some account settings appear invalid or missing. Please click the Connections button.")
    elsif @num_files == 0
        set_status_text("No images selected!")
    else
      set_status_text("You are ready to upload your " + (@num_files > 1 ? "#{@num_files} images." : "image."))
    end
  end
end # OAuthFileUploader


class OAuthConnection
  attr_reader :api_key, :api_secret
  attr_reader :access_token, :access_token_secret
  attr_reader :base_url, :callback_url

  def create_query_string_from_hash( query_hash = {} )
    qstr = ""
    query_hash.each_pair do |key, value|
      qstr += (qstr.empty? ? "?" : "&")
      qstr += URI.escape(key.to_s) + "=" + URI.escape(value.to_s).gsub(/[&=]/) { |s| '%' + ("%02X" % s[0].to_s) }
      #dbglog "qstr= #{qstr.inspect}"
    end
    qstr
  end

  def log_server_response(method, response)
    if PM::Logging.query_logging_active_for?("HTTP_RESPONSE_LOGGING")
      dbglog "http/response: #{method.to_s.upcase} #{response.inspect}, #{response.body}"
    end
    response
  end

  def log_server_request(method, path, headers)
    if PM::Logging.query_logging_active_for?("HTTP_REQUEST_LOGGING")
      headers_s = (headers.map { |k, v| "#{k}: #{v}" }).join(", ")
      dbglog "http/request: #{method.to_s.upcase} #{path}, {#{headers_s}}"
    end
  end

  def initialize(pm_api_bridge)
    raise "@base_url needs to be defined in #{self.class}.initialize" if @base_url.nil?
    raise "@api_key needs to be defined in #{self.class}.initialize" if @api_key.nil?
    raise "@api_secret needs to be defined in #{self.class}.initialize" if @api_secret.nil?
    @callback_url ||= 'oob'
    @bridge = pm_api_bridge
    @verifier = nil
    @http = nil
  end

  def reset!
    @access_token = nil
    @access_token_secret = nil
  end

  def authenticated?
    !(@access_token.nil? || @access_token.empty? || @access_token_secret.nil? || @access_token_secret.empty?)
  end

  # TODO: handle timeout
  def ensure_open_http(host, port)
    unless @http
      @http = @bridge.open_http_connection(host, port)
      @http.use_ssl = true
      @http.open_timeout = 60
      @http.read_timeout = 180
    end
    @http
  end

  def close_http
    if @http
      @http.finish rescue nil
      @http = nil
    end
  end

  def mute_transfer_status
    @mute_transfer_status = true
  end

  def unmute_transfer_status
    @mute_transfer_status = false
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

  def get(path)
    dbglog "#{self.class.name}:#{__method__}: #{@base_url + path}"
    headers = request_headers(:get, @base_url + path, {})
    request(:get, path, "", headers)
  end

  def put(path, data = "", upload_headers = {})
    dbglog "#{self.class.name}:#{__method__}: #{@base_url + path}"
    headers = request_headers(:put, @base_url + path, {})
    headers.merge!(upload_headers)
    request(:put, path, data, headers)
  end

  def post(path, data = "", upload_headers = {}, signature_params = {})
    dbglog "#{self.class.name}:#{__method__}: #{@base_url + path}"
    headers = request_headers(:post, @base_url + path, signature_params)
    headers.merge!(upload_headers)
    request(:post, path, data, headers)
  end

  def process_server_response_hash(err)
    errors = []
    [ 'message', 'error_user_msg' ].map { |m| errors.push(err[m]) if err[m] }
    errors = errors.join(", ").strip
    errors = nil if errors.empty?
    errors
  end

  def require_server_success_response(response)
    # NOTE: Because of sandbox restrictions, the code is overly complex
    # E.g., the sandbox does not even allow you to do "#{err}" or
    #   "#{err.inspect}" when err is a hash...
    unless response.code == "200" || response.code == "201"
      begin
        result = JSON::parse(response.body)
        # Error can be in 'error' or 'errors'
        err = result['error'] || result['errors']
      rescue
        # If result not in JSON, try xml <error></error> pairs
        err = []       
        response.body.scan(/<error>((?!<\/error>).*)<\/error>/m){ | e | err.push e }
      end
      begin
        if err.kind_of?(Array)
          # Handle array of messages
          if err.length == 0
            err = nil
          else
            err = (err.map { |e|
                     if e.kind_of?(Hash)
                       process_server_response_hash(e)
                     else
                       "#{e}"
                     end
                   }).join(", ")
          end
        elsif err.kind_of?(Hash)
          err = process_server_response_hash(err)
        end
      rescue
        # In case of conversion errors above
        err = nil
      end
      # Fallback to whole body if no error found
      err ||= response.body
      err = err.strip
      err = "Communication error #{response.code}" if err.empty? # Last resort if no body
      dbglog "#{self.class.name}:#{__method__}: Server error: #{response.code} - #{err}"
      raise err
    end
  end 

  def set_tokens(token, token_secret)
    @access_token = token
    @access_token_secret = token_secret
  end

  def set_tokens_from_post(path, verifier=nil)
    @verifier = verifier
    response = post(path)
    require_server_success_response(response)
    result = CGI::parse(response.body)
    set_tokens(result['oauth_token'].join, result['oauth_token_secret'].join)
    raise "Unable to verify code" unless !@verifier.nil? || authenticated?
    result
  end

  def set_tokens_from_settings(settings = {})
    set_tokens(settings[:token], settings[:token_secret])
  end

  protected

  def credentials
    {
      :consumer_key    => @api_key,
      :consumer_secret => @api_secret,
      :token           => @access_token,
      :token_secret    => @access_token_secret,
      :verifier        => @verifier,
      :callback        => @callback_url
    }
  end

  def request_headers(method, url, signature_params)
    {'Authorization' => auth_header(method, url, signature_params)}
  end

  def auth_header(method, url, signature_params)
    oauth_auth_header(method, url, signature_params).to_s
  end

  def oauth_auth_header(method, uri, signature_params)
    uri = URI.parse(uri)
    SimpleOAuth::Header.new(method, uri, signature_params, credentials)
  end

  def request(method, path, data, headers = {})
    url = @base_url + path
    uri = URI.parse(url)
    ensure_open_http(uri.host, uri.port)
    log_server_request(method, path, headers)
    if method == :get
      log_server_response(method, @http.send(str_to_sym(method), uri.request_uri, headers))
    else
      log_server_response(method, @http.send(str_to_sym(method), uri.request_uri, data, headers))
    end
  end
end # OAuthConnection


class OAuthClient
  attr_reader :name

  def connection
    raise "connection needs to be defined in class #{self.class}"
  end

  def authorization_url
    if smugmug_api?
      qstr = connection.create_query_string_from_hash( # https://api.smugmug.com/api/v2/doc/tutorial/authorization.html
      { "Access"      => "Full",
        "Permissions" => "Modify",
        "oauth_token" => connection.access_token
      })
      url = "#{connection.base_url}oauth/1.0a/authorize#{qstr}"
    else
      url = "#{connection.base_url}oauth/authorize?oauth_token=#{connection.access_token}"
    end

    url
  end

  def initialize(bridge, options = {})
    @bridge = bridge
  end

  def access_token
    connection.access_token
  end

  def access_token_secret
    connection.access_token_secret
  end

  def reset!
    connection.reset!
    @name = nil
  end

  def fetch_request_token
    if smugmug_api?
      connection.set_tokens_from_post('oauth/1.0a/getRequestToken')
    else
      connection.set_tokens_from_post('oauth/request_token')
    end
  end

  def launch_application_authorization_in_browser
    fetch_request_token unless connection.access_token
    @bridge.launch_url(authorization_url)
  end

  def get_access_token(verifier)
    if smugmug_api?
      result = connection.set_tokens_from_post('oauth/1.0a/getAccessToken', verifier)
    else
      result = connection.set_tokens_from_post('oauth/access_token', verifier)
    end
    @name = get_account_name(result)
    [ connection.access_token, connection.access_token_secret, @name ]
  end

  def get_account_name(result)
    raise "get_account_name needs to be defined in class #{self.class}"
  end

  def authenticate_from_settings(settings = {})
    connection.set_tokens_from_settings(settings)
    @name = settings[:name]
  end

  def update_ui
    @dialog.reset_active_account
  end

  def store_settings_data(token, token_secret, name)
    connection.set_tokens(token, token_secret)
    @name = name
  end

  def smugmug_api?
    false
  end
end # OAuthClient


class OAuth2Client < OAuthClient
  def fetch_request_token
    # Empty step for OAuth2!
  end

  def get_access_token(verifier)
    result = connection.set_tokens_from_post('oauth2/token', verifier)
    @name = get_account_name(result)
    [ connection.access_token, connection.access_token_secret, @name ]
  end
end # OAuth2Client


class OAuth2Connection < OAuthConnection

  protected
  
  def oauth_auth_header(method, uri, params = {})
    if !authenticated?
      auth = 'Basic ' + [@api_key + ':' + @api_secret].pack('m').chomp("\n")
    else
      auth = 'Bearer ' + @access_token
    end
    auth
  end
end # OAuth2Connection


class OAuthUploadProtocol
  def connection
    raise "connection needs to be defined in class #{self.class}"
  end

  def initialize(pm_api_bridge, options = {:connection_settings_serializer => nil, :dialog => nil})
    @bridge = pm_api_bridge
    @shared = @bridge.shared_data
    @dialog = options[:dialog]
    @connection_settings_serializer = options[:connection_settings_serializer]
    connection.mute_transfer_status
  end

  def reset_transfer_status
    defined?(connection_image_upload) ? connection_image_upload.reset_transfer_status : connection.reset_transfer_status
  end

  # return [bytes_to_write, bytes_written]
  def poll_transfer_status
    defined?(connection_image_upload) ? connection_image_upload.poll_transfer_status : connection.poll_transfer_status
  end

  def abort_transfer
    defined?(connection_image_upload) ? connection_image_upload.abort_transfer : connection.abort_transfer
  end

  def reset!
    defined?(connection_image_upload) ? connection_image_upload.reset! : connection.reset!
  end

  def image_upload(local_filepath, remote_filename, is_retry, spec)
    @bridge.set_status_message "Uploading via secure connection..."

    if defined?(api)
      connection.set_tokens(api.connection.access_token, api.connection.access_token_secret)
      connection_image_upload.set_tokens(api.connection.access_token, api.connection.access_token_secret) if defined?(connection_image_upload)
    else
      connection.set_tokens(spec.token, spec.token_secret)
      connection_image_upload.set_tokens(spec.token, spec.token_secret) if defined?(connection_image_upload)
    end

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

  def upload(fname, remote_filename, spec)
    raise "upload needs to be defined in class #{self.class}"
  end

  def authenticate_from_settings(settings = {})
    connection.set_tokens_from_settings(settings)
  end
end # OAuthUploadProtocol

