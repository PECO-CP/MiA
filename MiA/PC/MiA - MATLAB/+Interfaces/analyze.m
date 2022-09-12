classdef analyze < handle
%ANALYZE Secondary MATLAB tool; child of image_analysis parent class
%      ANALYZE creates a new ANALYZE class object instance within the parent 
%      class or creates a nonfunctional GUI representation.
%
%      H = ANALYZE returns the handle to a new ANALYZE tool.
% 
%      This class was constructed to operate solely with the parent class
%      image_analysis in package Interfaces. This may change in future
%      releases.
%
%      This class can be run on its own; in that case, it is a
%      nonfunctional representation of the graphic objects inherent in this
%      class. This is primarily used for troubleshooting and preview
%      purposes.

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

    properties
        % Parent class objects and Constant properties
        parent                              % handle to parent class
        CONSTANTS = Constants.Graphics();   % graphics constants
        
        % Class graphic objects
        fig_handle = [];                    % handle to parent figure
        fig_title = [];                     % Original fig title; when dragzoom is disabled, necessary to reset title
        image_panel = [];                   % handle to parent panel (where image axes are displayed)
        image_axes = [];                    % handle to axes that display image 
        
        % Image properties
        filepath = [];                      % image filepath(s)
        image_data = [];                    % for RGB and grayscale, just the image; for CZI, image, metadata, color map, OME metadata
        original_data = [];                 % holds specifically all color image data
        extra_channels = [];                % holds any non-empty channels not currently selected
        channel_exp_orig = {};              % for > 3 channel images, holds original exposure times for later use
        channel_exp = {};                   % cell array holding exposure times for individual channels
        channel_names_orig = {};            % for > 3 channel images, holds original channel names for later use
        channel_names = {};                 % cell array holding channel names
        color_channels = [];                % string array containing which channels are assigned to which color
        image_type = [];                    % image type; 1 for CZI, 2 for RGB, 3 for grayscale
        image_handle = [];                  % handle for created image object
        image_unedited = [];                % original unedited image array
        image_mask_original = [];           % initial original normalized image array
        image_mask = [];                    % current normalized image array, unedited
        image_edited = {};                  % series of edited image arrays
        image_mask_bin = [];                % binary image mask (logical array)
        image_mask_outlines = [];           % ROI outlines in image format (uint8 array)
        image_normalized_all = [];          % handle to image of all channels combined, normalized
        threshold_selection = [];           % channel with which to threshold on
        image_info = [];                    % handle to structure with image info
        mask_indx = 1;                      % holds index of most recent mask in image_edited array
        bs_arr = [];                        % background subtraction mask array
        
        % Zoom values
        zoom_limits = [];                   % current axes limits to maintain zoom   
        zoom_reset = [];                    % original axes limits for zoom reset
        
        % Background subtraction
        bs_shapes = {'','',''};             % cell string array of 'Rolling Ball' shapes for each channel
        bs_input_parameters = cell([1 3]);  % cell vector array of inputs for each BS performed on each channel
        
        % ROI Identification
        last_id_mask = [];                  % stores mask associated with most recent ROI identification
        last_zoom = 0;                      % stores previous 'zoom-out' value for ROI IDing
        id_edited = {};                     % stores series of ROI IDs
        roi_types = {'Undefined'};          % stores uploaded or added roi types
    end
    
    events
       Status_Update        % Status_Update event, indicating an event has occurred significant enough to display to the user
       SelectionMade        % SelectionMade event, indicating an image(s) has been selected
       ChannelChanged       % ChannelChanged event, indicating a channel's contrast has been changed, or a channel has been disabled/enabled.
       ChannelsSelected     % ChannelsSelected event, indicating the user has finished selecting the color channels for a CZI or grayscale image.
       ROIDefined           % ROIDefined event, indicating an ROI has been defined by any of the ROI-related functions
       ThresholdChanged     % ThresholdChanged event, indicating that the thresholdhing level for a 'Manual Interface Threshold' GUI has been changed
       AreaFilter           % AreaFilter event, indicating the user has changed the min/max ROI area
    end
    
    methods
        function obj = analyze(parent_class,filepath,filter_index)
            %ANALYZE Creates an analysis object that expands the parent figure
            % object to include the loaded image(s) and contains functions
            % for analysis.
            %
            %  Can be called with 0-3 input arguments. However, a call with
            %  any inputs less than 3 will result in a nonfunctional
            %  version of the tool.
            %
            %  Inputs:      parent_class : Parent class that will hold the
            %                              analysis tool object. Currently requires an instance of the 
            %                              image_analysis interface class as the parent class.
            %                   filepath : Filepath to the image to be
            %                              loaded. Can be either a cell array of
            %                              grayscale image filepaths or a character 
            %                              array of one .CZI or .tiff filepath.
            %               filter_index : Filter index indicates what type
            %                              of image was loaded.
            %                                   1 = CZI image
            %                                   2 = RGB image
            %                                   3 = Grayscale images
            %
            %  Outputs:              obj : An analyze object with the
            %                              properties and functions listed 
            %                              above and below.
            if nargin < 3
                filter_index = 'Default';
                if nargin < 2
                    filepath = 'Default';
                    if nargin < 1
                       fig_handle = Figure.blank_figure().fig_handle;
                       image_panel = uipanel(fig_handle);
                    end
                end
            else
               obj.parent = parent_class;
               fig_handle = parent_class.fig_handle;
               image_panel = parent_class.image_panel;
               temp_handle_roi = findobj('Tag','ROI Menu');
               temp_handle_display = findobj('Tag','Display Menu');
               if ~isempty(temp_handle_roi)
                   for i = 1:length(temp_handle_roi.Children)
                      temp_handle_roi.Children(i).Enable = 'on'; 
                   end
               end
               if ~isempty(temp_handle_display)
                   for i = 1:length(temp_handle_display.Children)
                      temp_handle_display.Children(i).Enable = 'on'; 
                   end
               end
            end
            
            obj.fig_handle = fig_handle;
            
            obj.fig_handle.WindowButtonMotionFcn = [];
            obj.fig_handle.WindowButtonDownFcn = [];
            obj.fig_handle.WindowButtonUpFcn = [];
            obj.fig_handle.Pointer = 'watch';
            
            obj.image_panel = image_panel;
            obj.filepath = filepath;
            
            % Check if image axes already exist
            temp_axes = findobj('Tag','Image Axes');
            if isempty(temp_axes)
                obj.image_axes = axes(obj.image_panel,'Units','normalized',...
                    'Position',obj.CONSTANTS.FIG_FILL,'Visible','off','Tag','Image Axes');
                obj.image_axes.Toolbar.Visible = 'off';
            else
               obj.image_axes = temp_axes; 
            end
            obj.fig_title = obj.fig_handle.Name;
            obj.parent.roi_disp_txt.Parent = obj.image_axes;
            
            % Extract channel tool
            chan_tool = obj.parent.channel_tool;
            im_prop_hand = chan_tool.image_prop_image;
            if filter_index == 1
                % Filter index of 1 refers to a CZI image
                obj.image_data = bfmatlab.bfopen(filepath);
                obj.image_type = 1;
                s = dir(filepath);
                im_prop_hand.Visible = 'on';
                imshow(imread([chan_tool.image_prop_image_dir 'czi_logo.png']),'Parent',im_prop_hand);
                obj.image_info = struct('FileSize',s.bytes,'Filename',filepath,'Format','czi');
                im_type_string = 'Carl Zeiss Image (.';
                obj.analyzeCZI();
            elseif filter_index == 2
                % Filter index of 2 or 3 refers to a RGB or grayscale image
                obj.image_data = imread(filepath);
                obj.image_info = imfinfo(filepath);
                obj.image_type = 2;
                im_prop_hand.Visible = 'on';
                imshow(imread([chan_tool.image_prop_image_dir 'tiff_logo.jpg']),'Parent',im_prop_hand);
                im_type_string = 'RGB Image (.';
                obj.analyzeRGB();
            elseif filter_index == 3
                obj.image_type = 3;
                im_prop_hand.Visible = 'on';
                imshow(imread([chan_tool.image_prop_image_dir 'tiff_logo.jpg']),'Parent',im_prop_hand);
                im_type_string = 'Grayscale Image (.';
                if iscell(filepath)
                    obj.image_info = imfinfo(filepath{1});
                    for i = 1:length(filepath)
                        obj.image_data{i} = imread(filepath{i});
                    end
                    if i < 3
                       % Since case of 1 is already accounted for, only two
                       % images will activate this if statement
                       [rows,columns] = size(obj.image_data{1});
                       obj.image_data{3} = zeros(rows,columns);
                       filepath{3} = 'BLANK IMAGE 1';
                    end
                else
                    % One loaded image
                    obj.image_data{1} = imread(filepath);
                    obj.image_info = imfinfo(filepath);
                    [rows,columns] = size(obj.image_data{1});
                    obj.image_data{2} = zeros(rows,columns);
                    obj.image_data{3} = zeros(rows,columns);
                    temp = {filepath};
                    filepath = temp;
                    filepath{2} = 'BLANK IMAGE 1';
                    filepath{3} = 'BLANK IMAGE 2';              
                end
                obj.analyzeGray(filepath);
            end
            
            % Set image info
            
           chan_tool.image_type_txt.String = [im_type_string obj.image_info.Format ')'];
           chan_tool.image_filepath_txt.String = regexprep(obj.image_info.Filename,' ','');
           chan_tool.image_filepath_txt.Tooltip = obj.image_info.Filename;
           chan_tool.image_bit_depth.String = num2str(obj.image_info.BitDepth);
           chan_tool.image_dimensions.String = [num2str(obj.image_info.Height) 'x' num2str(obj.image_info.Width) ' pixels'];
           chan_tool.image_file_size.String = [num2str(obj.image_info.FileSize/1024/1024) 'MB (' num2str(obj.image_info.FileSize) ' bytes)'];           % handle to image file size text


            % Enable all thresholding options
            threshold_options = findobj('Tag','threshold');
            if ~isempty(threshold_options)
                for i = 1:length(threshold_options.Children)
                   if strcmp(threshold_options.Children(i).Checked,'on')
                      obj.threshold_selection = 5-i; 
                   end
                end
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%
        % LOAD IMAGES FUNCTIONS %
        %%%%%%%%%%%%%%%%%%%%%%%%%
        
        function obj = analyzeRGB(obj)
        %ANALYZERGB Analyze function for loading an RGB image.
        % Function takes in RGB image data, creates a binary mask matching
        % its size, then normalizes and loads the image into the image_axes
        % display window.
            
            % Extract image data
            obj.image_unedited = obj.image_data;
            
            % Create blank background subtraction mask
            obj.bs_arr = obj.image_unedited;
            obj.bs_arr(:) = 0;
            
            obj.original_data = {obj.image_data(:,:,1) obj.image_data(:,:,2) obj.image_data(:,:,3)};
            % Set empty, editable channel name and exposure time arrays
            obj.channel_names = {'Red','Green','Blue','None'};
            obj.channel_exp = cell(size(obj.channel_names));
            obj.channel_exp_orig = obj.channel_exp;
            obj.channel_names_orig = obj.channel_names;
            obj.extra_channels = cell([1 length(obj.original_data)]);
            % Create binary mask
            obj.image_mask_bin = false(size(obj.image_data(:,:,1)));
            obj.image_mask_outlines = uint8(zeros(size(obj.image_unedited(:,:,1))));
            
            % Normalize image
            I2 = double(obj.image_unedited);
            I2 = I2 - min(I2(:));
            I2 = I2 / max(I2(:));
            I2 = im2uint8(I2);
            obj.image_mask = I2;
            obj.image_mask_original = I2;
            obj.image_normalized_all = I2;
            % Display image on image_axes
            obj.image_handle = imshow(I2,'Parent',obj.image_axes);
            % Recreate image axes text after initial imshow (imshow deletes
            % existing axes objects)
            obj.parent.roi_disp_txt = text('Visible','off','Parent',obj.image_axes);
            
            % Set initial axes limits for maintaing zoom and resetting
            % orignal view
            obj.zoom_limits = get(obj.image_axes,{'XLim','YLim'});
            obj.zoom_reset = obj.zoom_limits;
            
            % Notify parent class that the image was successfully loaded.
            notify(obj,'Status_Update',Events.ActionData([obj.filepath ' Loaded']))
            
            % Reset figure pointer to arrow and reinstate pointer callbacks
            obj.fig_handle.Pointer = 'arrow';
            obj.parent.resetMouseMoveFunction;
            
            % Add binary image mask to record of binary masks
            obj.add_to_record();
        end
        
        function obj = analyzeGray(obj,filepath)
        %ANALYZEGRAY Analyze function for loading a grayscale image.
        % Function takes in grayscale image data, creates a binary mask matching
        % its size, then creates a 'Interfaces.select_channel' object to
        % allow the user to select which grayscale image should correspond
        % to which color channel.
        
            % Extract image data
            obj.image_unedited = obj.image_data;
            
            % Create binary mask
            obj.image_mask_bin = false(size(obj.image_unedited{1}));
            
            % Reset figure pointer to arrow and reinstate pointer callbacks
            obj.fig_handle.Pointer = 'arrow';
            obj.parent.resetMouseMoveFunction;
            
            % Create new Interfaces.select_channel object
            channel_select_tool = Interfaces.select_channel(filepath,obj.parent.last_color_order);
            
            % Extract channel names from filepath
            for i = 1:length(filepath)
                new_name = regexp(filepath{i},'([^\\/]+)(?!\\/)','tokens');
                if ~isempty(new_name)
                   obj.channel_names{i,1} = new_name{end}{1}; 
                else
                   obj.channel_names{i,1} = filepath{i}; 
                end
            end
            obj.channel_names{end+1,1} = 'None';
            % Add event listeners to the new object
            addlistener(channel_select_tool,'ChannelsSelected',...
                @(~,evnt)obj.normalize_load_image(evnt));
            addlistener(channel_select_tool,'Status_Update',@(~,evnt)notify(obj,'Status_Update',evnt));
            
            % Add binary mask to the record
            obj.add_to_record();
        end
        
        function obj = analyzeCZI(obj)
        %ANALYZECZI Analyze function for loading a CZI image.
        % Function takes in CZI image data, creates a binary mask matching
        % its size, then creates a 'Interfaces.select_channel' object to
        % allow the user to select which CZI image should correspond
        % to which color channel.
        
            % Extract image from data
            obj.image_unedited = obj.image_data{1,1}(:,1);
            
            % Create binary image mask
            obj.image_mask_bin = false(size(obj.image_unedited{1}));
            
            % Extract metadata from data
            metadata = obj.image_data{1,2};
              
            % Initialize channel tracking arrays
            channel_keys = cell(size(obj.image_unedited));
            channel_numbers = zeros(length(obj.image_data{1}),1);
                      
            %%%%%%%%%%%%%%%%%%% RETRIEVE CHANNEL NAMES %%%%%%%%%%%%%%%%%%%
            % retrieve all key names
            allKeys = arrayfun(@char, metadata.keySet.toArray, 'UniformOutput', false);
            % retrieve all key values
            allValues = cellfun(@(x) metadata.get(x), allKeys, 'UniformOutput', false);
            
            % Apply known .CZI Hashtable filters to find channel names
            for i = 1:length(obj.image_unedited)
                channel_keys{i,1} = ['Global Information|Image|Channel|Name #' num2str(i)];
            end
            temp_channel_names = cellfun(@(x) metadata.get(x),channel_keys, 'UniformOutput', false);
            
            % Find activated channel numbers
            channel_num_count = 0;
            for ii=1:length(allKeys)
                if contains(allKeys{ii,1},'Global Experiment')...
                        && contains(allKeys{ii,1},'AcquisitionBlock')...            
                        && contains(allKeys{ii,1},'IsActivated')...
                        && contains(allKeys{ii,1},'Track')...
                        && contains(allKeys{ii,1},'Channel')...
                        && ~contains(allKeys{ii,1},'ShadingReferenceTrack')...
                        && ~contains(allKeys{ii,1},'DataGrabberSetup')...
                        && ~contains(allKeys{ii,1},'FocusSetup')
                    
                        %true means that the channel was used
                        if strcmp(allValues{ii,1},'true')
                            %save channel numbers used
                            channel_num_count = channel_num_count + 1;
                            channel_numbers(channel_num_count) = str2double(allKeys{ii,1}(end)); 
                        end
                 end

            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            
            %%%%%%%%%%%%%%%%% RETRIEVE EXPOSURE TIMES %%%%%%%%%%%%%%%%%%%%%
            % Extract channel exposure times and names associated with them
            names_channel_exp = cell([length(temp_channel_names) 1]);
            
            obj.image_info.Width = str2double(metadata.get('Global Information|Image|SizeX #1'));
            obj.image_info.Height =  str2double(metadata.get('Global Information|Image|SizeY #1'));
            obj.image_info.BitDepth =  str2double(metadata.get('Global Information|Image|Channel|ComponentBitCount #1'));

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            
            %%%%%%%%%%%%%%%%% RETRIEVE IMAGE INFO %%%%%%%%%%%%%%%%%%%%%
            % Extract channel exposure times and names associated with them
            for ii = 1:length(allKeys)
                if contains(allKeys{ii,1},'Global Experiment|AcquisitionBlock|')...
                   && ~contains(allKeys{ii,1},'IsActivated') ...
                   && ~contains(allKeys{ii,1},'FocusSetup')
                    for jj=1:length(channel_numbers)
                        if contains(allKeys{ii,1},['Channel|DataGrabberSetup|CameraFrameSetup|ExposureTime #' num2str(channel_numbers(jj))])
                            obj.channel_exp{jj,1} = str2double(allValues{ii,1});
                        end
                    end
                end
                
                for jj=1:length(channel_numbers)
                    if contains(allKeys{ii,1},['Track|Channel|Name #' num2str(channel_numbers(jj))])...
                        && ~contains(allKeys{ii,1},'FocusSetup')
                        names_channel_exp{jj,1} = string(allValues{ii,1});
                    end
                end
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            
            %%%%%% RE-INDEX EXPOSURE TIMES TO PROPER CHANNELS %%%%%%%%%%%%%
            % Exposure time array and channel names array do not always
            % match; this rearranges the exposure time array to match.
            temp_exp_arr = num2cell(zeros(length(temp_channel_names),1));
            for i = 1:length(temp_channel_names)
               logi = strcmp(string(temp_channel_names{i}),string(names_channel_exp));
               temp_exp_arr{i,1} = obj.channel_exp{logi};
            end
            obj.channel_exp = temp_exp_arr;
            
            % Set blank exposure times, channel names, and image channels
            % for CZIs with < 3 channels
            while length(temp_channel_names) < 3
                image_num = length(temp_channel_names) + 1;
                temp_channel_names{end+1,1} = ['Blank #' num2str(image_num)]; %#ok
                obj.channel_exp{end+1,1} = []; 
                obj.image_unedited{end+1} = zeros(size(obj.image_unedited{1}));
            end
            
            obj.channel_names = temp_channel_names;
            obj.channel_names{end+1} = 'None';
            % Reset pointer figure and pointer callback functions
            obj.fig_handle.Pointer = 'arrow';
            obj.parent.resetMouseMoveFunction;
            
            % Allow user to select which color they wish to assign to each channel
            channel_select_tool = Interfaces.select_channel(temp_channel_names,obj.parent.last_color_order);
            
            % Add event listeners to new tool
            addlistener(channel_select_tool,'ChannelsSelected',@(~,evnt)obj.normalize_load_image(evnt));
            addlistener(channel_select_tool,'Status_Update',@(~,evnt)notify(obj,'Status_Update',evnt));
            
            % Add binary mask to record
            obj.add_to_record();
        end
        
        function obj = normalize_load_image(obj,data)
        %NORMALIZE_LOAD_IMAGE Final loading function, implemented after CZI
        %or grayscale color channels have been selected for loading.
        % Function takes in channel selection data and creates a
        % three-channel RGB image based on selection data. It then
        % normalizes and displays that image.
            
            % Extract EventData
            selection = data.newValue;
            
            if selection == -1
               obj.parent.roi_menu.Enable = 'off';
               obj.parent.roi_stats_tool.enable_edits('off');
               obj.parent.display_menu.Enable = 'off';
               return;
            end
            
            % Create color position variables
            red_pos = find(selection==1);
            green_pos = find(selection==2);
            blue_pos = find(selection==3);
            
            obj.parent.last_color_order = [red_pos green_pos blue_pos]; % remember current color order if next image is loaded
            
            if ~isempty(obj.channel_names)
                obj.channel_names_orig = obj.channel_names;
                obj.channel_names = [obj.channel_names(red_pos,1);obj.channel_names(green_pos,1);obj.channel_names(blue_pos,1)];
                
            end
            % Reorder image channels and exposure times based on selection data
            image_whole = cat(3,obj.image_unedited{red_pos},obj.image_unedited{green_pos},obj.image_unedited{blue_pos});
            if ~isempty(obj.channel_exp)
                obj.channel_exp_orig = obj.channel_exp;
                obj.channel_exp = [obj.channel_exp(red_pos,1);obj.channel_exp(green_pos,1);obj.channel_exp(blue_pos,1)];
            else
                obj.channel_exp_orig = cell(size(obj.channel_names_orig));
                obj.channel_exp = cell(size(obj.channel_names));
            end
            obj.original_data = obj.image_unedited;
            obj.image_unedited = image_whole;
            
            % Create blank background subtraction mask
            obj.bs_arr = obj.image_unedited;
            obj.bs_arr(:) = 0;
            
            % Normalize image
            I2 = double(obj.image_unedited);
            I2 = I2 - min(I2(:));
            I2 = I2 / max(I2(:));
            I2 = im2uint8(I2);
            obj.image_mask = I2; % current image mask
            obj.image_mask_original = I2; % original image mask
            
            % Create logical array to identify extra channels
            logi_channels = false([1 length(obj.channel_names_orig)]);
            logi_channels(red_pos) = 1;
            logi_channels(green_pos) = 1;
            logi_channels(blue_pos) = 1;
            logi_channels(end) = 1;
                
            % Store all channels
            I3 = obj.original_data{1};
            for i = 2:length(obj.original_data)
                I3 = cat(3,I3,obj.original_data{i});
            end           
            obj.image_normalized_all = I3;
            
            % Store unused channels for export
            obj.extra_channels = cell([1 length(logi_channels)]);
            for i = 1:length(logi_channels)
                selected = ~logi_channels(i);
                if selected
                    obj.extra_channels{i} = obj.image_normalized_all(:,:,i);
                end
            end
                
            % Create ROI image mask outlines
            obj.image_mask_outlines = uint8(zeros(size(obj.image_unedited)));
            
            % Create and display normalized image
            obj.image_handle = imshow(I2,'Parent',obj.image_axes);
            % Recreate image axes text after initial imshow (imshow deletes
            % existing axes objects)
            obj.parent.roi_disp_txt = text('Visible','off','Parent',obj.image_axes);
            
            % Record image_axes limits
            obj.zoom_limits = get(obj.image_axes,{'XLim','YLim'});
            obj.zoom_reset = obj.zoom_limits;
            
            % Notify parent class that channels have been selected and
            % image loaded
            notify(obj,'ChannelsSelected',Events.ActionData(obj));
            temp_path = obj.filepath;
            if iscell(obj.filepath)
                temp_path = obj.filepath{1};
            end
            if ~isempty(obj.channel_exp) && ~isempty(obj.channel_exp{1})
                notify(obj,'Status_Update',Events.ActionData([temp_path ' and Exposure Times Loaded']))
            else
                notify(obj,'Status_Update',Events.ActionData([temp_path ' Loaded']))
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % IMAGE CONTRAST EDITING FUNCTIONS %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function obj = update_channel(obj,src)
        %UPDATE_CHANNEL Updates current image contrast values and enabled
        %channels.
        % Function takes in the source of its activation, an
        % Interfaces.channel object, and checks which channels have been
        % activated. Disabled channels are replaced with an equal sized
        % array of zeros. The image's color data is then updated
        % accordingly.
        
            % Check if color channels have been swapped
            if strcmp(src.UserData,'Channel_Changed')
                zero_channel = zeros(size(obj.image_mask_original(:,:,1)));
                
                red_pos = find(strcmp(src.red_channel_name.String(src.red_channel_name.Value),obj.channel_names_orig)==1);
                green_pos = find(strcmp(src.green_channel_name.String(src.green_channel_name.Value),obj.channel_names_orig)==1);
                blue_pos = find(strcmp(src.blue_channel_name.String(src.blue_channel_name.Value),obj.channel_names_orig)==1);
                is_none = length(obj.channel_names_orig);
                
                % Create logical array to identify unused channels
                logi_channels = false([1 length(obj.channel_names_orig)]);
                logi_channels(red_pos) = 1;
                logi_channels(green_pos) = 1;
                logi_channels(blue_pos) = 1;
                logi_channels(is_none) = 1;
                
                if red_pos == is_none
                    red_channel = zero_channel;
                else
                    red_channel = obj.original_data{red_pos};
                end
                
                if green_pos == is_none
                    green_channel = zero_channel;
                else
                    green_channel = obj.original_data{green_pos};
                end
                
                if blue_pos == is_none
                    blue_channel = zero_channel;
                else
                    blue_channel = obj.original_data{blue_pos};
                end
                
                image_whole = cat(3,red_channel,green_channel,blue_channel);
                obj.image_unedited = image_whole;
                
                % Normalize RGB-specific image channels
                I2 = double(obj.image_unedited-obj.bs_arr); % include background subtraction, if any
                I2 = I2 - min(I2(:));
                I2 = I2 / max(I2(:));
                I2 = uint8(255*I2);
                obj.image_mask = I2; % current image mask
                obj.image_mask_original = I2; % original image mask
                 
                % Store unused channels for export
                obj.extra_channels = cell([1 length(logi_channels)]);
                for i = 1:length(logi_channels)
                    selected = ~logi_channels(i);
                    if selected
                        obj.extra_channels{i} = obj.image_normalized_all(:,:,i);
                    end
                end
                
                %obj.image_handle = imshow(obj.image_handle.CData,'Parent',obj.image_axes);
                %set(obj.image_axes,{'XLim','YLim'},obj.zoom_limits);
                obj.redraw_rois();
                % Create image history plots based on image
                src.red_bar_plot.YData = imhist(obj.image_mask(:,:,1));
                src.green_bar_plot.YData = imhist(obj.image_mask(:,:,2));
                src.blue_bar_plot.YData = imhist(obj.image_mask(:,:,3));
            end

            % Checks if red channel is enabled
            if src.red_check_box.Value == 0
                zero_channel = zeros(size(obj.image_mask_original(:,:,1)));
                obj.image_mask(:,:,1) = zero_channel;
            else
                obj.image_mask(:,:,1) = obj.image_mask_original(:,:,1);
            end

            % Checks if green channel is enabled
            if src.green_check_box.Value == 0
                zero_channel = zeros(size(obj.image_mask_original(:,:,2)));
                obj.image_mask(:,:,2) = zero_channel;
            else
                obj.image_mask(:,:,2) = obj.image_mask_original(:,:,2);
            end

            % Checks if blue channel is enabled
            if src.blue_check_box.Value == 0
                zero_channel = zeros(size(obj.image_mask_original(:,:,3)));
                obj.image_mask(:,:,3) = zero_channel;
            else
                obj.image_mask(:,:,3) = obj.image_mask_original(:,:,3);
            end
            
            % Creates a triplet of normalized high and low RGB values
            high_rgb_triplet = [src.red_channel_max_slider.Value/255,...
                               src.green_channel_max_slider.Value/255,...
                               src.blue_channel_max_slider.Value/255];
            low_rgb_triplet = [src.red_channel_min_slider.Value/255,...
                                src.green_channel_min_slider.Value/255,...
                                src.blue_channel_min_slider.Value/255];
            
            % Adjusts the image color data with new min and max values
            obj.image_handle.CData = uint8((imadjust(obj.image_mask,...
                [low_rgb_triplet; high_rgb_triplet],[])));
            obj.image_mask = obj.image_handle.CData;
            obj.redraw_rois();
        end
        
        %%%%%%%%%%%%%%%%%%%%%%
        % DRAW ROI FUNCTIONS %
        %%%%%%%%%%%%%%%%%%%%%%
        
        function draw_ellipse(obj)
        %DRAW_ELLIPSE Allows the user to create an ellipse ROI on the image
        %axes. 
        % Function disables zoom if it is enabled, and waits for user input
        % to define the elliptical ROI. It then passes the ROI to
        % 'roi_definition' and adds the updated binary mask to the record.
        
            % Disable 'dragzoom' if it is enabled
            obj.check_zoom();
            
            % Update the user on status and create a manipulable ellipse
            notify(obj,'Status_Update',Events.ActionData('Draw ROI ellipse.'))
            roi = drawellipse(obj.image_axes);
            notify(obj,'Status_Update',Events.ActionData('Double-click to finalize ROI definition.'))
            wait(roi);
            
            % If user cancels ROI creation, return
            if isempty(roi.Position)
               return; 
            end
            
            % Pass binary ROI to roi_definition and notify parent class
            obj.roi_definition(roi);
            notify(obj,'ROIDefined');
            
            % Add ROI binary mask to record
            obj.add_to_record();
        end
        
        function draw_freehand(obj)
        %DRAW_FREEHAND Allows the user to create a freehand ROI on the image
        %axes. 
        % Function disables zoom if it is enabled, and waits for user input
        % to define the freehand ROI. It then passes the ROI to
        % 'roi_definition' and adds the updated binary mask to the record.
        
            % Disable 'dragzoom' if it is enabled
            obj.check_zoom();
            
            % Update the user on status and create a manipulable freehand
            % drawing
            notify(obj,'Status_Update',Events.ActionData('Draw ROI freehand.'))
            roi = drawfreehand(obj.image_axes);
            notify(obj,'Status_Update',Events.ActionData('Double-click to finalize ROI definition.'))
            wait(roi);
            
            % If user cancels ROI creation, return
            if isempty(roi.Position)
               return; 
            end
            
            % Pass binary ROI to roi_definition and notify parent class
            obj.roi_definition(roi);
            notify(obj,'ROIDefined');
            
            % Add ROI binary mask to record
            obj.add_to_record();
        end
        
        function roi_definition(obj,roi)
        %ROI_DEFINITION Defines a binary ROI mask and draws its outline on
        %the image.
        % Function creates a binary mask of the ROI, adds it to the overall
        % binary image mask, draws its outline on the image axes, deletes
        % the ROI from the image, and notifies the parent class that an ROI
        % has been defined.
        
            % Create binary ROI mask
            roi_mask = createMask(roi);
            
            % Add binary ROI mask to overall image binary mask
            obj.image_mask_bin(roi_mask) = 1;
            
            % Draw ROI outlines onto the image
            obj.redraw_rois();
            
            % Delete MATLABs ROI from the image_axes
            delete(roi);
            
            % Notify the parent class that an ROI has been defined
            notify(obj,'Status_Update',Events.ActionData('ROI defined.'))
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % AUTO AND MANUAL ROI THRESHOLDING METHODS %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function initialize_manual_threshold(obj,src)
        %INITIALIZE_MANUAL_THRESHOLD Creates a GUI that controls ROI
        %thresholding levels through user input.
        % Function initializes a new manual thresholding interface based on
        % the currently selected thresholding channel. This function
        % handles all three types of ROI manual thresholding: single ROI,
        % a region of ROIs, and all ROIs.
        
            % Ensure 'dragzoom' is disabled
            obj.check_zoom();
            
            % Check ROI threshold channel
            if obj.threshold_selection == 1
                % Threshold based on all channels
                image = rgb2gray(obj.image_mask);
                level = graythresh(image);
            else
                % Threshold based on specific color channel
                image = obj.image_mask(:,:,obj.threshold_selection-1);
                level = graythresh(image);
            end
            
            % Check which tool activated this function
            if strcmp(src.Tag,'single') || strcmp(src.Tag,'multi')
                % Specify a region within which to identify ROIs
                notify(obj,'Status_Update',Events.ActionData('Draw ROI freehand.'))
                roi = drawfreehand(obj.image_axes);
                notify(obj,'Status_Update',Events.ActionData('Double-click to finalize ROI definition.'))
                wait(roi);
                if isempty(roi.Position)
                   notify(obj,'Status_Update',Events.ActionData('ROI creation canceled.'))
                   return; 
                end
                notify(obj,'Status_Update',Events.ActionData('ROI defined. Select threshold level.'))
                src.UserData = createMask(roi);
            end
            
            % Instantiate new manual thresholding interface
            thresh_tool = Interfaces.manual_threshold_interface(level,src);
            
            % Add listeners to new temporary tool
            addlistener(thresh_tool,'Status_Update',@(~,evnt)notify(obj,'Status_Update',evnt));
            addlistener(thresh_tool,'ThresholdChanged',@(src,evnt)obj.manualThreshold(src,evnt));
            
            % Run manual thresholding on the first auto-identified
            % threshold level
            obj.manualThreshold(src,Events.ActionData([thresh_tool.threshold_slider.Value str2double(thresh_tool.pix_val_edit.String)]));
        end
        
        function auto_threshold(obj,src)
        %AUTO_THRESHOLD_SINGLE Automatically identifies a single ROI within
        %a user-specified region based on area.
        % Function waits for user to define the region with a ROI
        % freehand, and then identifies and outlines the ROI with the
        % largest area detectable by the Otsku method.
        
            % Ensure 'dragzoom' is disabled
            obj.check_zoom();
            
            % Extract connectivity value
            connect_val = obj.parent.connectivity;
            
            % Ask for user to create region for identification
            notify(obj,'Status_Update',Events.ActionData('Draw ROI freehand.'))
            roi = drawfreehand(obj.image_axes);
            notify(obj,'Status_Update',Events.ActionData('Double-click to finalize ROI definition.'))
            wait(roi);
            if ~isvalid(roi) || isempty(roi.Position)
               notify(obj,'Status_Update',Events.ActionData('Auto-Threshold ROI canceled.'))
               return; 
            end
            % Set thresholding level based on thresholding channel
            if obj.threshold_selection == 1
                image = rgb2gray(obj.image_mask);
            else
                image = obj.image_mask(:,:,obj.threshold_selection-1);
            end
            
            % Set minimum pixel area to default 50
            pix_val = 50;
            
            % Create ROI binary mask and eliminate the rest of the image
            % except for the ROI
            temp_mask = uint8(createMask(roi));
            image_temp = image.*temp_mask;
            
            % Find ROI extrema and extract min and max x- and y- data
            table_data = regionprops(bwlabel(temp_mask,connect_val),'Extrema'); %#ok<MRPBW> Due to use of connect_val
            x_data = table_data.Extrema(:,1);
            y_data = table_data.Extrema(:,2);
            min_x = floor(min(x_data));
            max_x = ceil(max(x_data));
            min_y = floor(min(y_data));
            max_y = ceil(max(y_data));
            
            % Extract a rectangular section of the image encompassing the
            % ROI and find threshold values based only on that section
            temp_im = image(min_y:max_y,min_x:max_x);
            thresh_level = graythresh(temp_im);
            
            % Create binary mask defining ROI based on calculated threshold
            % value and insert into current mask
            current_mask = imbinarize(image_temp,thresh_level);
            current_mask = bwareaopen(current_mask,pix_val,connect_val);
            current_mask = imfill(current_mask,'holes');
            if strcmp(src.Tag,'single')
                current_mask = bwareafilt(current_mask,1,connect_val);
            end
            obj.image_mask_bin(current_mask) = 1;
            
            % Update image axes with new ROI outline
            obj.redraw_rois(obj.image_mask_bin);
            
            % Notify parent class that an ROI has been defined and add new
            % binary mask to record
            notify(obj,'ROIDefined');
            notify(obj,'Status_Update',Events.ActionData('ROI(s) defined.'))
            obj.add_to_record();
        end
        
        function manualThreshold(obj,src,evnt)
        %MANUALTHRESHOLD Manual threshold interface tool image update
        %function. Activates whenever the threshold value is changed,
        %canceled, or confirmed.
        % Function identifies ROIs based on input thresholding value and
        % minimum pixel area input. Expects the source of function
        % activation to be a manual_threshold_interface object or the
        % analyze.initialize_manual_threshold function. Updates ROIs
        % temporarily until source indicates the ROI selections have been
        % confirmed.
        
            % Ensure 'dragzoom' is disabled.
            obj.check_zoom();
            
            % Extract parent connectivity values
            connect_val = obj.parent.connectivity;
            
            % Extract image color channel for thresholding
            if obj.threshold_selection == 1
                image = rgb2gray(obj.image_mask);
            else
                image = obj.image_mask(:,:,obj.threshold_selection-1);
            end
            
            % Extract passed event thresholding level and min pixel area
            thresh_level = evnt.newValue(1);
            pix_val = evnt.newValue(2);
            
            % Create a temp binary image mask based on manual thresholding
            % type
            if strcmp(src.Tag,'single') || strcmp(src.Tag,'multi')
                temp_mask = uint8(src.UserData);
                image_temp = image.*temp_mask;
                   
                current_mask = imbinarize(image_temp,thresh_level);
            else
                current_mask = imbinarize(image,thresh_level);
            end
            
            % Indicates that the manual interface was closed/canceled
            if thresh_level == -1
                current_mask = obj.image_mask_bin;
            end
            
            current_mask = bwareaopen(current_mask,pix_val,connect_val);
            
            current_mask = imfill(current_mask,'holes');
            
            % Filter all but one ROI if manual type is 'single'
            if strcmp(src.Tag,'single')
                current_mask = bwareafilt(current_mask,1,connect_val);
            end
            
            % Create temporary copy of binary mask, including new temporary
            % ROI outlines
            temp_bin_mask = obj.image_mask_bin;
            temp_bin_mask(current_mask) = 1;
            
            obj.redraw_rois(temp_bin_mask);
            
            % If thresholding was canceled, end function execution
            if thresh_level == -1
               return; 
            end
            
            % Finalize ROI outline temporary or final definition
            if isa(src,'matlab.ui.container.Menu') ~= 1
                if src.confirmed == 1
                    obj.image_mask_bin = temp_bin_mask;
                    notify(obj,'ROIDefined');
                    notify(obj,'Status_Update',Events.ActionData('ROI outlines confirmed.'))
                    obj.add_to_record();
                    return;
                else
                    src.fig_handle.Pointer = 'arrow';
                end                
            end
            notify(obj,'Status_Update',Events.ActionData(['Threshold level set to ' num2str(thresh_level)]))
        end
        
        function redraw_rois(obj, temp_bin_mask)
        %REDRAW_ROIS Redraws all ROI outlines based either on object image
        %binary mask or passed temporary binary mask onto image axes.
        % Function can take either one or none inputs.
        %   1 input  : Redraws ROIs based on current object binary image
        %              mask.
        %   2 inputs : Redraws ROIs based on passed temp_bin_mask binary
        %              image mask.
        
            % Extract parent connectivity value
            connect_val = obj.parent.connectivity;
            if nargin == 1
                temp_bin_mask = obj.image_mask_bin;
            end
            
            % Identify boundaries of ROIs in binary mask image
            structBoundaries = bwboundaries(temp_bin_mask,connect_val);
            
            obj.image_handle = imshow(obj.image_mask,'Parent',obj.image_axes);
            % Plot ROI outlines over image axes
            hold(obj.image_axes,'on')
            for i = 1:length(structBoundaries)
                xy = structBoundaries{i};
                x = xy(:, 2); 
                y = xy(:, 1);
                plot(obj.image_axes,x,y,'w');
            end
            hold(obj.image_axes,'off')
            % Create uint8 image of only ROI outlines
            im = getimage(obj.image_axes);
            [~,~,z] = size(im);
            outlines = zeros(size(im));
            for i = 1:z
                outlines(:,:,i) = bwperim(logical(temp_bin_mask),connect_val).*255;
            end
            obj.image_mask_outlines = uint8(outlines);
            
            % Check if display ROI IDs is on; if so 
            temp_disp = findobj('Tag','disp_ids');
            if strcmp(temp_disp.Checked,'on')
                %Image with cells, outlines, and numbers
                cell_outline_num = im+obj.image_mask_outlines;
                
                %labeling mask
                temp_master_mask = bwlabel(temp_bin_mask,connect_val);
                %getting numerical data
                master_regions = regionprops('table',temp_master_mask,'Centroid');
                counter = 1:1:length(structBoundaries);
                if ~isempty(master_regions)
                    cell_outline_num = insertText(cell_outline_num,...
                        master_regions.Centroid,counter,'FontSize',18,...
                        'TextColor','white','BoxColor','blue');
                end
                obj.image_handle = imshow(cell_outline_num,'Parent',obj.image_axes);
            end
            set(obj.image_axes,{'XLim','YLim'},obj.zoom_limits);
            
            % Instantiate image text overlay for hover options; deleted
            % every imshow, so must reinitialize
            obj.parent.roi_disp_txt = text('Visible','off','Parent',obj.image_axes);
        end
        
        %%%%%%%%%%%%%%%%%%
        % ZOOM FUNCTIONS %
        %%%%%%%%%%%%%%%%%%
        
        function enable_zoom(obj,src,status)
        %ENABLE_ZOOM Turns on or off 'dragzoom' functionality for image
        %axes.
        % This function expects to be called only by the uimenu option
        % 'Zoom'. It can be called either with two or three input
        % arguments:
        %
        %        [obj,src] : the function acts as a zoom switch, turning
        %                    off 'dragzoom' if it is on and turning on 'dragzoom' 
        %                    if it is off. 
        % [obj,src,status] : the function sets 'dragzoom' to the value of
        % 'status'. Status must be either 'on', 'On', 'off' , or 'Off'.
        %
        % DRAGZOOM function from https://www.mathworks.com/matlabcentral/fileexchange/29276-dragzoom-drag-and-zoom-tool
        % IMPORTANT DRAGZOOM NOTE: dragzoom functionality may be limited as
        % the function expects the figure to be in units of 'Pixels' rather
        % than in normalized units. dragzoom was partially edited to
        % workaround this issue, allowing zoom functionality with a mouse
        % scrollwheel, but other issues may arise from this problem.
        
            % Check number of input arguments
            if nargin == 2
                % Set dragzoom status to opposite of menu checked state
                if isa(src,'matlab.ui.container.Menu')
                    if strcmp(src.Checked,'on')
                        src.Checked = 'off';
                        Figure.Functions.dragzoom(obj.image_axes,'off');  
                        obj.fig_handle.Name = obj.fig_title;
                        obj.zoom_limits = get(obj.image_axes,{'XLim','YLim'});
                    else
                        src.Checked = 'on';
                        Figure.Functions.dragzoom(obj.image_axes,'on');
                    end
                else
                   warning('Input source must be a menu item.') 
                end
            else
                % Set dragzoom status to input status
                if strcmp(status,'on') || strcmp(status,'On')
                    src.Checked = status;
                    Figure.Functions.dragzoom(obj.image_axes,'on');                       
                elseif strcmp(status,'off') || strcmp(status,'Off')
                    src.Checked = status;
                    Figure.Functions.dragzoom(obj.image_axes,'off'); 
                    obj.fig_handle.Name = obj.fig_title;
                    obj.zoom_limits = get(obj.image_axes,{'XLim','YLim'});
                else
                    error('Status must be either ''on'', ''On'', ''off'', or ''Off''.');
                end
            end
        end
        
        function check_zoom(obj)
        %CHECK_ZOOM Disables dragzoom.
        % This function disables dragzoom, regardless of the current object
        % state.
        
            % Find and grab the handle to the Zoom menu object
            zoom_menu = findobj('Tag','Zoom Menu');
            
            % Return if Zoom does not exist; otherwise, disable dragzoom
            % and set new zoom limits
            if isempty(zoom_menu)
                return;
            else
               obj.zoom_limits = get(obj.image_axes,{'XLim','YLim'});
               obj.enable_zoom(zoom_menu,'off');
               set(obj.image_axes,{'XLim','YLim'},obj.zoom_limits);
            end
        end
        
        function reset_zoom(obj)
        %RESET_ZOOM Callback function for 'Default View' menu option in the 
        %parent image_analysis class. Sets image_axes to default view.
        % This function resets the image axes limits to its default size. 
           set(obj.image_axes,{'XLim','YLim'},obj.zoom_reset); 
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%
        % DELETE ROI FUNCTION  %
        %%%%%%%%%%%%%%%%%%%%%%%%
        
        function delete_roi(obj,src)
        %DELETE_ROI Callback function for 'Delete ROI', 'Delete Region of ROIs', 
        %and 'Delete All ROIs' menu options in the parent image_analysis class. 
        %Deletes ROIs dependent on selected option.
        % This function deletes ROIs dependent on the menu option which
        % triggered the callback:
        %
        %              Delete ROI: In this case, the program  waits for
        %                          user input to select a point on the 
        %                          image axes and then deletes the ROI 
        %                          around or on the selected point.
        %
        %   Delete Region of ROIs: The program acts much like 'Threshold
        %                          Region of ROIs', and waits for the user
        %                          to draw a freehand region. After
        %                          definition, all ROIs within the region
        %                          are deleted.
        %
        %         Delete All ROIs: The program first asks the user to
        %                          confirm their selection, and then
        %                          deletes all ROIs from the image axes.
            
            % Disable 'dragzoom' if enabled
            obj.check_zoom();
            
            % Extract parent class connectivity value
            connect_val = obj.parent.connectivity;
            
            % Check which menu option triggered the callback
            if strcmp(src.Tag,'single')
                % Wait for user input to select a point on image axes
                notify(obj,'Status_Update',Events.ActionData('Select ROI to delete.'))
                [x,y,button] = ginput(1);
                obj.image_axes.Toolbar.Visible = 'off';
                x = round(x);
                y = round(y);
                
                % If user hit 'Esc', return
                if button == 27; return; end
                
                % If user selects outside of image axes, try again
                while y < 0 || x < 0
                    [x,y,button] = ginput(1);
                    obj.image_axes.Toolbar.Visible = 'off';
                    x = round(x);
                    y = round(y);
                    if button == 27; return; end
                end
                
                % Identify ROI below selection, delete, and redraw
                temp_master_mask = bwlabel(obj.image_mask_bin,connect_val);
                obj.image_mask_bin(temp_master_mask==(temp_master_mask(y,x))) = 0;
                obj.image_handle = imshow(obj.image_handle.CData,'Parent',obj.image_axes);
                set(obj.image_axes,{'XLim','YLim'},obj.zoom_limits);
                obj.redraw_rois();
                status_text = 'ROI deleted.';
                
            elseif strcmp(src.Tag,'multiple')
                % Wait for user to identify a deletion region
                notify(obj,'Status_Update',Events.ActionData('Draw ROI freehand.'))
                roi = drawfreehand(obj.image_axes);
                notify(obj,'Status_Update',Events.ActionData('Double-click to finalize ROI definition.'))
                wait(roi);
                
                % Delete all ROIs within the selected region and redraw
                temp_mask = createMask(roi);
                delete(roi);
                obj.image_mask_bin(temp_mask) = false;
                obj.image_mask_bin = bwareaopen(obj.image_mask_bin,6,connect_val);
                obj.image_handle = imshow(obj.image_handle.CData,'Parent',obj.image_axes);
                set(obj.image_axes,{'XLim','YLim'},obj.zoom_limits);
                obj.redraw_rois();
                status_text = 'Region of ROIs deleted.';
                
            elseif strcmp(src.Tag,'all')
               % Request confirmation from the user
               answer = questdlg('Delete all ROIs?','Remove All',...
               'Yes','Cancel','Cancel');
                
               % Return if user cancels
               if isempty(answer) || strcmp(answer,'Cancel'); return; end
                
                % Delete all ROIs if user confirms
                obj.image_mask_bin = false(size(obj.image_mask_bin));
                obj.image_handle = imshow(obj.image_handle.CData,'Parent',obj.image_axes);
                set(obj.image_axes,{'XLim','YLim'},obj.zoom_limits);
                status_text = 'All ROIs deleted.';
            else
               return; 
            end
            
            % Recreate roi_disp_txt object as imshow deletes axes objects
            obj.parent.roi_disp_txt = text('Visible','off','Parent',obj.image_axes);
            
            % Notify parent class that deletions were completed, and add
            % new binary mask to record
            notify(obj,'Status_Update',Events.ActionData(status_text))
            notify(obj,'ROIDefined')
            obj.add_to_record();
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%
        % SPLIT ROI FUNCTIONS %
        %%%%%%%%%%%%%%%%%%%%%%%
        
        function split_roi(obj)
        %SPLIT_ROI Callback function for 'Split ROI' menu option in the parent 
        %image_analysis class. Splits an ROI if freehand is drawn through
        %one.
        % This function splits ROIs if drawn through one or multiple ROIs
        % and does nothing if drawn through no ROIs.
        
            % Disable 'dragzoom' if enabled
            obj.check_zoom();
            
            % Extract parent class connectivity value
            connect_val = obj.parent.connectivity;
            notify(obj,'Status_Update',Events.ActionData('Draw a line between the ROIs you would like to separate.'))
            % Create splitter ROI freehand
            roi_line_split = drawfreehand(obj.image_axes,'Closed',false);
            notify(obj,'Status_Update',Events.ActionData('Double-click to finalize split.'))
            wait(roi_line_split);
            c = roi_line_split.Position;
            delete(roi_line_split);
            if isempty(c)
                return;
            end
            
            % Identify where line and defined cells overlap
            cells = bwlabel(obj.image_mask_bin,connect_val);
            old_cells = cells;
            origc = zeros(size(cells)); % pixels where drawn line and defined cells overlap
            
            % Loop through each pixel in the ROI splitter freehand and
            % create a new binary image eliminating every '1' in that
            % region from the binary mask
            for ii=1:(size(c,1)-1)
                a=c(ii+[0 1],1:2);
                dx=diff(a(:,1));
                dy=diff(a(:,2));
                if(dx==0)
                    if(dy>0)
                        ang=pi/2;
                    else
                        ang=-pi/2;
                    end
                else
                    ang = atan(abs(dy/dx));
                    if(dx<0 && dy<0)
                        ang=ang+pi;
                    end
                    if(dx<0 && dy>=0)
                        ang=pi-ang;
                    end
                    if(dx>0 && dy<0)
                        ang = -ang;
                    end
                end
                L=sqrt(dx^2+dy^2);
                v=[linspace(0,L,20); zeros(1,20)];
                x=[cos(ang) -sin(ang); sin(ang) cos(ang)]; 
                v1=x*v;
                v1(1,:)=v1(1,:)+a(1,1);
                v1(2,:)=v1(2,:)+a(1,2);
                v1=v1';
                v1=round(v1);

                % Set pixels v1 in CELLS to zero, but remember what the original values
                % were
                for jj=1:size(v1,1)
                    y = v1(jj,2);
                    x = v1(jj,1);
                    if(cells(y,x)>0 && ...
                            x > 0 && x <=size(cells,2) ...
                            && y > 0 && y <=size(cells,1))

                        cells(y,x) = 0;
                        cells(y,x+1) = 0;
                        cells(y,x-1) = 0;
                        origc(y,x)=old_cells(y,x);
                        origc(y,x+1)=old_cells(y,x+1);
                        origc(y,x-1)=old_cells(y,x-1);

                    end
                end
            end
            
            % Recognize which cells were really split (those that were only touched by
            % the line but not split remain unchanged)

            ucells=setdiff(unique(cells),0);
            VCELLS=zeros(size(cells));
            new_cell = 0;
            if length(ucells)<1

                for ii=1:length(ucells)
                    ind=find(cells==ucells(ii));
                    p1=zeros(size(cells));
                    p1(ind)=ones(size(ind));
                    p2=bwlabel(p1,connect_val);

                    if(length(unique(p2))>2)
                        VCELLS(ind)=max(VCELLS(:))+p2(ind);
                        notify(obj,'Status_Update',Events.ActionData('ROI split successfully.'))
                        new_cell = 1;
                    else
                        ind=find(old_cells==ucells(ii));
                        p1=zeros(size(old_cells));
                        p1(ind)=ones(size(ind));
                        VCELLS(ind)=max(VCELLS(:))+p1(ind);
                    end

                end
            else
                % If there are more then 9 cells the new and old number of cells are compared
                % instead of checking each indidvidual cell for a change to save time

                p1 = logical(cells);
                VCELLS = bwlabel(p1,connect_val);

                old_cells = length(setdiff(sort(unique(old_cells)),0));
                new_cells = length(setdiff(sort(unique(VCELLS)),0));
                if old_cells == new_cells
                    notify(obj,'Status_Update',Events.ActionData('No new ROIs detected. Please try again; zooming in might help.'))
                else
                    notify(obj,'Status_Update',Events.ActionData('ROI split successfully.'))
                end
                %so message is not repeated this is set to 1
                new_cell = 1;
            end
            if new_cell==0
                notify(obj,'Status_Update',Events.ActionData('No split ROI detected. Please try again; zooming in might help.'))
            end

            cells=VCELLS;

            % Removes pixels 5 or less from the mask 
            obj.image_mask_bin = bwareaopen(logical(cells),6,connect_val);

            % Redraws outlines and adds new binary mask to record
            obj.image_handle = imshow(obj.image_handle.CData,'Parent',obj.image_axes);
            set(obj.image_axes,{'XLim','YLim'},obj.zoom_limits);
            obj.redraw_rois();
            notify(obj,'ROIDefined');
            obj.add_to_record();
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % MIN/MAX AREA CHANGED FUNCTIONS %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function area_changed(obj,src)
        %AREA_CHANGED Callback function for the pixel area edit text boxes 
        %in the partner class roi_stats. Redraws ROIs based on new minimum
        %and maximum pixel area values.
        % This function redefines listed and displayed ROIs based on new
        % pixel area ROI values.
        
            % Disable 'dragzoom' if it is enabled
            obj.check_zoom();
            
            % Extract pixel area ranges
            range = [str2double(src.min_pixel_edit.String) str2double(src.max_pixel_edit.String)];
            
            % Filter existing ROIs based on input area values and redraw
            if ~obj.image_mask_bin
                src.min_pixel_edit.String = '';
                src.max_pixel_edit.String = '';
                return;
            end
            
            if any(isnan(range))
                area = obj.parent.roi_stats_tool.table_data.Area;
                min_max = [min(area) max(area)];
                range(isnan(range)) = min_max(isnan(range));
            end
            
            obj.image_mask_bin = bwareafilt(obj.image_mask_bin,range,obj.parent.connectivity);
            obj.image_handle = imshow(obj.image_handle.CData,'Parent',obj.image_axes);
            set(obj.image_axes,{'XLim','YLim'},obj.zoom_limits);
            obj.redraw_rois();
            
            % Notify parent class that ROIs have been redefined and add new
            % binary mask to record
            notify(obj,'ROIDefined');
            obj.add_to_record();
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % RECORD OF ROIS and UNDO ROI %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function add_to_record(obj)
        %ADD_TO_RECORD Adds current binary mask to image mask record.
        % This function adds the current image binary mask to the record of
        % image binary masks for use in the 'undo_roi' and 'redo_roi' callback.
        
           
           % Truncate edited ROI mask list to current mask
           if ~isempty(obj.image_edited)
               obj.image_edited = obj.image_edited(1:obj.mask_indx);
               obj.id_edited = obj.id_edited(1:obj.mask_indx);
           end
           
           % Add binary mask to end of record
           obj.image_edited{end+1} = obj.image_mask_bin;
           obj.id_edited{end+1} = obj.parent.roi_id;
           obj.mask_indx = length(obj.image_edited);
           if length(obj.image_edited) > 1
               temp = findobj('Tag','UndoROI');
               temp.Enable = 'on';
           end
           temp = findobj('Tag','RedoROI');
           temp.Enable = 'off';
           
           % Change autosaved ROI mask to new mask unless mask is
           % completely empty
           if nnz(obj.image_mask_bin) > 0
               obj.autosave_roi();
           end
           
           % Check if any ROIs exist
           obj.check_identify();
        end
        
        function undo_roi(obj)
        %UNDO_ROI Returns ROI mask to previous ROI mask.
        % This function resets and redraws the binary ROI mask to the
        % previous binary mask.
        
            % Check that an ROI mask exists
            if length(obj.image_edited) <= 1
                return;
            else
                % Set ROI mask to previous mask
                obj.last_id_mask = obj.image_edited{obj.mask_indx};
                obj.mask_indx = obj.mask_indx - 1;
                obj.image_mask_bin = obj.image_edited{obj.mask_indx};
                obj.parent.roi_id = obj.id_edited{obj.mask_indx};
                
                if length(obj.image_edited) <= 1
                   temp = findobj('Tag','UndoROI');
                   temp.Enable = 'off';
                end
                temp = findobj('Tag','RedoROI');
                temp.Enable = 'on';
            end
            % Redraw ROIs
            obj.image_handle = imshow(obj.image_handle.CData,'Parent',obj.image_axes);
            set(obj.image_axes,{'XLim','YLim'},obj.zoom_limits);
            obj.redraw_rois();
            obj.autosave_roi();
            notify(obj,'ROIDefined');
            obj.check_identify();
            notify(obj,'Status_Update',Events.ActionData('Last ROI loaded.'))
        end
        
        function redo_roi(obj)
        %REDO_ROI Returns ROI mask to one forward of the current ROI mask.
        % This function resets and redraws the binary ROI mask to the
        % most recent binary mask.
        
            % Check that the mask isn't already the most current; should
            % not ever be the case, but just in case
            if obj.image_mask_bin == obj.image_edited{end}
                temp = findobj('Tag','RedoROI');
                temp.Enable = 'off';
                return;
            else
                % Find where in the mask list we are and set the mask to
                % one forward of the current position
                obj.last_id_mask = obj.image_edited{obj.mask_indx};
                obj.mask_indx = obj.mask_indx + 1;
                obj.image_mask_bin = obj.image_edited{obj.mask_indx};
                obj.parent.roi_id = obj.id_edited{obj.mask_indx};
                if obj.mask_indx == length(obj.image_edited)
                    temp = findobj('Tag','RedoROI');
                    temp.Enable = 'off';
                end
            end
            
            
            % Redraw ROIs
            obj.image_handle = imshow(obj.image_handle.CData,'Parent',obj.image_axes);
            set(obj.image_axes,{'XLim','YLim'},obj.zoom_limits);
            obj.redraw_rois();
            obj.autosave_roi();
            notify(obj,'ROIDefined');
            obj.check_identify();
            notify(obj,'Status_Update',Events.ActionData('Previous ROI loaded.'))
        end
        
        function autosave_roi(obj)
        %AUTOSAVE_ROI Saves the current binary image mask in the selected
        %output directory under a program-specific name.
        % This function saves the current binary image mask in the default
        % output directory under the default image name with a
        % program-specific 'autosaved_mask' ending. The program will search
        % for this name specifically when the user tries to load an
        % autosaved mask.
            
           % Set mask filepath
           fp = [obj.parent.output_dir.edit.String obj.parent.image_name];
           fp = regexprep(fp,'\.[a-zA-Z]+','_autosaved_mask.mat');
           
           % Save binary image mask
           temp_bin_mask = obj.image_mask_bin; 
           if ~isempty(obj.parent.roi_id)
            temp_roi_id = obj.parent.roi_id;
            save(fp,'temp_bin_mask','temp_roi_id');   
           else
            save(fp,'temp_bin_mask');
           end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % ENABLE/UPDATE ROI IDENTIFICATION %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function check_identify(obj)
        %CHECK_IDENTIFY Checks that at least one ROI exists and
        %enables/disables menu option 'Identify ROIs' accordingly
        
            % Find 'Identify ROI' submenu item
            temp_menu = findobj('Tag','identify');
            temp_save_menu = findobj('Tag','Save_IDs');
            temp_clear_id = findobj('Tag','identify_clear');
                
            % Check that at least one ROI exists; if not, disable 'Identify
            % ROI' menu
            roi_id = obj.parent.roi_id;
            if ~nnz(obj.image_mask_bin)
                temp_menu.Enable = 'off';
                temp_save_menu.Enable = 'off';
                temp_clear_id.Enable = 'off';
                roi_id = [];
            else
                temp_menu.Enable = 'on';
                temp_save_menu.Enable = 'on';
                if ~isempty(roi_id) && ~isempty(obj.last_id_mask)
                    temp_clear_id.Enable = 'on';
                    curr_stats = obj.parent.roi_stats_tool.table_data.Centroid;
                    temp_mask = bwlabel(obj.last_id_mask,obj.parent.connectivity);
                    prev_stats = regionprops('table',temp_mask,'Centroid');
                    prev_stats = prev_stats.Centroid;
                    
                    [prev_row,~] = size(prev_stats);
                    [curr_row,~] = size(curr_stats);
                    
                    temp_id = cell([1 curr_row]);
                    temp_id(:) = {'Undefined'};
                        
                    for i = 1:curr_row
                        curr_centr = curr_stats(i,:);
                        for ii = 1:prev_row
                            if curr_centr==prev_stats(ii,:)
                                temp_id(i) = roi_id(ii);
                                break;
                            end
                        end
                    end
                    roi_id = temp_id;
                    obj.last_id_mask = obj.image_mask_bin; % update last id'd mask with current mask
                end
            end
            
            obj.parent.roi_id = roi_id;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        % DELETE/REFRESH ANALYSIS %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function delete(obj)
        %DELETE Deletes image axes properties and hidden listeners, then
        %removes object completely.
        % Employed when loading new images during the same session and when
        % closing the program completely.
        
            % If axes exist, turn off dragzoom, reset zoom limits of image,
            % clear the axes, and delete them
            if isvalid(obj.image_axes)
                obj.check_zoom();
                obj.reset_zoom();
                cla(obj.image_axes);
                delete(obj.image_axes);
            end
            
            % Iterate through attached listeners, if any, and remove them
            % to avoid listener stacking
            for i = 1:numel(obj.AutoListeners__)
                delete(obj.AutoListeners__{i}); %#ok<MCNPN> AutoListeners is an undocumented property
            end
            delete(obj);
        end
        
    end
    
end

