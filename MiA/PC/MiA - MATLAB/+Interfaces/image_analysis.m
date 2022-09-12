classdef image_analysis < handle
%IMAGE_ANALYSIS Primary MATLAB class file
%      IMAGE_ANALYSIS creates a new IMAGE_ANALYSIS instance or raises the 
%      existing GUI singleton.
% 
%      This IMAGE_ANALYSIS program was designed for analyzing regions of
%      interest (ROIs) in epiflourescence microscopy .CZI and .tiff images. 
%      It is capable of loading any number of .CZI channels or separate 
%      grayscale .tiff images as well as regular RGB .tiff images.
% 
%      Several interactive tools are available within the program to assist
%      in ROI definition; please refer to program help documentation for a
%      full tutorial.
%
%      ROI data can currently be exported in .CSV, .txt, or .xslx formats.
% 
%      H = IMAGE_ANALYSIS returns the handle to a new IMAGE_ANALYSIS or the 
%      handle to the existing singleton.

% Last Modified by JONATHAN HOOD v3.0 Sep-2022


% MiA Interfaces package holding all created interfaces of the MiA class,
% including the primary interface image_analysis.m.
%     Copyright (C) 2022 California Polytechnic State University San Luis
%     Obispo:
%     -Jonathan Hood
%     -Alexis Pasulka
% 
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <https://www.gnu.org/licenses/>.
%     
%     With questions regarding this program, please contact Dr. Alexis
%     Pasulka electronically at apasulka@calpoly.edu or send a letter to:
%           Cal Poly San Luis Obispo
%           1 Grande Ave.
%           Biological Sciences Department
%           San Luis Obispo, CA 93407

    properties(Access = public)
        % Class constants
        CONSTANTS = Constants.Graphics();   % handle to graphics constants values
        
        % Class GUI objects
        blank_fig = [];                     % handle to blank_figure class
        status_bar = [];                    % handle to blank_figure's status_bar class
        fig_handle = [];                    % handle to Matlab Figure of blank_figure class
        panel_handle = [];                  % handle to uipanel; holds all children graphic objects
        
        % Class inset panels
        file_panel = [];                    % handle to uipanel for file and output directory selection
        image_panel = [];                   % handle to uipanel for image axes
        roi_panel = [];                     % handle to uipanel for ROI statistics
        channel_panel = [];                 % handle to uipanel for image channel options
        channel_tab_grp = [];               % handle to uitabgroup inset in channel_panel for channel editing options
        contrast_tab = [];                  % handle to uitab for contrast editing inset in channel_tab_group
        channel_prop_tab = [];              % handle to uitab for channel properties editing inset in channel_tab_group
        image_prop_tab = [];                % handle to uitab for image properties editing inset in channel_tab_group
        
        % Class menu options
        roi_menu = [];                      % handle to ROI uimenu; holds all ROI uimenu tools
        file_menu = [];                     % handle to 'File' uimenu; holds general program options such as 'Save' and 'Exit'
        display_menu = [];                  % handle to 'Display' uimenu; holds 'Zoom' and 'Default View' image options
        help_menu = [];                     % handle to 'Menu' uimenu; holds 'Manual' and 'Licensing' options
        connectivity = 4;                   % holds selected value for ROI connectivity; default is 4
        export_type = 'Excel';              % holds selected value for ROI data export data type; default is 'Excel'
        
        % Class inset panel children
        image_fp = [];                      % holds filepath of loaded image
        image_name = [];                    % holds name of loaded image
        output_dir = [];                    % holds output directory character string
        analysis_tool = [];                 % handle to instance-specific Interfaces.analyze class object
        channel_tool = [];                  % handle to instance-specific Interfaces.channel class object
        roi_stats_tool = [];                % handle to instance-specific Interfaces.roi_stats class object
        roi_disp_txt = [];                  % handle to ROI display text object
        
        % Save Options
        mask_save_name = [];                % holds user input name for save ROI binary mask file; default is value of 'image_fp'
        dont_ask_again_mask = 0;            % indicates whether the user has chosen 'Don't ask me again' after first 'Save ROI Mask' save
        overwrite_mask = 0;                 % indicates whether the user wishes to overwrite an existing ROI mask
        dont_ask_again_images = 0;          % indicates whether the user has chosen 'Don't ask me again' after first  'Save Images' save
        overwrite_images = 0;               % indicates whether the user wishes to overwrite existing images
        dont_ask_again_data = 0;            % indicates whether the user has chosen 'Don't ask me again' after first 'Save ROI Data' save
        overwrite_data = 0;                 % indicates whether the user wishes to overwrite existing ROI data
        dont_ask_again_snapshot = 0;        % indicates whether the user has chosen 'Don't ask me again' after first 'Save Outlined Cells Image' save
        overwrite_snapshot = 0;             % indicates whether the user wishes to overwrite an existing ROI outlined cells image
        dont_ask_again_ids = 0;             % indicates whether the user has chosen 'Don't ask me again' after first 'Save Outlined Cells Image' save
        overwrite_ids = 0;                  % indicates whether the user wishes to overwrite an existing ROI outlined cells image
        dont_ask_again_load_ids = 0;        % indicates whether the user has chosen 'Don't ask me again' for ROI ID overwriting after first 'Load Mask' save
        overwrite_load_ids = 0;             % indicates whether the user wishes to overwrite existing ROI IDs from loaded mask
        previous_filepath = [];             % holds previous opened folder, if any
        last_color_order = [1 2 3];         % numeric array describing order of channels; 1 = R, 2 = G, B = 3. Default is 1 2 3
        load_mask_filepath = [];            % string filepath to mask loading directory; default is input image filepath. Changes only when new image is loaded from different input directory
        
        % ROI identification properties
        roi_id = [];                        % holds list of ROI IDs for session duration
        roi_id_next_default = 1;            % boolean denoting whether 'Next ROI Default' or 'Last Used' was last selected on close
        roi_id_next_default_val = 1;        % index indicating for 'Next ROI Default' which existing ROI type to use
        
        Tag = 'Image Analysis';             % class identifier
    end
    
    properties(Access = private)
       orig_file_filters =  {'*.czi;*.CZI;','CZI Files (*.czi,*.CZI)';...                   % default file filter set
              '*.tif;*.tiff;*.TIF;*.TIFF;','RGB Files (*.tif,*.tiff,*.TIF,*.TIFF)';...
              '*.tif;*.tiff;*.TIF;*.TIFF;','Grayscale Files (*.tif,*.tiff,*.TIF,*.TIFF)'};
       prev_filt_indx = 1;                                                                  % previous file extension index. Default is 1
    end
    
    events
        SelectionMade       % SelectionMade event, indicating an image(s) has been selected
        Status_Update       % Status_Update event, indicating an event has occurred significant enough to display to the user
        ChannelChanged      % ChannelChanged event, indicating a channel's contrast has been changed, or a channel has been disabled/enabled.
        ChannelsSelected    % ChannelsSelected event, indicating the user has finished selecting the color channels for a CZI or grayscale image.
        ROIDefined          % ROIDefined event, indicating an ROI has been defined by any of the ROI-related functions
        AreaFilter          % AreaFilter event, indicating the user has changed the min/max ROI area
    end    

    methods
        function obj = image_analysis()
        %IMAGE_ANALYSIS Construct a new instance of image_analysis or raise
        % an existing GUI.
        %   This class instantiates a new Image Analysis figure and
        %   object, unless a GUI for said object already exists. In that
        %   case, it raises the existing GUI.
        
            clear ans
            temp = findobj('Tag','Image Analysis Figure');
            if isempty(temp)
                obj.blank_fig = Figure.blank_figure(1);
                obj.fig_handle = obj.blank_fig.fig_handle;
                obj.fig_handle.Tag = 'Image Analysis Figure';
                obj.panel_handle = obj.blank_fig.panel_handle;
                obj.status_bar = obj.blank_fig.status_bar;
                obj.buildFcn();
            else
                figure(temp);
            end
        end
        
        function buildFcn(obj)
            %BUILDFCN Build the Image Analysis GUI.
            %   This function takes an input object and builds the basic
            %   image analysis GUI into the object's figure handle.
            
            % Overall figure constant spacing
            X = obj.CONSTANTS.X;
            Y = obj.CONSTANTS.Y;
            width = obj.CONSTANTS.OBJ_WIDTH;
            height = obj.CONSTANTS.OBJ_HEIGHT;
            file_selection_height = 0.35;
            im_disp_title_fontsize = 0.02;
            stat_chan_title_fontsize = 0.015;
            % Extract blank figure handle and set figure name
            fh = obj.fig_handle;
            fh.CloseRequestFcn = @(~,~)obj.closefig();
            fh.Name = 'Image Analysis Tool';
            
            fp = obj.panel_handle;
            
            %%%%%%%%%%%%%%%%
            % MENU TOOLBAR %
            %%%%%%%%%%%%%%%%
            
                % File menu item
            obj.file_menu = uimenu(fh,'Text','File','UserData',0);
                    % File submenu items
            file_load_image = uimenu(obj.file_menu,'Text','Load Image(s)','Callback',...
                @(src,~)obj.load_image(src)); %#ok<*NASGU>
            file_save_all = uimenu(obj.file_menu,'Text',...
                'Save ROI Data & Masks','Separator','on','Callback',...
                @(~,~)obj.save_all(),'Enable','off');
            file_save_image = uimenu(obj.file_menu,'Text','Save Images',...
                'Enable','off','UserData',[0 0],'Callback',@(~,~)obj.save_images());
            file_save_options = uimenu(obj.file_menu,'Text','Save Options',...
                'Enable','off','UserData',0,'Tag','Save_Options');
            % Save options submenu items
            file_save_data = uimenu(file_save_options,'Text','Save ROI Data Only',...
                'Enable','on','UserData',0,'Callback',@(~,~)obj.save_roi_data());
            file_save_mask = uimenu(file_save_options,'Text','Save ROI Mask Only',...
                'Enable','on','UserData',0,'Callback',@(~,~)obj.save_roi_mask());
            file_save_snap = uimenu(file_save_options,'Text','Save Outlined Cells Image Only',...
                'Enable','on','UserData',0,'Callback',@(src,~)obj.save_snapshot(src),...
                'Tag','Save_Outlined');
            file_save_ids = uimenu(file_save_options,'Text','Save ROI IDs Only',...
                'Enable','off','UserData',0,'Callback',@(~,~)obj.save_ids(),...
                'Tag','Save_IDs');
            
            file_undo = uimenu(obj.file_menu,'Text','Undo ROI','Enable','off',...
                'Separator','On','Accelerator','U','Callback',...
                @(~,~)obj.analysis_tool.undo_roi(),'Tag','UndoROI');
            file_redo = uimenu(obj.file_menu,'Text','Redo ROI','Enable','off',...
                'Callback',...
                @(~,~)obj.analysis_tool.redo_roi(),'Tag','RedoROI');
            file_export_data = uimenu(obj.file_menu,'Text','Export ROI Data As...',...
                'Enable','off','Separator','On','Tag','Export_Options');
            
                % Export Data submenu items
            file_export_csv = uimenu(file_export_data,'Text','CSV (.csv)',...
                'Tag','CSV','Callback',@(src,~)obj.export_changed(src));
            file_export_txt = uimenu(file_export_data,'Text','Text (.txt)',...
                'Tag','Text','Callback',@(src,~)obj.export_changed(src));
            file_export_excel = uimenu(file_export_data,'Text','Excel (.xlsx)',...
                'Tag','Excel','Checked','on','Callback',@(src,~)obj.export_changed(src));
            file_exit = uimenu(obj.file_menu,'Text','Exit','Separator','on',...
                'Callback',@(~,~)obj.closefig());
            
                % ROI menu item
            obj.roi_menu = uimenu(fh,'Text','ROI Tools','Enable','off',...
                'Tag','ROI Menu');
                    % ROI submenu items
            roi_threshold_options = uimenu(obj.roi_menu,'Text','Threshold Channel',...
                'Tag','threshold','Enable','Off');
            roi_connectivity = uimenu(obj.roi_menu,'Text','Connectivity',...
                'Tag','connect','Enable','Off');
            roi_bckgrnd_sub = uimenu(obj.roi_menu,'Text','Background Subtraction',...
                'Tag','BS','Enable','Off','Callback',@(~,~)obj.open_BS());
                    % ROI connectivity submenu options 4 or 8
            roi_connectivity_4 = uimenu(roi_connectivity,'Text','4',...
                'Tag','connect_four','Enable','On','Checked','On','Callback',...
                @(src,~)obj.connect_changed(src));
            roi_connectivity_8 = uimenu(roi_connectivity,'Text','8',...
                'Tag','connect_eight','Enable','On','Callback',...
                @(src,~)obj.connect_changed(src));                   
                    % ROI Threshold Channel submenu
            roi_threshold_all = uimenu(roi_threshold_options,'Text','All','Checked','on',...
                'Callback',@(src,~)obj.set_threshold(src));
            roi_threshold_red = uimenu(roi_threshold_options,'Text','Red',...
                'Callback',@(src,~)obj.set_threshold(src));
            roi_threshold_green = uimenu(roi_threshold_options,'Text','Green',...
                'Callback',@(src,~)obj.set_threshold(src));
            roi_threshold_blue = uimenu(roi_threshold_options,'Text','Blue',...
                'Callback',@(src,~)obj.set_threshold(src));
            roi_auto_threshold = uimenu(obj.roi_menu,'Text','Automatic Threshold a ROI',...
                'Callback',@(src,~)obj.analysis_tool.auto_threshold(src),...
                'Enable','Off','Accelerator','A','Separator','on','Tag','single');
            roi_manual_threshold = uimenu(obj.roi_menu,'Text','Manual Threshold a ROI',...
                'Callback',@(src,~)obj.analysis_tool.initialize_manual_threshold(src),...
                'Tag','single','Enable','Off','Accelerator','W');
            roi_auto_multi_threshold = uimenu(obj.roi_menu,'Text',...
                'Auto Threshold a Region of ROIs','Separator','on',...
                'Tag','multi','Callback',@(src,~)obj.analysis_tool.auto_threshold(src),...
                'Enable','Off');
            roi_manual_multi_threshold = uimenu(obj.roi_menu,'Text',...
                'Manual Threshold a Region of ROIs',...
                'Tag','multi','Callback',@(src,~)obj.analysis_tool.initialize_manual_threshold(src),...
                'Enable','Off','Accelerator','R');
            roi_manual_threshold_all = uimenu(obj.roi_menu,'Text','Manual Threshold All ROIs',...
                'Callback',@(src,~)obj.analysis_tool.initialize_manual_threshold(src),...
                'Tag','all','Enable','Off');
            roi_draw_ellipse = uimenu(obj.roi_menu,'Text','Draw Ellipse ROI',...
                'Separator','on','Callback',@(~,~)obj.analysis_tool.draw_ellipse(),...
                'Enable','Off','Accelerator','E');
            roi_draw_freehand = uimenu(obj.roi_menu,'Text','Draw Freehand ROI',...
                'Callback',@(~,~)obj.analysis_tool.draw_freehand(),'Enable','Off',...
                'Accelerator','F');
            roi_split = uimenu(obj.roi_menu,'Text','Split ROI','Enable','Off',...
                'Callback',@(~,~)obj.analysis_tool.split_roi(),'Accelerator','X');
            roi_delete_one_roi = uimenu(obj.roi_menu,'Text','Delete ROI',...
                'Separator','on','Enable','Off','Callback',@(src,~)obj.analysis_tool.delete_roi(src),...
                'Tag','single','Accelerator','D');
            roi_delete_region_roi = uimenu(obj.roi_menu,'Text',...
                'Delete Region of ROIs','Enable','Off','Callback',@(src,~)obj.analysis_tool.delete_roi(src),...
                'Tag','multiple','Accelerator','G');
            roi_delete_all_rois = uimenu(obj.roi_menu,'Text','Delete All ROIs',...
                'Enable','Off','Callback',@(src,~)obj.analysis_tool.delete_roi(src),...
                'Tag','all');
            roi_load_mask = uimenu(obj.roi_menu,'Text','Load Mask (*.mat file)','Separator','on',...
                'Callback',@(src,~)obj.load_mask(src),'Tag','Save','Enable','Off');
            roi_load_autosaved_mask = uimenu(obj.roi_menu,'Text','Load Autosaved Mask (*.mat file)',...
                'Callback',@(src,~)obj.load_mask(src),'Tag','Autosave','Enable','Off');
            roi_identification = uimenu(obj.roi_menu,'Text','Identify ROIs',...
                'Tag','identify','Enable','Off','Separator','on');
                % ROI Identification Submenu Items
            roi_identification_from_one = uimenu(roi_identification,'Text','From Start',...
                'Tag','from_one','Callback',@(src,~)obj.open_ROI_ID(src));
            roi_identification_from_selection = uimenu(roi_identification,'Text','From Selection',...
                'Tag','from_sel','Callback',@(src,~)obj.open_ROI_ID(src));
            roi_clear = uimenu(obj.roi_menu,'Text','Clear All ROI IDs',...
                'Tag','identify_clear','Enable','Off','Callback',...
                @(src,~)obj.clear_IDs(src));
                % Display menu item
            obj.display_menu = uimenu(fh,'Text','Display','Enable','Off',...
                'Tag','Display Menu');
                    % Display submenu items
            display_zoom = uimenu(obj.display_menu,'Text','Zoom','Callback',...
                @(src,~)obj.analysis_tool.enable_zoom(src),'Accelerator','Z',...
                'Tag','Zoom Menu','Enable','Off');
            display_reset = uimenu(obj.display_menu,'Text','Default View',...
                'Enable','Off','Callback',@(~,~)obj.analysis_tool.reset_zoom());
            reset_contrast = uimenu(obj.display_menu,'Text','Reset Channel Color Contrasts',...
                'Enable','Off','Callback',@(~,~)obj.channel_tool.reset_contrasts());
            disp_roi_ids = uimenu(obj.display_menu,'Text','Display ROIs Numerically',...
                'Enable','Off','Callback',@(src,~)obj.display_ROIs_ids(src),'Tag','disp_ids');
            hover_roi_ids = uimenu(obj.display_menu,'Text','Enable Hover ROI ID Display',...
                'Enable','Off','Callback',@(src,~)obj.hover_display_ROIs_ids(src),'Tag',...
                'hover_disp_ids');
                % Help menu item 
            obj.help_menu = uimenu(fh,'Text','Help','UserData',0);
                    % Help submenu items
            help_manual = uimenu(obj.help_menu,'Text','Manual','Callback',...
                @(src,~)obj.load_manual(src)); %#ok<*NASGU>
            help_licensing = uimenu(obj.help_menu,'Text',...
                'Licensing','Separator','on','Callback',...
                @(src,~)obj.load_licensing(src));
            
            %%%%%%%%%%%%%%%%%%%%%
            % INITIALIZE PANELS %
            %%%%%%%%%%%%%%%%%%%%%
            
            channel_panel_width = 0.26;
            file_image_panel_width = 0.6;
            roi_panel_width = 1-channel_panel_width-file_image_panel_width;
            
            file_height = 0.15;
            
            % Create ROI panel (left-hand frame)
            obj.roi_panel = uipanel(fp,'Units','normalized',...
                'Position',[0 0 roi_panel_width 1],'Title','ROI Statistics','FontUnits','normalized',...
                'FontSize',stat_chan_title_fontsize);
            
            newX = obj.roi_panel.Position(1) + obj.roi_panel.Position(3);
            
            % Create file selection panel (bottom frame)
            obj.file_panel = uipanel(fp,'Units','normalized',...
                'Position',[newX 0 file_image_panel_width file_height]);
            
            % Create image display panel
            newY = obj.file_panel.Position(2) + obj.file_panel.Position(4);
            obj.image_panel = uipanel(fp,'Units','normalized',...
                'Position',[newX newY file_image_panel_width 1-file_height],...
                'Title','Image Display','FontUnits','normalized',...
                'FontSize',im_disp_title_fontsize);
            
            % Instantiate floating text object for 'hover ids' to avoid
            % error in mouse move callback
            obj.roi_disp_txt = text('Visible','off');   
            
            % Create channel editing panel
            newX = obj.image_panel.Position(1) + obj.image_panel.Position(3);
            obj.channel_panel = uipanel(fp,'Units','normalized',...
                'Position',[newX 0 channel_panel_width 1],'Title','Image Options','FontUnits','normalized',...
                'FontSize',stat_chan_title_fontsize);
            obj.channel_tab_grp = uitabgroup(obj.channel_panel,'Units','normalized','Position',[0 0 1 1]);
            obj.contrast_tab = uitab(obj.channel_tab_grp,'Title','Displayed Properties');
            obj.channel_prop_tab = uitab(obj.channel_tab_grp,'Title','Channel Properties');
            obj.image_prop_tab = uitab(obj.channel_tab_grp,'Title','Image Properties');
            
            %%Display for output directory%%
            output_dir_edit_string = 'Select Output Directory...';
            output_dir_browse_title = 'Select Output Directory';
            
            obj.output_dir = Figure.file_select_display(obj.file_panel,1); % create a
            % file_select_display object; '1' indicates selecting a directory rather than a file
            
            obj.output_dir.editString = output_dir_edit_string;
            obj.output_dir.browseTitle = output_dir_browse_title;
            
            obj.output_dir.Position = [X 2*Y width file_selection_height];
            
            newX = X;
            newY = 1- (obj.output_dir.Position(2) + obj.output_dir.Position(4));
            
            %%Display for chosen image file path%%
            
            % Set image selection parameters
            image_selection_file_title = 'Select a CZI, RGB, or grayscale image';
            
            image_selection_file_multi = 'On';
                        
            obj.image_fp = Figure.file_select_display(obj.file_panel);
            obj.image_fp.browseFilter = obj.orig_file_filters;
            obj.image_fp.browseTitle = image_selection_file_title;
            obj.image_fp.browseMulti = image_selection_file_multi;
            obj.image_fp.Position = [newX newY width file_selection_height];
                    
            % Create image and ROI statistics panel
            obj.channel_tool = Interfaces.channel(obj.channel_tab_grp);
            obj.roi_stats_tool = Interfaces.roi_stats(obj);
            
            % Bind listeners to file and output selection to enable
            % analysis
            addlistener(obj.image_fp,'SelectionMade',@(src,evnt)obj.load_image(src));
            addlistener(obj.channel_tool,'ChannelsSelected',@(~,evnt)obj.channel_tool.enable_all(evnt));
            
            addlistener(obj.channel_tool,'Status_Update',@(~,evnt)obj.status_bar.update_status(evnt));
            addlistener(obj.roi_stats_tool,'Status_Update',@(~,evnt)obj.status_bar.update_status(evnt));
            addlistener(obj.image_fp,'Status_Update',@(~,evnt)obj.status_bar.update_status(evnt));
            addlistener(obj.output_dir,'Status_Update',@(~,evnt)obj.status_bar.update_status(evnt));
            addlistener(obj,'Status_Update',@(~,evnt)obj.status_bar.update_status(evnt));
            
            % Resize figure after child construction so that children
            % resize automatically
            fh.Position = obj.CONSTANTS.FIG_POS_FULL;
            obj.status_bar.update_status(Events.ActionData('Ready to Load Image'));
            obj.fig_handle.WindowButtonMotionFcn = @(~,~)obj.mouse_move();
            obj.fig_handle.WindowButtonDownFcn = @(~,~)obj.button_down();
            obj.fig_handle.WindowButtonUpFcn = @(~,~)obj.resize_panel();
        end
    end
    
    methods(Access = public)
        
       %%%%%%%%%%%%%%%%%%%%%%%%%
       % RESET MOUSE FUNCTIONS %
       %%%%%%%%%%%%%%%%%%%%%%%%%
        
       function resetMouseMoveFunction(obj)
           %RESETMOUSEMOVEFUNCTION Sets the image analysis figure mouse
           % callbacks to custom functions.
           %   This function is for use when another custom function or
           %   built-in MATLAB function changes the figure mouse
           %   callbacks. It resets all mouse functions to the custom
           %   class functions.
            
           obj.fig_handle.WindowButtonMotionFcn = @(~,~)obj.mouse_move();
           obj.fig_handle.WindowButtonDownFcn = @(~,~)obj.button_down();
           obj.fig_handle.WindowButtonUpFcn = @(~,~)obj.resize_panel();
       end
       
    end
    
    methods(Access = private)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        % FIGURE HANDLE CALLBACKS %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function obj = mouse_move(obj)
        %MOUSE_MOVE Class-specific mouse move callback function.
        %   This function sets the pointer to an arrow at all points except
        %   near panel boundaries. There it switches to left-right or
        %   up-down arrows to indicate the option of resizing panels.
            current_pos = obj.fig_handle.CurrentPoint;
            yspace = obj.panel_handle.Position(2);
            padding = 0.0015;
            X = current_pos(1);
            Y = current_pos(2);
            roi_pos = obj.roi_panel.Position(1:2);
            roi_pos(1) = roi_pos(1) + obj.roi_panel.Position(3);
            
            file_pos = obj.file_panel.Position(1:2);
            file_pos(2) = (file_pos(2) + obj.file_panel.Position(4))*(1-yspace) + yspace;
            
            image_pos = obj.image_panel.Position(1:2);
            image_pos(1) = image_pos(1) + obj.image_panel.Position(3);
            
            if X > roi_pos(1)-padding && X < roi_pos(1)+padding && Y >= roi_pos(2)
                % Movement changes all horizontally
                 obj.fig_handle.Pointer = 'left';
            elseif X > image_pos(1)-padding && X < image_pos(1)+padding && Y >= yspace
                % Movement changes all horizontally
                obj.fig_handle.Pointer = 'right';
            elseif X > roi_pos(1) && X < image_pos(1) && Y > file_pos(2)-padding && Y < file_pos(2)+padding
                % Movement changes all vertically
                obj.fig_handle.Pointer = 'top';
            elseif strcmp(obj.fig_handle.Pointer,'fleur') || strcmp(obj.fig_handle.Pointer,'custom')
            else
               obj.fig_handle.Pointer = 'arrow';
            end
            
            obj.roi_disp_txt.Visible = 'off';
            temp_hover = findobj('Tag','hover_disp_ids');
            % If hover is on
            if strcmp(temp_hover.Checked,'on')
                % Grab current position on axes and extract just x and y
                % coords
                current_pos = get(obj.analysis_tool.image_axes,'CurrentPoint');
                current_pos = floor(current_pos(1,1:2));
                x1 = current_pos(1);
                y1 = current_pos(2);
                [row,col] = size(obj.analysis_tool.image_mask_bin);
                % If on axes and on an ROI
                if ~any(current_pos<=0) && y1<=row && x1<=col && (obj.analysis_tool.image_mask_bin(y1,x1))
                    temp_master_mask = bwlabel(obj.analysis_tool.image_mask_bin,obj.connectivity);
                    id_num = temp_master_mask(round(y1),round(x1));
                    id_str = num2str(id_num);
                    if isempty(obj.roi_id)
                        obj.roi_disp_txt.String = ['ROI ID ' id_str ': Undefined'];
                    else
                        obj.roi_disp_txt.String = ['ROI ID ' id_str ': ' obj.roi_id{id_num}];
                    end
                    xlimf = obj.analysis_tool.zoom_limits{1};
                    xlimi = obj.analysis_tool.zoom_reset{1};
                    xrangef = xlimf(2)-xlimf(1);
                    xrangei = xlimi(2)-xlimi(1);
                    
                    xnorm = xrangef/xrangei;
                    
                    obj.roi_disp_txt.Position = [x1 y1-floor(35*xnorm)];
                    obj.roi_disp_txt.BackgroundColor = 'w';
                    obj.roi_disp_txt.Visible = 'on';
                end
            end
        end
        
        function obj = closefig(obj)
        %CLOSEFIG Custom close figure callback function.
        %   Closes the image analysis figure and any child manual
        %   threshold interfaces, as well as ending the logger.
           
           delete(gcf);
           temp = findobj('Tag','manual_threshold_interface');
           temp_bs = findobj('Tag','Background Subtraction Tool');
           if ~isempty(temp)
              delete(temp); 
           end
           if ~isempty(temp_bs)
              delete(temp_bs); 
           end
           % If Channel Select tool is active, close it
           temp_cs = findobj('Tag','Channel Select Tool');
           if ~isempty(temp_cs)
              delete(temp_cs);
           end
           clear ans
           diary off
        end
        
        function obj = button_down(obj)
        %BUTTON_DOWN Custom mouse click callback function.
        %   Clicking the mouse will keep the pointer an arrow or custom
        %   image unless it's a left-right or up-down arrow, indicating
        %   that the user is trying to change the size of a panel. In that
        %   case, the 'mouse move' callback is set to null to maintain the
        %   pointer.
        
           if strcmp(obj.fig_handle.Pointer,'arrow') || strcmp(obj.fig_handle.Pointer,'custom')
               return;
           end
           obj.fig_handle.WindowButtonMotionFcn = [];
        end
        
        function obj = resize_panel(obj)
        %RESIZE_PANEL Custom button-up callback function.
        %   If the pointer is an up-down or left-right arrow, resizes
        %   panels to current pointer position. Otherwise, does nothing.
            if ~strcmp(obj.fig_handle.Pointer,'left') && ...
                    ~strcmp(obj.fig_handle.Pointer,'right') && ...
                    ~strcmp(obj.fig_handle.Pointer,'top') && ...
                    ~strcmp(obj.fig_handle.Pointer,'bottom') 
               return;
            end
            
            current_pos = obj.fig_handle.CurrentPoint;
            yspace = obj.panel_handle.Position(2);
            
            X = current_pos(1);
            if X < 0
                X = 0;
            elseif X > 1
                X = 1;
            end
            Y = current_pos(2);
            if Y < yspace
                Y = yspace;
            elseif Y > 1
                Y = 1;
            end
            if strcmp(obj.fig_handle.Pointer,'left')
               % ROI panel size change
               if X > obj.channel_panel.Position(1)
                  X = obj.channel_panel.Position(1);
               end
                obj.roi_panel.Position(3) = X;
                obj.image_panel.Position(1) = X;
                obj.file_panel.Position(1) = X;
                obj.image_panel.Position(3) = 1-X-obj.channel_panel.Position(3);
                obj.file_panel.Position(3) = obj.image_panel.Position(3);
            elseif strcmp(obj.fig_handle.Pointer,'top')
               % File panel size change
               ymove = Y - yspace;
               obj.file_panel.Position(4) = ymove;
               obj.image_panel.Position(2) = ymove;
               obj.image_panel.Position(4) = 1-(ymove);
            else
               % Image panel size change
                if X < obj.roi_panel.Position(3)
                   X = obj.roi_panel.Position(3);
                end
                obj.channel_panel.Position(1) = X;
                obj.channel_panel.Position(3) = 1-X;
                xspace = 1-obj.channel_panel.Position(3)-obj.roi_panel.Position(3);
                if xspace < 0
                    xspace = 0.01;
                end
                obj.image_panel.Position(3) = xspace;
                obj.file_panel.Position(3) = obj.image_panel.Position(3);
             end
            obj.fig_handle.WindowButtonMotionFcn = @(~,~)obj.mouse_move();
        end
       
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       % FILE MENU CALLBACK FUNCTIONS %
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       
       %%%%%% LOAD IMAGE CALLBACK %%%%%%%%%%%
       function obj = load_image(obj,src)
        %LOADIMAGE Uimenu 'Load Image' callback function.
        %   Sets image filepath and save names, and notifies the object
        %   that an image has been selected, activating the 'image_fp'
        %   callback function 'enable_analysis'.
        
        imag_fp_handle = obj.image_fp;
        if ~strcmp(class(src),'Figure.file_select_display') %#ok<STISA> Compared class is custom
            [file,path,filterIndex] = uigetfile(imag_fp_handle.browseFilter,...
                    imag_fp_handle.browseTitle,obj.previous_filepath,'MultiSelect',imag_fp_handle.browseMulti);
            if ~strcmp(obj.previous_filepath,path) && ~isnumeric(path) % numeric path value indicates canceled load image
                obj.load_mask_filepath = path; % set load mask directory
            end

            if filterIndex ~= 0
                
                % Rearrange filter so selected filter index is primary on
                % next load
                logiFilter = cellfun(@(x)isequal(x,imag_fp_handle.browseFilter{filterIndex,2}),obj.orig_file_filters(:,2));
                imag_fp_handle.browseFilter(1,:) = obj.orig_file_filters(logiFilter,:);
                imag_fp_handle.browseFilter(2:end,:) = obj.orig_file_filters(~logiFilter,:);
                
                % Resort filter index to equal the indx associated with
                % original file filters
                filterIndex = find(logiFilter);
                
                if ~isempty(obj.analysis_tool)
                    cont = obj.reload_analysis();
                    if ~cont; return; end
                end
                obj.previous_filepath = path;
                % Check if multiple files were selected
                if iscell(file)
                   if filterIndex ~= 3
                    warning('Multiple image selection is not supported for non-grayscale images; please select a single image for analysis.')
                    notify(obj,'Status_Update',...
                            Events.ActionData(['Multiple image selection is ',...
                            'not supported for non-grayscale images; please select a ',...
                            'single image for analysis.']));
                    obj.load_image(src);
                    return;
                   end
                   imag_fp_handle.filepath = cell([1 length(file)]);
                   for i = 1:length(file)
                      imag_fp_handle.filepath{i} = [path file{i}]; 
                   end
                   obj.image_name = file{1};
                   imag_fp_handle.edit.String = imag_fp_handle.filepath{1}; % set file selected string to first loaded image 
                else
                   imag_fp_handle.filepath = [path file];
                   obj.image_name = file;
                   imag_fp_handle.edit.String = imag_fp_handle.filepath; 
                end
                obj.mask_save_name = obj.image_name;
                imag_fp_handle.path = path;
                imag_fp_handle.browseIndex = filterIndex;
                imag_fp_handle.selectionEventData = 1;
            else
               return; 
            end
        else
            
            % If string of filepath was edited, possible that extension is
            % not valid
            if ~any(strcmpi(imag_fp_handle.exten,{'.tif','.tiff','.czi'}))
                notify(obj,'Status_Update',Events.ActionData('Invalid file extension; image must be a .czi, .tiff, or .tif.'));
                return;
            end
            
            % If extension is valid, check for existing analysis tool and
            % reload
            if ~isempty(obj.analysis_tool)
                cont = obj.reload_analysis();
                if ~cont; return; end
            end
            
            if ~strcmp(obj.previous_filepath,imag_fp_handle.path)
                obj.load_mask_filepath = imag_fp_handle.path; % set load mask directory
            end
            obj.previous_filepath = imag_fp_handle.path;
            
            if iscell(imag_fp_handle.file_name)
               obj.image_name = imag_fp_handle.file_name{1}; 
            else
               obj.image_name = imag_fp_handle.file_name;
            end
            obj.mask_save_name = obj.image_name;
        end
        obj.enable_analysis();
       end 
       
       function obj = enable_analysis(obj)
        %ENABLE_ANALYSIS Enables all necessary GUI objects for image
        %analysis.
        %   'image_fp' SelectionMade callback. Enables all ROI and display
        %   menu tools, populates file selection fields, and creates and
        %   runs a new Interface.analyze object for image analysis.
           if obj.image_fp.selectionEventData == 1
               if obj.output_dir.selectionEventData ~= 1
                  obj.output_dir.editString = obj.image_fp.path;
                  obj.output_dir.path = obj.image_fp.path;
               end
               
               if ~isnumeric(obj.image_fp.browseIndex)
                   if strcmpi(obj.image_fp.browseIndex,'.czi')
                       obj.image_fp.browseIndex = 1;
                   else
                       obj.image_fp.browseIndex = 2;
                   end
               end
               
               obj.analysis_tool = Interfaces.analyze...   % analyze image
               (obj,obj.image_fp.filepath,obj.image_fp.browseIndex);
           
               children = obj.file_menu.Children;
               for i = 1:length(children)
                  children(i).Enable = 'on'; 
               end
               identify_menu = findobj('Tag','identify');
               identify_menu.Enable = 'off';
               obj.roi_menu.Enable = 'On';
               obj.roi_stats_tool.enable_edits('on');
               obj.display_menu.Enable = 'On';
               
               addlistener(obj.analysis_tool,'Status_Update',@(~,evnt)obj.status_bar.update_status(evnt));
               addlistener(obj.channel_tool,'ChannelChanged',@(src,~)obj.analysis_tool.update_channel(src));
               addlistener(obj.analysis_tool,'ChannelsSelected',@(~,evnt)obj.channel_tool.enable_all(evnt));
               addlistener(obj.analysis_tool,'ROIDefined',@(~,~)obj.resetMouseMoveFunction());
               addlistener(obj.analysis_tool,'ROIDefined',@(~,~)obj.roi_stats_tool.update_stats(obj.analysis_tool.image_mask_bin));
               addlistener(obj.roi_stats_tool,'AreaFilter',@(src,~)obj.analysis_tool.area_changed(src));
               
               if obj.analysis_tool.image_type == 2
                   notify(obj.channel_tool,'ChannelsSelected',Events.ActionData(obj.analysis_tool));
                   notify(obj.analysis_tool,'Status_Update',Events.ActionData('RGB Image Loaded'));
                   %^^needed due to no channel selection necessary for RGB images, which 
                   % would normally activate channel_tool's enable_all.
               end
               
               notify(obj.channel_tool,'SelectionMade',Events.ActionData(obj.analysis_tool));
           end
       end
       
       %%%%%%%%%%% SAVE ALL CALLBACK %%%%%%%%%%%%%
       function save_all(obj)
        %SAVE_ALL File menu 'Save ROI Data & Masks' callback.
        %   Saves ROI Data and current ROI mask.
           obj.save_roi_mask();
           temp = obj.save_roi_data();
           obj.save_ids();
           if temp
               notify(obj,'Status_Update',Events.ActionData('All ROI data and masks saved successfully.'))
           end
       end
       
       %%%%%%%%%%% SAVE ROI IDs CALLBACK %%%%%%%%%%%%%
       function save_ids(obj)
       %SAVE_IDS Saves all current ROI IDs to a CSV file.
           
           % Check any ROI IDs exist
           if ~isempty(obj.roi_id)
                notify(obj,'Status_Update',Events.ActionData('Saving ROI IDs to CSV file...'))
                
                % Create filepath string
                old_filepath = [obj.output_dir.path obj.mask_save_name];
                filepath = regexprep(old_filepath,'\.[a-zA-Z]+','_ROI_IDs.csv');
                if strcmp(old_filepath,filepath)
                        filepath = [filepath '_ROI_IDs.csv'];
                end

                % If file already exists, ask user whether or not to
                % overwrite.
                if isfile(filepath)
                  if ~obj.dont_ask_again_ids
                      sel = Figure.custom_questdlg('Overwrite saved ROI IDs?',{'Yes','No','Cancel'},'Overwrite Saved ROI IDs','yes');
                      obj.dont_ask_again_ids = sel.dont_ask_again_val;
                      switch sel.selection
                          case 'Yes'
                            obj.overwrite_ids = 1;
                          case 'No'
                            obj.overwrite_ids = 0;
                          otherwise
                              return;
                      end
                  end
                  if ~obj.overwrite_ids  
                      file_num = 0;
                      while isfile(filepath)
                         file_num = file_num + 1;
                         filepath = regexprep(filepath,'_ROI_IDs(\([0-9]+\))?\.csv',['_ROI_IDs(' num2str(file_num) ').csv']);
                      end
                  else
                      temp = obj.check_fopen(filepath);
                      if temp == -1
                          notify(obj,'Status_Update',Events.ActionData('ROI IDs failed to save.'))
                          obj.fig_handle.Pointer = 'arrow';
                          obj.resetMouseMoveFunction;
                          return;
                      end
                  end
                end
                counter = 1:length(obj.roi_id);
                temp_table = table(obj.roi_id',counter','VariableNames',{'roi_id','roi_num'});
                
                writetable(temp_table,filepath);
                notify(obj,'Status_Update',Events.ActionData('ROI IDs saved successfully.'))
           end
       end
       
       %%%%%%%%%%% SAVE MASK CALLBACK %%%%%%%%%%%%%
       function cont = save_roi_mask(obj)
        %SAVE_ROI_MASK File menu 'Save ROI Mask' callback.
        %   Saves only the current ROI binary mask to the value of
        %   obj.mask_save_name. Asks the user if they want to save to a
        %   different name.
           cont = 1;
           obj.fig_handle.WindowButtonMotionFcn = [];
           obj.fig_handle.WindowButtonDownFcn = [];
           obj.fig_handle.WindowButtonUpFcn = [];
           obj.fig_handle.Pointer = 'watch';
           notify(obj,'Status_Update',Events.ActionData('Saving ROI mask...'))
           pause(0.1);
           if obj.file_menu.UserData == 0
              input = obj.new_save(); 
              if strcmp(input,'Cancel') == 1
                  cont = 0;
                  obj.fig_handle.Pointer = 'arrow';
                  obj.resetMouseMoveFunction;
                  return;
              else
                  if iscell(input)
                    obj.mask_save_name = input{1};  
                  else
                    obj.mask_save_name = input;
                  end
              end
           end
           old_filepath = [obj.output_dir.path obj.mask_save_name];
           filepath = regexprep(old_filepath,'\.[a-zA-Z]+','_mask.mat');
           if strcmp(old_filepath,filepath)
               filepath = [filepath '_mask.mat'];
           end
          
           if isfile(filepath)
              if ~obj.dont_ask_again_mask
                  sel = Figure.custom_questdlg('Overwrite saved ROI mask?',{'Yes','No','Cancel'},'Overwrite Saved Mask','yes');
                  obj.dont_ask_again_mask = sel.dont_ask_again_val;
                  switch sel.selection
                      case 'Yes'
                        obj.overwrite_mask = 1;
                      case 'No'
                        obj.overwrite_mask = 0;
                      otherwise
                          cont = 0;
                          obj.fig_handle.Pointer = 'arrow';
                          obj.resetMouseMoveFunction;
                          return;
                  end
              end
              if ~obj.overwrite_mask
                    count = 0;
                    while isfile(filepath)
                        count = count + 1;
                        filepath = regexprep(filepath,'_mask(\([0-9]+\))?\.mat',['_mask(' num2str(count) ').mat']);
                    end
              else
                  temp = obj.check_fopen(filepath);
                  if temp == -1
                      notify(obj,'Status_Update',Events.ActionData('ROI mask failed to save.'))
                      obj.fig_handle.Pointer = 'arrow';
                      obj.resetMouseMoveFunction;
                      return;
                  end
              end
           end
           
           temp_bin_mask = obj.analysis_tool.image_mask_bin; 
           if ~isempty(obj.roi_id)
            temp_roi_id = obj.roi_id;
            save(filepath,'temp_bin_mask','temp_roi_id');   
           else
            save(filepath,'temp_bin_mask');
           end
           obj.fig_handle.Pointer = 'arrow';
           obj.resetMouseMoveFunction;
           notify(obj,'Status_Update',Events.ActionData('Saved ROI mask successfully.'))
       end
       
       %%%%%%%% SAVE OUTLINED CELLS CALLBACK %%%%%%%%%%
       function save_snapshot(obj,src)
        %SAVE_SNAPSHOT File menu 'Save Snapshot' callback function.
        %   Saves only the outlined cells image; despite the name, does NOT
        %   save the image snapshot.
           obj.fig_handle.WindowButtonMotionFcn = [];
           obj.fig_handle.WindowButtonDownFcn = [];
           obj.fig_handle.WindowButtonUpFcn = [];
           obj.fig_handle.Pointer = 'watch';
           notify(obj,'Status_Update',Events.ActionData('Saving Outlined ROI Image...'))
           pause(0.1);
           old_filepath = [obj.output_dir.path obj.mask_save_name];
           filepath = regexprep(old_filepath,'\.[a-zA-Z]+','_all_outlined_cells.png');
           if strcmp(old_filepath,filepath)
               filepath = [filepath '_all_outlined_cells.png'];
           end
                      
           if isfile(filepath)
              if ~obj.dont_ask_again_snapshot
                  sel = Figure.custom_questdlg('Overwrite saved outlined ROI image?',{'Yes','No','Cancel'},'Overwrite Saved Outline Cells Image','yes');
                  obj.dont_ask_again_snapshot = sel.dont_ask_again_val;
                  switch sel.selection
                      case 'Yes'
                        obj.overwrite_snapshot = 1;
                      case 'No'
                        obj.overwrite_snapshot = 0;
                      otherwise
                          obj.fig_handle.Pointer = 'arrow';
                          obj.resetMouseMoveFunction;
                          return;
                  end
              end
              if ~obj.overwrite_snapshot
                    count = 0;
                    while isfile(filepath)
                        count = count + 1;
                        filepath = regexprep(filepath,'_all_outlined_cells(\([0-9]+\))?\.png',['_all_outlined_cells(' num2str(count) ').png']);
                    end
              else
                  temp = obj.check_fopen(filepath);
                  if temp == -1
                      notify(obj,'Status_Update',Events.ActionData('ROI snapshot failed to save.'))
                      obj.fig_handle.Pointer = 'arrow';
                      obj.resetMouseMoveFunction;
                      return;
                  end
              end
           end
           
           im = getimage(obj.analysis_tool.image_axes);
           imwrite(im+obj.analysis_tool.image_mask_outlines,filepath);
           notify(obj,'Status_Update',Events.ActionData('Saved Outlined ROI Image Successfully'))
           obj.fig_handle.Pointer = 'arrow';
           obj.resetMouseMoveFunction;
       end
       
       %%%%%%%%% SAVE LABELLED IMAGES %%%%%%%%%%%
       function save_images(obj)
        %SAVE_IMAGES File menu 'Save Images' callback function
        %   Saves a snapshot of the current image axes with ROI outlines,
        %   another with ROI outlines and numbers, and a snapshot with no
        %   ROI outlines.
            notify(obj,'Status_Update',Events.ActionData('Saving ROI Images...'))
            obj.fig_handle.WindowButtonMotionFcn = [];
            obj.fig_handle.WindowButtonDownFcn = [];
            obj.fig_handle.WindowButtonUpFcn = [];
            obj.fig_handle.Pointer = 'watch';
            
            pause(0.1);
            im = getimage(obj.analysis_tool.image_axes);
           
            %Image with cells and outlines
            cell_outline = im+obj.analysis_tool.image_mask_outlines;

            %Image with cells, outlines, and numbers
            cell_outline_num = im+obj.analysis_tool.image_mask_outlines;

            %labeling mask
            temp_master_mask = bwlabel(obj.analysis_tool.image_mask_bin,obj.connectivity);
            %getting numerical data
            master_regions = regionprops('table',temp_master_mask,'Area', 'Centroid', 'MajorAxisLength', 'MinorAxisLength', 'Perimeter');
            master_regions = master_regions(~any(ismissing(master_regions),2),:);
            [row,~] = size(master_regions);
            counter = (1:1:row)';
            if ~isempty(master_regions)
                cell_outline_num = insertText(cell_outline_num,...
                    master_regions.Centroid,counter,'FontSize',18,...
                    'TextColor','white','BoxColor','blue');
            end
            
           old_filepath = [obj.output_dir.path obj.mask_save_name];
           filepath_cell = regexprep(old_filepath,'\.[a-zA-Z]+','_all_outlined_cells.png');
           filepath_num = regexprep(old_filepath,'\.[a-zA-Z]+','_all_numbered_cells.png');
           filepath_snap = regexprep(old_filepath,'\.[a-zA-Z]+','_snapshot.png');
           if strcmp(old_filepath,filepath_cell)
               filepath_cell = [filepath_cell '_all_outlined_cells.png'];
           end
           if strcmp(old_filepath,filepath_num)
               filepath_num = [filepath_num '_all_numbered_cells.png'];
           end
           if strcmp(old_filepath,filepath_snap)
               filepath_snap = [filepath_snap '_snapshot.png'];
           end
           
           isfile_arr = cellfun(@isfile,{filepath_cell filepath_num filepath_snap});
           
           % Instantiate true array to check if files are open
           is_open = ones([1 3]);
           
           if any(isfile_arr)
              if ~obj.dont_ask_again_images
                  sel = Figure.custom_questdlg('Overwrite saved images?',{'Yes','No','Cancel'},'Overwrite Saved Images','yes');
                  obj.dont_ask_again_images = sel.dont_ask_again_val;
                  switch sel.selection
                      case 'Yes'
                        obj.overwrite_images = 1;
                      case 'No'
                        obj.overwrite_images = 0;
                      otherwise
                          obj.fig_handle.Pointer = 'arrow';
                          obj.resetMouseMoveFunction;
                          return;
                  end
              end
              if ~obj.overwrite_images
                   count = 0;
                   while isfile(filepath_cell)
                       count = count + 1;
                       filepath_cell = regexprep(filepath_cell,'_all_outlined_cells(\([0-9]+\))?\.png',['_all_outlined_cells(' num2str(count) ').png']);
                   end
                   count = 0;
                   while isfile(filepath_num)
                       count = count + 1;
                       filepath_num = regexprep(filepath_num,'_all_numbered_cells(\([0-9]+\))?\.png',['_all_numbered_cells(' num2str(count) ').png']);
                   end
                   count = 0;
                   while isfile(filepath_snap)
                       count = count + 1;
                       filepath_snap = regexprep(filepath_snap,'_snapshot(\([0-9]+\))?\.png',['_snapshot(' num2str(count) ').png']);
                   end
              else
                  is_open(1) = obj.check_fopen(filepath_cell);
                  is_open(2) = obj.check_fopen(filepath_num);
                  is_open(3) = obj.check_fopen(filepath_snap);
              end
           end
           
            %saving numbered ROI image
            notify(obj,'Status_Update',Events.ActionData('Saving Numbered ROI Image...'))
            pause(0.1);
            if is_open(2)
                imwrite(cell_outline_num,filepath_num)
                notify(obj,'Status_Update',Events.ActionData('Saved Numbered ROI Image Successfully'))
            else
                notify(obj,'Status_Update',Events.ActionData('Failed to save Numbered ROI Image.'))
            end
            
            % saving outlined ROI image
            notify(obj,'Status_Update',Events.ActionData('Saving Outlined ROI Image...'))
            pause(0.1);
            if is_open(2)
                imwrite(cell_outline,filepath_cell);
                notify(obj,'Status_Update',Events.ActionData('Saved Outlined ROI Image Successfully'))            
            else
                notify(obj,'Status_Update',Events.ActionData('Failed to save Outlined ROI Image.'))
            end
            
            % saving snapshot of image
            notify(obj,'Status_Update',Events.ActionData('Saving Image Snapshot...'))
            pause(0.1);
            if is_open(2)
                imwrite(im,filepath_snap)
                notify(obj,'Status_Update',Events.ActionData('Saved Image Snapshot Successfully'))       
            else
                notify(obj,'Status_Update',Events.ActionData('Failed to save Outlined ROI Image.'))
            end
            
            % Notify if all images have been saved successfully
            if all(is_open,'all')
                notify(obj,'Status_Update',Events.ActionData('All Images Saved Successfully'))
            end
            
            obj.fig_handle.Pointer = 'arrow';
            obj.resetMouseMoveFunction;
       end
       
       function input = new_save(obj)
        %NEW_SAVE Asks the user for a mask name.
        %   Requests a mask name from the user if this is the first
        %   time a mask is saved.
           answer = questdlg('Save ROI mask under image name?','Save Mask',...
               'Yes.','Save with another name.','Cancel','Yes.');
           switch answer
               case 'Yes.'
                   obj.file_menu.UserData = 1;
                   input = obj.image_name;
               case 'Save with another name.'
                   input = inputdlg('Enter ROI mask name:','Save as',[1 35]...
                       ,{obj.image_name});
                   if ~strcmp(input,'Cancel')
                      obj.file_menu.UserData = 1; 
                   else
                      input = obj.image_name; 
                   end
               case 'Cancel'
                   input = 'Cancel';
                   return;
           end
       end
       
       %%%%%%%%%% LOAD MASK CALLBACK %%%%%%%%%%%%
       function load_mask(obj,src)
        %LOADMASK Callback function to the ROI Tools menu 'Load Mask'
        %option.
        %   This function loads a user-selected binary ROI mask onto the
        %   current image axes. This mask can either replace the current
        %   mask or add on to it.
        
           % Get current image mask
           current_image_mask = obj.analysis_tool.image_mask_bin;
           
           % Check if current mask has any ROIs; if so, ask the user
           % whether or not to overwrite
           if any(current_image_mask,'all')
               answer = questdlg('Overwrite existing ROIs?','Load Mask',...
               'Yes.','No.','No.');
           
                if isempty(answer); return; end
                
                switch answer
                    case 'Yes.'
                        replace = 1;
                    case 'No.'
                        replace = 0;
                end
           else
               replace = 1;
           end
           
           % Autosave section within save callback; loads autosaved mask
           if strcmp(src.Tag,'Autosave')
               % Construct hardcoded autosaved mask filepath
               filepath = [obj.output_dir.path obj.mask_save_name];
               filepath = regexprep(filepath,'\.[a-zA-Z]+','_autosaved_mask.mat');
               new_mask = load(filepath);
               % Check for existance of autosaved mask
               if isempty(new_mask)
                    notify(obj,'Status_Update',Events.ActionData(['WARNING: '...
                      'No autosaved mask for this image found in selected output directory.']));
                  return;
               end
              % Load data in saved mask
              arr_name = fieldnames(new_mask);
               if length(arr_name) ~= 1
                   roi_name = arr_name{2};
                   new_roi_id = new_mask.(roi_name);
               end
              arr_name = arr_name{1};
              new_mask = new_mask.(arr_name); 
           else
               % Select a binary image mask to load
               mask_selection_file_filter = {'*.mat;','MATLAB Binary Files (*.mat)'};
               mask_selection_file_title = 'Select a MATLAB .mat image mask';
               
               % Open file selection dialog
               [file,path,filterIndex] = uigetfile(mask_selection_file_filter,...
                    mask_selection_file_title,obj.load_mask_filepath);
                if filterIndex ~= 0
                   obj.load_mask_filepath = path;
                   full_mask_path = [path file];
                   new_mask = load(full_mask_path);
                   arr_name = fieldnames(new_mask);
                   if length(arr_name) ~= 1
                       roi_name = arr_name{2};
                       new_roi_id = new_mask.(roi_name);
                   end
                   mask_name = arr_name{1};
                   new_mask = new_mask.(mask_name);
                else
                   return; 
                end
           end
           
           % Check mask is a logical array
           if ~islogical(new_mask)
               notify(obj,'Status_Update',Events.ActionData(['WARNING: '...
                  'Loaded mask must be a logical array.'])) 
              return;
           end
           
           % Check if mask size is equivalent to current image size
           if isequal(size(current_image_mask),size(new_mask))

               % If user chose to overwrite, replace existing mask and
               % redefine ROIs
               if replace
                  obj.analysis_tool.image_mask_bin = new_mask;
                  if exist('new_roi_id','var')
                      sel = Figure.custom_questdlg('ROI IDs detected in loaded mask: load IDs?',{'Yes','No','Cancel'},'Load ROI IDs','no');
                      switch sel.selection
                          case 'Yes'
                            obj.roi_id = new_roi_id;
                            % Find all unique ROI types in the loaded IDs
                            % and append 'Other' if not included
                            obj.analysis_tool.roi_types = unique(new_roi_id(~strcmp(new_roi_id,'Undefined')));
                            if ~any(strcmp(obj.analysis_tool.roi_types,'Other'))
                                obj.analysis_tool.roi_types = [obj.analysis_tool.roi_types {'Other'}];
                            end
                            obj.analysis_tool.last_id_mask = obj.analysis_tool.image_mask_bin;
                          case 'No'

                          otherwise
                              return;
                      end
                  end
               else
                   obj.analysis_tool.image_mask_bin(new_mask) = 1;
                   % If ROI IDs were loaded, need to substitute in the
                   % loaded ids to existing ids.
                   
                   if exist('new_roi_id','var')
                       % Check that user wants to load ROI IDs
                      sel = Figure.custom_questdlg('ROI IDs detected in loaded mask: load IDs?',{'Yes','No','Cancel'},'Load ROI IDs','no');
                      switch sel.selection
                          case 'Yes'
                              % Check if user wants to overwrite existing IDs
                              if ~obj.dont_ask_again_load_ids
                                  sel = Figure.custom_questdlg('Existing ROI IDs detected: overwrite?',{'Yes','No','Cancel'},'Overwrite Saved ROI IDs','yes');
                                  obj.dont_ask_again_load_ids = sel.dont_ask_again_val;
                                  switch sel.selection
                                      case 'Yes'
                                        obj.overwrite_load_ids = 1;
                                      case 'No'
                                        obj.overwrite_load_ids = 0;
                                      otherwise
                                          return;
                                  end
                              end
                              if obj.overwrite_load_ids 
                                    obj.roi_id = new_roi_id;
                                    obj.analysis_tool.roi_types = unique(new_roi_id(~strcmp(new_roi_id,'Undefined')));
                                    if ~any(strcmp(obj.analysis_tool.roi_types,'Other'))
                                        obj.analysis_tool.roi_types = [obj.analysis_tool.roi_types {'Other'}];
                                    end
                                    obj.analysis_tool.last_id_mask = obj.analysis_tool.image_mask_bin;
                              else
                                prev_stats = obj.roi_stats_tool.table_data.Centroid;
                                temp_mask = bwlabel(new_mask,obj.connectivity);
                                loaded_stats = regionprops('table',temp_mask,'Centroid');
                                loaded_stats = loaded_stats.Centroid;

                                obj.roi_stats_tool.update_stats(obj.analysis_tool.image_mask_bin);
                                new_stats = obj.roi_stats_tool.table_data.Centroid;

                                [prev_row,~] = size(prev_stats);
                                [load_row,~] = size(loaded_stats);
                                [new_row,~] = size(new_stats);

                                temp_id = cell([1 new_row]);
                                temp_id(:) = {'Undefined'};
                                % Possible existing ROIs haven't been defined yet;
                                % if so, only compare to loaded stats
                                % Note: If a loaded ROI coincides exactly with an
                                % existing ROI, the existing ID takes precedence.
                                if ~isempty(obj.roi_id)
                                    for i = 1:new_row
                                        curr_centr = new_stats(i,:);
                                        found = 0;
                                        for ii = 1:load_row
                                            if curr_centr==loaded_stats(ii,:)
                                                if strcmp(new_roi_id(ii),'Undefined')
                                                    break;
                                                end
                                                temp_id(i) = new_roi_id(ii);
                                                found = 1;
                                                break;
                                            end
                                        end
                                        if ~found
                                            for ii = 1:prev_row
                                                if curr_centr==prev_stats(ii,:)
                                                    temp_id(i) = obj.roi_id(ii);
                                                    break;
                                                end
                                            end
                                        end
                                    end
                                else
                                    for i = 1:new_row
                                        curr_centr = new_stats(i,:);
                                        for ii = 1:load_row
                                            if curr_centr==loaded_stats(ii,:)
                                                temp_id(i) = new_roi_id(ii);
                                                found = 1;
                                                break;
                                            end
                                        end
                                    end
                                end
                                obj.roi_id = temp_id;
                                obj.analysis_tool.roi_types = unique(new_roi_id(~strcmp(temp_id,'Undefined')));
                                if ~any(strcmp(obj.analysis_tool.roi_types,'Other'))
                                    obj.analysis_tool.roi_types = [obj.analysis_tool.roi_types {'Other'}];
                                end
                                obj.analysis_tool.last_id_mask = obj.analysis_tool.image_mask_bin;
                              end
                          case 'No'

                          otherwise
                              return;
                      end
                      
                      
                   end
               end
               obj.roi_stats_tool.update_stats(obj.analysis_tool.image_mask_bin);
               obj.analysis_tool.redraw_rois();
               obj.analysis_tool.add_to_record();
               notify(obj,'Status_Update',Events.ActionData(['ROI mask '...
                  'loaded successfully.']))
           else
              notify(obj,'Status_Update',Events.ActionData(['WARNING: '...
                  'Loaded mask size does not match current image size.'])) 
              return;
           end
       end
       
       %%%%%%%%%% SAVE ROI DATA/EXPORT OPTIONS CALLBACK %%%%%%%%%%%%%%
       function temp = save_roi_data(obj)
        %SAVE_ROI_DATA File menu 'Save ROI Data' callback function.
        %   Saves the statistics of current ROIs based on the current
        %   binary mask in the format selected under 'Export Options'.
        %   Default export type is as an Excel spreadsheet. Note that saved
        %   intensity values are taken from the original, unedited, not-
        %   normalized uint16 image. Gives user the additional option to
        %   save unused channels if any are detected.
            temp = 1;
            notify(obj,'Status_Update',Events.ActionData('Saving ROI Data...'))
            obj.fig_handle.WindowButtonMotionFcn = [];
            obj.fig_handle.WindowButtonDownFcn = [];
            obj.fig_handle.WindowButtonUpFcn = [];
            obj.fig_handle.Pointer = 'watch';
            
            pause(0.1);
            
            master_mask = obj.analysis_tool.image_mask_bin;
            connect_val = obj.connectivity;
            temp_im = obj.analysis_tool.image_unedited;
            bs_arr = obj.analysis_tool.bs_arr;
            temp_bs_im = obj.analysis_tool.image_unedited-bs_arr;
            extra_channels = obj.analysis_tool.extra_channels;
            orig_names = obj.analysis_tool.channel_names_orig;
            exp_times = obj.analysis_tool.channel_exp_orig;
            extra_channel_names = {};
            orig_names = cellfun(@(x)regexprep(x,'[^0-9A-Za-z_]','_'),orig_names,'UniformOutput',0);
            maxLength = namelengthmax() - 7;
            for i = 1:length(orig_names)
                if length(orig_names{i}) > maxLength
                    orig_names{i} = orig_names{i}(1:maxLength);
                end
            end
            % Check if there are any channels in 'Extra Channels'
            if cellfun(@isempty,obj.analysis_tool.extra_channels)
                export_all = 0;
            else
                % If extra channels, give the user the following options:
                %   1)  Export All Channels
                %   2)  Export Only Enabled Channels
                % For any selection, do not export 'None' Channels.
                msg = 'You have more channels loaded than are displayed. Would you like to export all available channels, or just the displayed channels?';
                title = 'Additional Channels';
                answer = questdlg(msg,title,'Export All Channels','Export Only Displayed Channels','Cancel',...
                    'Export All Channels');
                if isempty(answer) || strcmp(answer,'Cancel')
                   notify(obj,'Status_Update',Events.ActionData('Data save canceled.'))
                   obj.fig_handle.Pointer = 'arrow';
                   obj.resetMouseMoveFunction;
                   temp = 0;
                   return; 
                end
                switch answer
                    case 'Export All Channels'
                        export_all = 1;
                        extra_channels = obj.analysis_tool.extra_channels;
                        extra_channel_colors = cell([1 length(extra_channels)]);
                        extra_struct = struct();
                        count = 1;
                        for i = 1:length(extra_channels)
                           if ~isempty(extra_channels{i})
                               % Remove invalid characters
                               extra_channel_names{count} = orig_names{i};
                               count = count + 1;
                               [color_selection,tf] = listdlg('PromptString',['Select ''' orig_names{i} ''' color channel:'],...
                                   'SelectionMode','single','ListString',{'Red',...
                                   'Green','Blue'},'Name','Extra Channel Color Selection');
                               if ~tf; return; end
               
                               extra_struct.(orig_names{i}).Exposure = exp_times{i};
                               switch color_selection
                                   case 1
                                       extra_struct.(orig_names{i}).Color = 'Red';
                                       extra_struct.(orig_names{i}).Data = extra_channels{i};
                                   case 2
                                       extra_struct.(orig_names{i}).Color = 'Green';
                                       extra_struct.(orig_names{i}).Data = extra_channels{i};
                                   case 3
                                       extra_struct.(orig_names{i}).Color = 'Blue';
                                       extra_struct.(orig_names{i}).Data = extra_channels{i};
                               end
                           end
                        end
                    case 'Export Only Displayed Channels'
                        export_all = 0;
                    case 'Cancel'
                        return;
                end
            end
            none_arr = [0 0 0];
            none_bs_arr = [0 0 0];
            
            % Grab displayed image data and check if a channel has been set
            % to 'None', as well as if any background subtraction data
            % exists
            red_mask   = temp_im(:,:,1);
            red_bs_mask = temp_bs_im(:,:,1);
            if ~nnz(red_mask); none_arr(1) = 1; end
            if ~nnz(bs_arr(:,:,1)); none_bs_arr(1) = 1; end
            green_mask = temp_im(:,:,2);
            green_bs_mask = temp_bs_im(:,:,2);
            if ~nnz(green_mask); none_arr(2) = 1; end
            if ~nnz(bs_arr(:,:,2)); none_bs_arr(2) = 1; end
            blue_mask  = temp_im(:,:,3);
            blue_bs_mask = temp_bs_im(:,:,3);
            if ~nnz(blue_mask); none_arr(3) = 1; end
            if ~nnz(bs_arr(:,:,3)); none_bs_arr(3) = 1; end
            
            %preallocating 1xn of zeros where n = size of total number of red cells
            temp_master_mask = bwlabel(master_mask,connect_val);

            mcells = length(setdiff(sort(unique(temp_master_mask)),0));
            initial_arr = zeros(mcells,1);
            if ~none_arr(1)
                r_max = initial_arr;
                r_min = initial_arr;
                r_mean = initial_arr;
                if ~none_bs_arr(1)
                    r_bs_max = initial_arr;
                    r_bs_min = initial_arr;
                    r_bs_mean = initial_arr;
                end
            end
            
            if ~none_arr(2)
                g_max = initial_arr;
                g_min = initial_arr;
                g_mean = initial_arr;
                if ~none_bs_arr(2)
                    g_bs_max = initial_arr;
                    g_bs_min = initial_arr;
                    g_bs_mean = initial_arr;
                end
            end
            
            if ~none_arr(3)
                b_max = initial_arr;
                b_min = initial_arr;
                b_mean = initial_arr;
                if ~none_bs_arr(3)
                    b_bs_max = initial_arr;
                    b_bs_min = initial_arr;
                    b_bs_mean = initial_arr;
                end
            end
            
            if export_all
                for i = 1:length(extra_channel_names)
                    extra_struct.(extra_channel_names{i}).Max = initial_arr;
                    extra_struct.(extra_channel_names{i}).Min = initial_arr;
                    extra_struct.(extra_channel_names{i}).Mean = initial_arr;
                end
            end
            
            image_names = cell(mcells,1);   
            %saving numerical data
            master_regions = regionprops('table',temp_master_mask,'Area', 'Centroid', 'MajorAxisLength', 'MinorAxisLength', 'Perimeter');
            master_regions = master_regions(~any(ismissing(master_regions),2),:);
            master_regions.Properties.VariableNames = {'area', 'centroid','major_length', 'minor_length', 'perimeter'};
            to_image_name = {obj.image_name};
            [rows,~] = size(master_regions);
            counter = 1:1:rows;
            f = waitbar(0,'Begin ROI Save','Name','Saving ROI Data','CreateCancelBtn',@(src,~)obj.waitbar_close_fnc(src));
                             
            %goes through a loop made of each labelled cell and calculates the following:
            if export_all
                for i = 1:length(counter) 
                    image_names(i) = to_image_name;
                    if ~none_arr(1)
                        r_max(i)  = max(red_mask(temp_master_mask==counter(i)));
                        r_min(i)  = min(red_mask(temp_master_mask==counter(i)));
                        r_mean(i) = mean(red_mask(temp_master_mask==counter(i)));
                        if ~none_bs_arr(1)
                            r_bs_max(i)  = max(red_bs_mask(temp_master_mask==counter(i)));
                            r_bs_min(i)  = min(red_bs_mask(temp_master_mask==counter(i)));
                            r_bs_mean(i) = mean(red_bs_mask(temp_master_mask==counter(i)));
                        end
                    end
                    
                    if ~none_arr(2)
                        g_max(i)  = max(green_mask(temp_master_mask==counter(i)));
                        g_min(i)  = min(green_mask(temp_master_mask==counter(i)));
                        g_mean(i) = mean(green_mask(temp_master_mask==counter(i)));
                        if ~none_bs_arr(2)
                            g_bs_max(i)  = max(green_bs_mask(temp_master_mask==counter(i)));
                            g_bs_min(i)  = min(green_bs_mask(temp_master_mask==counter(i)));
                            g_bs_mean(i) = mean(green_bs_mask(temp_master_mask==counter(i)));
                        end
                    end
                    
                    if ~none_arr(3)
                        b_max(i)  = max(blue_mask(temp_master_mask==counter(i)));
                        b_min(i)  = min(blue_mask(temp_master_mask==counter(i)));
                        b_mean(i) = mean(blue_mask(temp_master_mask==counter(i)));
                        if ~none_bs_arr(3)
                            b_bs_max(i)  = max(blue_bs_mask(temp_master_mask==counter(i)));
                            b_bs_min(i)  = min(blue_bs_mask(temp_master_mask==counter(i)));
                            b_bs_mean(i) = mean(blue_bs_mask(temp_master_mask==counter(i)));
                        end
                    end
                    
                    for ii = 1:length(extra_channel_names)
                        temp_image_data = extra_struct.(extra_channel_names{ii}).Data;
                        extra_struct.(extra_channel_names{ii}).Max(i) = max(temp_image_data(temp_master_mask==counter(i)));
                        extra_struct.(extra_channel_names{ii}).Min(i) = min(temp_image_data(temp_master_mask==counter(i)));
                        extra_struct.(extra_channel_names{ii}).Mean(i) = mean(temp_image_data(temp_master_mask==counter(i)));
                    end
                    
                    try
                        waitbar((i/length(counter)),f,['Saving ROI ' num2str(i)...
                        '/' num2str(length(counter))])
                    catch
                        notify(obj,'Status_Update',Events.ActionData('Save canceled.'))
                        obj.fig_handle.Pointer = 'arrow';
                        obj.resetMouseMoveFunction;
                        temp = 0;
                        return;
                    end
                end
            else
                for i = 1:length(counter) 
                    image_names(i) = to_image_name;
                    if ~none_arr(1)
                        r_max(i)  = max(red_mask(temp_master_mask==counter(i)));
                        r_min(i)  = min(red_mask(temp_master_mask==counter(i)));
                        r_mean(i) = mean(red_mask(temp_master_mask==counter(i)));
                        if ~none_bs_arr(1)
                            r_bs_max(i)  = max(red_bs_mask(temp_master_mask==counter(i)));
                            r_bs_min(i)  = min(red_bs_mask(temp_master_mask==counter(i)));
                            r_bs_mean(i) = mean(red_bs_mask(temp_master_mask==counter(i)));
                        end
                    end
                    
                    if ~none_arr(2)
                        g_max(i)  = max(green_mask(temp_master_mask==counter(i)));
                        g_min(i)  = min(green_mask(temp_master_mask==counter(i)));
                        g_mean(i) = mean(green_mask(temp_master_mask==counter(i)));
                        if ~none_bs_arr(2)
                            g_bs_max(i)  = max(green_bs_mask(temp_master_mask==counter(i)));
                            g_bs_min(i)  = min(green_bs_mask(temp_master_mask==counter(i)));
                            g_bs_mean(i) = mean(green_bs_mask(temp_master_mask==counter(i)));
                        end
                    end
                    
                    if ~none_arr(3)
                        b_max(i)  = max(blue_mask(temp_master_mask==counter(i)));
                        b_min(i)  = min(blue_mask(temp_master_mask==counter(i)));
                        b_mean(i) = mean(blue_mask(temp_master_mask==counter(i)));
                        if ~none_bs_arr(3)
                            b_bs_max(i)  = max(blue_bs_mask(temp_master_mask==counter(i)));
                            b_bs_min(i)  = min(blue_bs_mask(temp_master_mask==counter(i)));
                            b_bs_mean(i) = mean(blue_bs_mask(temp_master_mask==counter(i)));
                        end
                    end
                    
                    try
                        waitbar((i/length(counter)),f,['Saving ROI ' num2str(i)...
                        '/' num2str(length(counter))])
                    catch
                        notify(obj,'Status_Update',Events.ActionData('Save canceled.'))
                        obj.fig_handle.Pointer = 'arrow';
                        obj.resetMouseMoveFunction;
                        temp = 0;
                        return;
                    end
                end
            end
            close(f);
            %need transposed counter array
            number = counter';
            
            channel_names =cellfun(@(x)regexprep(x,'[^0-9A-Za-z_]','_'), obj.analysis_tool.channel_names,'UniformOutput',0);
            maxLength = namelengthmax() - 7;
            for i = 1:length(channel_names)
                if length(channel_names{i}) > maxLength
                    channel_names{i} = channel_names{i}(1:maxLength);
                end
            end
            var_names = {'image_name','roi_num'};
            master_regions2 = table(image_names,number,'VariableNames',var_names);
            
            % Add ROI identification column, if any. Note ROI ID array is a
            % row vector; it is transposed here to match the table
            if ~isempty(obj.roi_id)
               var_name = {'roi_id'};
               master_regions2 = [master_regions2 table(obj.roi_id','VariableNames',var_name)];
            end
            
            exp_times = obj.analysis_tool.channel_exp;
            no_exp = isempty(exp_times);
            
            % Construct red channel if not 'None'
            if ~none_arr(1)
                var_names = {['r_' channel_names{1} '_max'],...
                        ['r_' channel_names{1} '_min'],['r_' channel_names{1} '_mean']};
                var_names = lower(var_names);
                master_regions2 = [master_regions2 table(r_max,r_min,r_mean,...
                    'VariableNames',var_names)];
                % If background subtracted, include data
                if ~none_bs_arr(1)
                    var_names = {['r_' channel_names{1} '_max_background_subtracted'],...
                        ['r_' channel_names{1} '_min_background_subtracted'],['r_' channel_names{1} '_mean_background_subtracted']};
                    var_names = lower(var_names);
                    master_regions2 = [master_regions2 table(r_bs_max,r_bs_min,r_bs_mean,...
                    'VariableNames',var_names)];
                end
                % If exposure time, include in data table
                if ~no_exp && ~isempty(obj.analysis_tool.channel_exp{1})
                    r_exp = ones(mcells,1).*exp_times{1};
                    var_names = {['r_' channel_names{1} '_exp']};
                    var_names = lower(var_names);
                    master_regions2 = [master_regions2 table(r_exp,...
                        'VariableNames',var_names)];
                end
            end

            % Construct green channel if not 'None'
            if ~none_arr(2)
                var_names = {['g_' channel_names{2} '_max'],...
                        ['g_' channel_names{2} '_min'],['g_' channel_names{2} '_mean']};
                var_names = lower(var_names);
                master_regions2 = [master_regions2 table(g_max,g_min,g_mean,...
                    'VariableNames',var_names)];
                % If background subtracted, include data
                if ~none_bs_arr(2)
                    var_names = {['g_' channel_names{2} '_max_background_subtracted'],...
                        ['g_' channel_names{2} '_min_background_subtracted'],['g_' channel_names{2} '_mean_background_subtracted']};
                    var_names = lower(var_names);
                    master_regions2 = [master_regions2 table(g_bs_max,g_bs_min,g_bs_mean,...
                    'VariableNames',var_names)];
                end
                % If exposure time, include in data table
                if ~no_exp && ~isempty(obj.analysis_tool.channel_exp{2})
                    g_exp = ones(mcells,1).*exp_times{2};
                    var_names = {['g_' channel_names{2} '_exp']};
                    var_names = lower(var_names);
                    master_regions2 = [master_regions2 table(g_exp,...
                        'VariableNames',var_names)];
                end
            end

            % Construct blue channel if not 'None'
            if ~none_arr(3)
                var_names = {['b_' channel_names{3} '_max'],...
                        ['b_' channel_names{3} '_min'],['b_' channel_names{3} '_mean']};
                var_names = lower(var_names);
                master_regions2 = [master_regions2 table(b_max,b_min,b_mean,...
                    'VariableNames',var_names)];
                % If background subtracted, include data
                if ~none_bs_arr(3)
                    var_names = {['b_' channel_names{3} '_max_background_subtracted'],...
                        ['b_' channel_names{3} '_min_background_subtracted'],['b_' channel_names{3} '_mean_background_subtracted']};
                    var_names = lower(var_names);
                    master_regions2 = [master_regions2 table(b_bs_max,b_bs_min,b_bs_mean,...
                    'VariableNames',var_names)];
                end
                % If exposure time, include in data table
                if ~no_exp && ~isempty(obj.analysis_tool.channel_exp{3})
                    b_exp = ones(mcells,1).*exp_times{3};
                    var_names = {['b_' channel_names{3} '_exp']};
                    var_names = lower(var_names);
                    master_regions2 = [master_regions2 table(b_exp,...
                        'VariableNames',var_names)];
                end
            end

           if export_all
               % Add extra channels to table
               for i = 1:length(extra_channel_names)
                   if ~isempty(extra_struct.(extra_channel_names{i}).Exposure)
                       color = extra_struct.(extra_channel_names{i}).Color;
                       extra_var_names = {[color(1) '_' extra_channel_names{i} '_max'],...
                        [color(1) '_' extra_channel_names{i} '_min'],...
                        [color(1) '_' extra_channel_names{i} '_mean'],...
                        [color(1) '_' extra_channel_names{i} '_exp']};
                        extra_var_names = lower(extra_var_names);

                        master_regions2 = [master_regions2 table(extra_struct.(extra_channel_names{i}).Max,...
                            extra_struct.(extra_channel_names{i}).Min,...
                            extra_struct.(extra_channel_names{i}).Mean,...
                            ones(mcells,1).*extra_struct.(extra_channel_names{i}).Exposure,...
                            'VariableNames',extra_var_names)];
                   else
                       color = extra_struct.(extra_channel_names{i}).Color;
                       extra_var_names = {[color(1) '_' extra_channel_names{i} '_max'],...
                        [color(1) '_' extra_channel_names{i} '_min'],...
                        [color(1) '_' extra_channel_names{i} '_mean']};
                        extra_var_names = lower(extra_var_names);
                        
                        master_regions2 = [master_regions2 table(extra_struct.(extra_channel_names{i}).Max,...
                            extra_struct.(extra_channel_names{i}).Min,...
                            extra_struct.(extra_channel_names{i}).Mean,...
                            'VariableNames',extra_var_names)];
                   end
               end                  
           end 
           
           % Add ROI region data
           master_regions2 = [master_regions2 master_regions];
           
           % Export data depending on selected output type
           switch obj.export_type
               case 'Excel'
                    notify(obj,'Status_Update',Events.ActionData('Writing to Excel file...'))
                    
                    old_filepath = [obj.output_dir.path obj.mask_save_name];
                    filepath = regexprep(old_filepath,'\.[a-zA-Z]+','_ROI_Data.xlsx');
                    if strcmp(old_filepath,filepath)
                       filepath = [filepath '_ROI_Data.xlsx'];
                    end
                    
                    if isfile(filepath)
                      if obj.check_fopen(filepath) == -1
                         notify(obj,'Status_Update',Events.ActionData('File in use; save canceled.'))
                         obj.fig_handle.Pointer = 'arrow';
                         obj.resetMouseMoveFunction;
                         temp = 0;
                         return; 
                      end
                      if ~obj.dont_ask_again_data
                          sel = Figure.custom_questdlg('Overwrite saved ROI data?',{'Yes','No','Cancel'},'Overwrite Saved ROI Data','yes');
                          obj.dont_ask_again_data = sel.dont_ask_again_val;
                          switch sel.selection
                              case 'Yes'
                                obj.overwrite_data = 1;
                              case 'No'
                                obj.overwrite_data = 0;
                              otherwise
                                notify(obj,'Status_Update',Events.ActionData('Save canceled.'))
                                obj.fig_handle.Pointer = 'arrow';
                                obj.resetMouseMoveFunction;
                                temp = 0;
                                return;
                          end
                      end
                      if ~obj.overwrite_data  
                          file_num = 0;
                          while isfile(filepath)
                             file_num = file_num + 1;
                             filepath = regexprep(filepath,'_ROI_Data(\([0-9]+\))?\.xlsx',['_ROI_Data(' num2str(file_num) ').xlsx']);
                          end
                      else
                          delete(filepath); 
                      end
                    end
                    
                    % Grab data summary variables and create table
                    var_names = {'total_cells','min_area_pix','max_area_pix','mean_area_pix'};
                    summ_data = table(str2double(obj.roi_stats_tool.cell.String),...
                        str2double(obj.roi_stats_tool.min_pixel.String),...
                        str2double(obj.roi_stats_tool.max_pixel.String),...
                        str2double(obj.roi_stats_tool.mean_pixel.String),...
                        'VariableNames',var_names);
                    
                    if ~isempty(obj.roi_stats_tool.conversion_factor.String)
                        var_names = {'conv_factor','min_maj_axis_um','max_maj_axis_um','mean_maj_axis_um','med_maj_axis_um',...
                            'min_area_um','max_area_um','mean_area_um','med_area_um'};
                        
                        conv_factor = str2double(obj.roi_stats_tool.conversion_factor.String);
                        
                        min_area_um = str2double(obj.roi_stats_tool.min_pixel.String)*conv_factor^2; % want um^2; have px^2. * by (um/px)^2, or conv^2
                        max_area_um = str2double(obj.roi_stats_tool.max_pixel.String)*conv_factor^2; % want um^2; have px^2. * by (um/px)^2, or conv^2
                        mean_area_um = str2double(obj.roi_stats_tool.mean_pixel.String)*conv_factor^2; % want um^2; have px^2. * by (um/px)^2, or conv^2
                        med_area_um = str2double(obj.roi_stats_tool.median_pixel.String)*conv_factor^2; % want um^2; have px^2. * by (um/px)^2, or conv^2
                        
                        % Create summary data table
                        summ_data = [summ_data table(conv_factor,...
                        str2double(obj.roi_stats_tool.min_pixel_um.String),...
                        str2double(obj.roi_stats_tool.max_pixel_um.String),...
                        str2double(obj.roi_stats_tool.mean_pixel_um.String),...
                        str2double(obj.roi_stats_tool.median_pixel_um.String),...
                        min_area_um,max_area_um,mean_area_um,med_area_um,...
                        'VariableNames',var_names)];
                    end
                    
                    writetable(master_regions2,filepath,'Sheet','Full Data','Range','A1','WriteMode','replacefile');
                    writetable(summ_data,filepath,'Sheet','Data Summary','Range','A1');
                    
                    % Create background subtraction data summary table
                    temp_range = 'A4';
                    if ~none_bs_arr(1)
                        % If 'Red' Channel was background subtracted,
                        % include parameters
                        var_names = {'red_channel_bs_shape','red_channel_bs_input_1'};
                        bs_data = table(obj.analysis_tool.bs_shapes(1),obj.analysis_tool.bs_input_parameters{1}(1),'VariableNames',var_names);
                        if length(obj.analysis_tool.bs_input_parameters{1}) == 2
                            bs_data = [bs_data table(obj.analysis_tool.bs_input_parameters{1}(2),'VariableNames',{'red_channel_bs_input_2'})];
                        end
                        
                        % Create summary data table
                        writetable(bs_data,filepath,'Sheet','Data Summary','Range',temp_range);
                        temp_range = 'A7';
                    end
                    if ~none_bs_arr(2)
                        % If 'Green' Channel was background subtracted,
                        % include parameters
                        var_names = {'green_channel_bs_shape','green_channel_bs_input_1'};
                        bs_data = table(obj.analysis_tool.bs_shapes(2),obj.analysis_tool.bs_input_parameters{2}(1),'VariableNames',var_names);
                        if length(obj.analysis_tool.bs_input_parameters{2}) == 2
                            bs_data = [bs_data table(obj.analysis_tool.bs_input_parameters{2}(2),'VariableNames',{'green_channel_bs_input_2'})];
                        end
                        
                        % Create summary data table
                        writetable(bs_data,filepath,'Sheet','Data Summary','Range',temp_range);
                        if strcmp(temp_range,'A4')
                            temp_range = 'A7';
                        else
                            temp_range = 'A10';
                        end
                    end
                    if ~none_bs_arr(3)
                        % If 'Blue' Channel was background subtracted,
                        % include parameters
                        var_names = {'blue_channel_bs_shape','blue_channel_bs_input_1'};
                        bs_data = table(obj.analysis_tool.bs_shapes(3),obj.analysis_tool.bs_input_parameters{3}(1),'VariableNames',var_names);
                        if length(obj.analysis_tool.bs_input_parameters{3}) == 2
                            bs_data = [bs_data table(obj.analysis_tool.bs_input_parameters{3}(2),'VariableNames',{'blue_channel_bs_input_2'})];
                        end
                        
                        % Create summary data table
                        writetable(bs_data,filepath,'Sheet','Data Summary','Range',temp_range);
                    end
               case 'CSV'
                    notify(obj,'Status_Update',Events.ActionData('Writing to CSV file...'))
                    
                    old_filepath = [obj.output_dir.path obj.mask_save_name];
                    filepath = regexprep(old_filepath,'\.[a-zA-Z]+','_ROI_Data.csv');
                    if strcmp(old_filepath,filepath)
                       filepath = [filepath '_ROI_Data.csv'];
                    end
                    
                    if isfile(filepath)
                      if obj.check_fopen(filepath) == -1
                         notify(obj,'Status_Update',Events.ActionData('File in use; save canceled.'))
                         obj.fig_handle.Pointer = 'arrow';
                         obj.resetMouseMoveFunction;
                         temp = 0;
                         return; 
                      end
                      if ~obj.dont_ask_again_data
                          sel = Figure.custom_questdlg('Overwrite saved ROI data?',{'Yes','No','Cancel'},'Overwrite Saved ROI Data','yes');
                          obj.dont_ask_again_data = sel.dont_ask_again_val;
                          switch sel.selection
                              case 'Yes'
                                obj.overwrite_data = 1;
                              case 'No'
                                obj.overwrite_data = 0;
                              otherwise
                                notify(obj,'Status_Update',Events.ActionData('Save canceled.'))
                                obj.fig_handle.Pointer = 'arrow';
                                obj.resetMouseMoveFunction;
                                temp = 0;
                                return;
                          end
                      end
                      if ~obj.overwrite_data  
                          file_num = 0;
                          while isfile(filepath)
                             file_num = file_num + 1;
                             filepath = regexprep(filepath,'_ROI_Data(\([0-9]+\))?\.csv',['_ROI_Data(' num2str(file_num) ').csv']);
                          end
                      else
                          delete(filepath); 
                      end
                    end
                    
                    writetable(master_regions2,filepath);
               case 'Text'
                    notify(obj,'Status_Update',Events.ActionData('Writing to text file...'))
                    
                    old_filepath = [obj.output_dir.path obj.mask_save_name];
                    filepath = regexprep(old_filepath,'\.[a-zA-Z]+','_ROI_Data.txt');
                    if strcmp(old_filepath,filepath)
                       filepath = [filepath '_ROI_Data.txt'];
                    end
                    
                    if isfile(filepath)
                      if obj.check_fopen(filepath) == -1
                         notify(obj,'Status_Update',Events.ActionData('File in use; save canceled.'))
                         obj.fig_handle.Pointer = 'arrow';
                         obj.resetMouseMoveFunction;
                         temp = 0;
                         return; 
                      end
                      if ~obj.dont_ask_again_data
                          sel = Figure.custom_questdlg('Overwrite saved ROI data?',{'Yes','No','Cancel'},'Overwrite Saved ROI Data','yes');
                          obj.dont_ask_again_data = sel.dont_ask_again_val;
                          switch sel.selection
                              case 'Yes'
                                obj.overwrite_data = 1;
                              case 'No'
                                obj.overwrite_data = 0;
                              otherwise
                                notify(obj,'Status_Update',Events.ActionData('Save canceled.'))
                                obj.fig_handle.Pointer = 'arrow';
                                obj.resetMouseMoveFunction;
                                temp = 0;
                                return;
                          end
                      end
                      if ~obj.overwrite_data  
                          file_num = 0;
                          while isfile(filepath)
                             file_num = file_num + 1;
                             filepath = regexprep(filepath,'_ROI_Data(\([0-9]+\))?\.txt',['_ROI_Data(' num2str(file_num) ').txt']);
                          end
                      else
                         delete(filepath); 
                      end
                    end
                    
                    writetable(master_regions2,filepath);
               otherwise
                    error('Critical error: output selection not recognized. Contact support with this error.');
           end
           notify(obj,'Status_Update',Events.ActionData('ROI Data saved successfully.'))
           obj.fig_handle.Pointer = 'arrow';
           obj.resetMouseMoveFunction;
       end
       
       function export_changed(obj,src)
        %EXPORT_CHANGED File menu 'Export Options' callback functions.
        %   Checks the selected export option and ensures all other export
        %   options are unchecked. Stores that data in the property
        %   'export_type'.
           exp_menu = findobj('Tag','Export_Options');
           for i = 1:length(exp_menu.Children)
               child = exp_menu.Children(i);
              if strcmp(src.Tag,child.Tag)
                  obj.export_type = src.Tag;
                  src.Checked = 'on';
              else
                  child.Checked = 'off';
              end
           end
       end
       
       %%%%%%%%%%%%%%%%%%%%%%
       % ROI MENU CALLBACKS %
       %%%%%%%%%%%%%%%%%%%%%%
       
       function set_threshold(obj,src)
        %SET_THRESHOLD Changes which color channel is used for ROI
        %thresholding.
        %   Unchecks all threshold options and then checks the channel
        %   option which activated this function. Also sets the threshold
        %   option in the child Interfaces.analyze tool to the new
        %   channel.
           
          for i = 1:length(src.Parent.Children)
              src.Parent.Children(i).Checked = 'off';
          end
          
          src.Checked = 'on';
          obj.analysis_tool.threshold_selection = src.Position; 
       end
       
       function connect_changed(obj,src)
        %CONNECT_CHANGED Callback function to ROI Tools menu item
        %'Connectivity'.
        %   Unchecks all connectivity options and checks the option which
        %   activated this function. Sets the connectivity property of this
        %   Image Analysis object to the selected option.
        
           connector = src.Parent;
           for i = 1:length(connector.Children)
              connector.Children(i).Checked = 'off'; 
           end
           src.Checked = 'On';
           obj.connectivity = str2double(src.Text);
       end
       
       function open_BS(obj)
       %OPEN_BS Opens a new instance of the background subtraction tool.
       
           % Check if dragzoom is enabled
           obj.analysis_tool.check_zoom();
           
           % Create new tool
           temp_BS = Interfaces.bckgrnd_sub_interface(obj);
       end
       
       function open_ROI_ID(obj,src)
       %OPEN_ROI_ID Opens a new instance of the ROI ID tool.
       
           % Check if dragzoom is enabled
           obj.analysis_tool.check_zoom();
           
           % Create labelled mask
           temp_master_mask = bwlabel(obj.analysis_tool.image_mask_bin,obj.connectivity);
                
           % Start from selection or from beginning
           if strcmp(src.Tag,'from_one')
               temp_ID = Interfaces.roi_identification_interface(obj);
               notify(obj,'Status_Update',Events.ActionData('Beginning ROI identification from first ROI'))
           else
               % Allow user to select an ROI to begin from
               % Wait for user input to select a point on image axes
                notify(obj,'Status_Update',Events.ActionData('Select ROI to start identification.'))
                [x,y,button] = ginput(1);
                obj.analysis_tool.image_axes.Toolbar.Visible = 'off';
                x = round(x);
                y = round(y);
                
                % If user hit 'Esc', return
                if button == 27
                    notify(obj,'Status_Update',Events.ActionData('ROI ID from selection canceled.'))
                    return; 
                end
                
                % If within axes limits, set ID
                if y > 0 && x > 0
                    sel_id = temp_master_mask(y,x);
                end
                
                % If user selects outside of image axes or selects nothing,
                % try again
                while y < 0 || x < 0 || sel_id == 0
                    [x,y,button] = ginput(1);
                    obj.analysis_tool.image_axes.Toolbar.Visible = 'off';
                    x = round(x);
                    y = round(y);
                    if button == 27
                        notify(obj,'Status_Update',Events.ActionData('ROI ID from selection canceled.'))
                        return; 
                    end
                    if y > 0 && x > 0
                        sel_id = temp_master_mask(y,x);
                    end
                end
                
                % Identify ROI below selection and start identification
                % process
                notify(obj,'Status_Update',Events.ActionData(['Beginning ROI identification from ROI #' num2str(sel_id)]))
                temp_ID = Interfaces.roi_identification_interface(obj,src,sel_id);
           end
       end
       
       function clear_IDs(obj,src)
       %CLEAR_IDS Clear all ROI IDs.
       
           obj.roi_id = [];
           src.Enable = 'off';
       end
       
       function display_ROIs_ids(obj,src)
       %DISPLAY_ROIS_IDS Check or uncheck the 'Display ROIs Numerically'
       %Display menu option and redraw ROIs accordingly.
          obj.analysis_tool.check_zoom();
          if strcmp(src.Checked,'on')
              src.Checked = 'off';
          else
              src.Checked = 'on';
          end
          obj.analysis_tool.redraw_rois();
       end
       
       function hover_display_ROIs_ids(obj,src)
       %HOVER_DISPLAY_ROIS_IDS Check or uncheck the hover ROI ID display
       %menu option.
       
          if strcmp(src.Checked,'on')
              src.Checked = 'off';
          else
              src.Checked = 'on';
          end
       end
       
       %%%%%%%%%%%%%%%%%%%%%%%
       % HELP MENU CALLBACKS %
       %%%%%%%%%%%%%%%%%%%%%%%
       
       function load_manual(obj,src)
       %LOAD MANUAL Load stored manual PDF and display.
          man_filepath = mfilename('fullpath');
          indx = strfind(man_filepath,'+Interfaces') + 11;
          man_filepath = [man_filepath(1:indx) 'MiA_Manual.pdf'];

          winopen(man_filepath);
       end

       function load_licensing(obj,src)
       %LOAD LICENSING Load stored license text and display.
          blank_fig_temp = Figure.blank_figure();
          fig_handle_temp = blank_fig_temp.fig_handle;
          fig_handle_temp.Name = "GNU General Public License V3";
          fig_handle_temp.Units = 'normalized';
          fig_handle_temp.WindowStyle = 'modal';
          fig_handle_temp.Position = [0.3 0.2 0.3 0.3];
          panel_handle_temp = blank_fig_temp.panel_handle;

          lic_filepath = mfilename('fullpath');
          indx = strfind(lic_filepath,'+Interfaces') + 11;
          lic_filepath = [lic_filepath(1:indx) 'license_txt.txt'];
          lic_text_temp = fileread(lic_filepath);
          
          uicontrol(panel_handle_temp,'Style','edit','String',lic_text_temp,...
               'Units','normalized','Position',[0.02 0.105 0.96 0.8],...
               'FontUnits','normalized','FontSize',0.04,'Enable',...
               'inactive','Min',0,'Max',2);
          uicontrol(panel_handle_temp,'Style','pushbutton','String',"OK",...
              'Units','normalized','Position',[0.45 0.02 0.1 0.08],...
              'Callback',fig_handle_temp.CloseRequestFcn)
       end

       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       % INTERNAL CALLBACK FUNCTIONS %
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       
       function waitbar_close_fnc(obj,src) %#ok<INUSL> obj is unused in this method but is necessary to call the method
        %WAITBAR_CLOSE_FNC Custom waitbar close function for waitbar
        %activated in 'save_roi_data'.
        %   The waitbar created when saving ROI data that displays the
        %   progress of the function requires this custom waitbar close
        %   function for the 'Cancel' button present in waitbar. If the
        %   'Cancel' button is the source of the close, it deletes the
        %   parent waitbar figure, while if the red 'X' option is the
        %   source of the close, it deletes the source.
           if isa(src,'matlab.ui.Figure')
               delete(src);
           else
               delete(src.Parent);
           end
       end
       
       function cont = reload_analysis(obj)
       %RELOAD_ANALYSIS This function resets all associated classes and 
       %image_analysis properties for new image analysis.
       % This function only activates if user loads a new image during
       % the same program session. Checks if any ROIs exist and asks the
       % user whether to save the existing mask before reloading.
       
          cont = 1;
          
          % Check binary mask for any ROIs; if any exist, ask user to save
          %if exist(obj.analysis_tool.image_mask_bin)
          if isvalid(obj.analysis_tool)
              if nnz(obj.analysis_tool.image_mask_bin)
                  sel = Figure.custom_questdlg('Save existing ROI mask?',...
                      {'Yes','No','Cancel'},'Overwrite Saved ROI Data','no');
    
                  switch sel.selection
                      case 'Yes'
                          cont = obj.save_roi_mask();
                          if ~cont; return; end
                      case 'No'
    
                      otherwise
                          cont = 0;
                          return;
                  end
              end
                % Delete the Analysis Tool
                delete(obj.analysis_tool);
          end
           
          % If Channel Select tool is active, close it
          temp = findobj('Tag','Channel Select Tool');
          if ~isempty(temp)
              delete(temp);
          end
          
         
           % If a BS tool is still active, delete it
           temp = findobj('Tag','Background Subtraction Tool');
           if ~isempty(temp)
               delete(temp);
           end
           
           % Removes and resets user data so that function 'dragzoom' in
           % package '+Figure' acts as though a new set of axes has been
           % created
           UserData = get(obj.fig_handle, 'UserData');

           if isfield(UserData, 'axesinfo')
               UserData = rmfield(UserData,{'origcallbacks','axesinfo','origfigname','tools'});
               set(obj.fig_handle,'UserData',UserData);
           end
           
           % Reset channel tool properties
           obj.channel_tool.reset_data();
           
           % Remove ROI Stats Listeners
           for i = 1:length(obj.roi_stats_tool.AutoListeners__)
            delete(obj.roi_stats_tool.AutoListeners__{i})
           end
           
           % Add back any needed listeners/objects not included in
           % 'enable_analysis'
           addlistener(obj.roi_stats_tool,'Status_Update',@(~,evnt)obj.status_bar.update_status(evnt));
           % Parent axes were deleted; recreate ROI display text
           obj.roi_disp_txt = text('Visible','off');   
           
           % Resest ROI ID values
           obj.roi_id_next_default = 1; 
           obj.roi_id_next_default_val = 1; 
           
           % Update statistics with a temporary empty false array to
           % quickly remove all listed stats
           obj.roi_stats_tool.update_stats(false(3));
       end
       
       function temp = check_fopen(obj,filepath)
       %CHECK_FOPEN Check if a given file is already open in another
       %program and inform the user if true. Otherwise, do nothing.
       
          temp = fopen(filepath,'w');
          if temp == -1
            % Inform user file is in use and exit
            d = dialog('units','normalized','Position',[0.4 0.4 0.2 0.15],...
                'Name','File In Use');
            uicontrol(d,'Style','text','units','normalized',...
                'Position',[0 0.6 1 0.3],'String',['Existing file ',...
                'is in use by another application; close and try ',...
                'again.'],'FontUnits','normalized','FontSize',0.4);
            uicontrol(d,'units','normalized','Position',...
                [0.4 0.2 0.2 0.2],'String',...
                'OK','Callback',@(~,~)delete(d),...
                'FontUnits','normalized','FontSize',0.4);
          else
             % If file is not in use, close to avoid 'file in
             % use' by MATLAB
             fclose(temp); 
          end
       end
       
    end
end

