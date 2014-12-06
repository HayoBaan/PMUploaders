
FileSkippedException = RuntimeError.new("***SKIPPED***")

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
    create_control(:apply_iptc_check,           CheckBox,       dlg, :label=>"Apply IPTC stationery")
    create_control(:stationery_pad_btn,         StationeryPadButton, dlg, :label=>"IPTC Stationery Pad...")
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
      c << @apply_iptc_check.layout(0, c.base, 170, eh)
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
      acct = current_account_settings
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
        dbglog "BackgroundDataFetchWorkerManager::run_worker_task: caught exception: #{ex.message}\n#{ex.backtrace_to_s(4)}"
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


