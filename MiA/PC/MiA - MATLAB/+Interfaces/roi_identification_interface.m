classdef roi_identification_interface < handle
%ROI_IDENTIFICATION_INTERFACE Supplementary GUI subclass; creates customized MATLAB
%figure intended for use with image_analysis.
%
%      ROI_IDENTIFICATION_INTERFACE creates a new CUSTOM_QUESTDLG class object 
%      instance.
%
%      H = ROI_IDENTIFICATION_INTERFACE returns the handle to a new ROI_IDENTIFICATION_INTERFACE tool, 
%      displaying GUI interfaces and handling input values relevant to 
%      identifying ROIs. It also supports and holds the
%      properties of parent Figure object 'blank_figure'.
% 
%      Object properties question and panel_handle can be extracted from
%      this class and modified just as a MATLAB figure or uipanel could be.
%      The object property 'status_bar', if activated, holds the status_bar
%      object which can be sent status updates as usual.

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
        % Parent Graphics
        blank_fig = [];                 % handle to Figure.blank_fig graphics object
        blank_panel = [];               % handle to panel within blank_fig graphics object
        roi_designation_panel = [];     % handle to subpanel within blank_panel for adding/removing ROI designations
        identify_roi_panel = [];        % handle to subpanel within blank_panel for navigating between ROIs and setting designations
        display_roi_panel = [];         % handle to subpanel within blank_panel for displaying a specific ROI
        from_sel = 0;                   % indicates whether the interface was called from start or selection

        % 'Available ROI Designations' Panel Graphics
        roi_designation_list = [];      % handle to ROI designation listbox for displaying available ROI types
        roi_designation_add = [];       % handle to 'Add' pushbutton
        roi_designation_remove = [];    % handle to 'Remove' pushbutton
        roi_designation_upload = [];    % handle to 'Upload' pushbutton
        
        % 'Identify ROI' Panel Graphics
        identify_roi_selection = [];    % handle to uicontrol popupmenu for designation assignment to ROI
        identify_roi_area = [];         % handle to text display for ROI area in pixels
        identify_roi_position = [];     % handle to text display for ROI centroid position in pixels
        identify_roi_major_axis = [];   % handle to text display for ROI major axis length in pixels
        identify_roi_minor_axis = [];   % handle to text display for ROI minor axis length in pixels
        identify_roi_next = [];         % handle to 'Next ROI' pushbutton
        identify_roi_previous = [];     % handle to 'Previous ROI' pushbutton
        identify_roi_cancel = [];       % handle to 'Cancel' pushbutton
        last_used_btn = [];             % handle to uibutton for 'Last Used' radiobutton
        sel_desig_btn = [];             % handle to uibutton for 'selected designation' radiobutton
        next_roi_default = [];          % handle to dropdown indicating selected designation
        
        % Image Panel Graphics
        image_axes = [];                % handle to image display axes
        image_handle = [];              % handle to displayed image
        roi_id = 1;                     % indicates ROI #; default is 1
        roi_id_display = [];            % handle to text edit box for ROI ID #
        zoom_out = 0;                   % handle to zoom decrease value text edit box
        zoom_out_val = 0;               % zoom decrease value; default is 0
        
        % Tool Handles
        parent_handle = [];             % handle to parent image_analysis class object
        analysis_tool = [];             % handle to instance specific analyze class object
        channel_tool = [];              % handle to instance specific channel class object
        roi_master_mask = [];           % label matrix numbering ROIs by region
        num_cells = [];                 % holds the total number of cells
        roi_data = [];                  % table of all ROI data, accessed for displaying ROI statistics
        
        % ROI ID Properties
        roi_types = {'Other'};          % handle to cell string list of ROI designations; default is 'Other'
        last_used = 1;                  % boolean indicating selected default ROI designation; default is true
        
        Tag = 'ROI Identification Interface';   % ROI ID interface class object identifier
    end
    
    methods
        function obj = roi_identification_interface(image_analysis_handle,src,sel_id)
        %ROI_IDENTIFICATION_INTERFACE Construction method for the ROI
        %identification interface.
        % If not given a parent object, creates a nonfunctional
        % representation of the class. Otherwise, creates a full function.
            
            if nargin == 3
               obj.parent_handle = image_analysis_handle;
               obj.zoom_out_val = image_analysis_handle.analysis_tool.last_zoom;
               if strcmp(src.Tag,'from_sel')
                  obj.from_sel = 1;
               end
            elseif nargin == 2 || nargin == 1
               obj.parent_handle = image_analysis_handle;
               obj.zoom_out_val = image_analysis_handle.analysis_tool.last_zoom;
               sel_id = 1; 
            else
               sel_id = 1;
            end
            
            obj.buildFunc(sel_id);
        end
        
        function obj = buildFunc(obj,sel_id)
        %BUILDFUNC Creates graphical interface for ROI identification.
            
            H = Figure.blank_figure();
            obj.blank_fig = H.fig_handle;
            obj.blank_fig.Position(4) = obj.blank_fig.Position(4)+0.1;
            obj.blank_fig.WindowStyle = 'modal';
            obj.blank_panel = H.panel_handle;
            obj.blank_fig.DeleteFcn = @(~,~)obj.exit_function();
            obj.blank_fig.Name = 'ROI Identification';
            obj.blank_fig.WindowKeyPressFcn = @(~,evnt)obj.button_press(evnt);
            
            %%%%%%%%%%%%%%%%%%%%%%%%
            % Create parent panels %
            %%%%%%%%%%%%%%%%%%%%%%%%
            
            identify_height = 0.66;
            designate_height = 1-identify_height;
            
            image_width = 0.65;
            info_width = 1-image_width;
            
            identify_fontsize_title = 0.04;
            designate_fontsize_title = 0.08;
            image_fontsize_title = 0.05-0.024;
            
            identify_fontsize = 0.4;
            designate_fontsize = identify_fontsize;
                        
            obj.identify_roi_panel = uipanel(obj.blank_panel,'Units','normalized',...
                'Position',[0 0 info_width identify_height],'FontUnits','normalized',...
                'FontSize',identify_fontsize_title,'Title','Identify ROI');
            obj.roi_designation_panel = uipanel(obj.blank_panel,'Units','normalized',...
                'Position',[0 identify_height info_width designate_height],...
                'FontUnits','normalized','FontSize',designate_fontsize_title,'Title',...
                'Available ROI Designations');
            obj.display_roi_panel = uipanel(obj.blank_panel,'Units','normalized',...
                'Position',[info_width 0 image_width 1],...
                'FontUnits','normalized','FontSize',image_fontsize_title,'Title',...
                'Image Display');
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Create 'Identify ROI' Panel %
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            btnWidth = 0.31;
            btnHeight = 0.072;
            X = 0.01;
            Y = 0.02;
            
            % Create cancel button
            cancel_X = 0.5-btnWidth/2;
            obj.identify_roi_cancel = uicontrol(obj.identify_roi_panel,'Style',...
                'pushbutton','String','Save & Finish','FontUnits','normalized',...
                'FontSize',identify_fontsize,'Units','normalized',...
                'Position',[cancel_X Y btnWidth btnHeight],'Callback',...
                @(~,~)obj.exit_function());
           
            % Create 'Previous ROI' button
            newY = obj.identify_roi_cancel.Position(4) + Y;
            obj.identify_roi_previous = uicontrol(obj.identify_roi_panel,'Style',...
                'pushbutton','String','<< Previous ROI','FontUnits','normalized',...
                'FontSize',identify_fontsize,'Units','normalized',...
                'Position',[X newY btnWidth btnHeight],'Callback',...
                @(src,~)obj.iterate_ROI(src),'Enable','off','Tag','Previous ROI');
            
            % Create 'Next ROI' button
            newX = 1-btnWidth-X;
            obj.identify_roi_next = uicontrol(obj.identify_roi_panel,'Style',...
                'pushbutton','String','Next ROI >>','FontUnits','normalized',...
                'FontSize',identify_fontsize,'Units','normalized',...
                'Position',[newX newY btnWidth btnHeight],'Callback',...
                @(src,~)obj.iterate_ROI(src),'Tag','Next ROI');
            
            statWidth = 0.3;
            
            % Create minor axis length display
            newX = (1-statWidth*2-X)/2;
            newY = newY + btnHeight + Y;
            uicontrol(obj.identify_roi_panel,'Style','text','FontUnits',...
                'normalized','Units','normalized','FontSize',identify_fontsize,...
                'Position',[newX newY statWidth btnHeight],'String',...
                'Minor Axis Length');
            
            newX1 = newX + statWidth + X;
            obj.identify_roi_minor_axis = uicontrol(obj.identify_roi_panel,...
                'Style','text','FontUnits','normalized','Units','normalized',...
                'FontSize',identify_fontsize,'Position',[newX1 newY statWidth btnHeight],'String',...
                '0');
            
            % Create major axis length display
            newY = newY + btnHeight + Y;
            uicontrol(obj.identify_roi_panel,'Style','text','FontUnits',...
                'normalized','Units','normalized','FontSize',identify_fontsize,...
                'Position',[newX newY statWidth btnHeight],'String',...
                'Major Axis Length');
            
            obj.identify_roi_major_axis = uicontrol(obj.identify_roi_panel,...
                'Style','text','FontUnits','normalized','Units','normalized',...
                'FontSize',identify_fontsize,'Position',[newX1 newY statWidth btnHeight],'String',...
                '0');
            
            % Create coordinate position display
            newY = newY + btnHeight + Y;
            uicontrol(obj.identify_roi_panel,'Style','text','FontUnits',...
                'normalized','Units','normalized','FontSize',identify_fontsize,...
                'Position',[newX newY statWidth btnHeight],'String',...
                'Position (x,y)');
            
            obj.identify_roi_position = uicontrol(obj.identify_roi_panel,...
                'Style','text','FontUnits','normalized','Units','normalized',...
                'FontSize',identify_fontsize,'Position',[newX1 newY statWidth btnHeight],'String',...
                '0');
            
            % Create Area display
            newY = newY + btnHeight + Y;
            uicontrol(obj.identify_roi_panel,'Style','text','FontUnits',...
                'normalized','Units','normalized','FontSize',identify_fontsize,...
                'Position',[newX newY statWidth btnHeight],'String',...
                'Area');
            
            obj.identify_roi_area = uicontrol(obj.identify_roi_panel,...
                'Style','text','FontUnits','normalized','Units','normalized',...
                'FontSize',identify_fontsize,'Position',[newX1 newY statWidth btnHeight],'String',...
                '0');
            
            % Create Selection text display and dropdown
            newY = newY + btnHeight + Y;
            uicontrol(obj.identify_roi_panel,'Style','text','FontUnits',...
                'normalized','Units','normalized','FontSize',identify_fontsize,...
                'Position',[newX newY statWidth btnHeight],'String',...
                'Select ROI Type');
            newY = newY + 0.02;
            obj.identify_roi_selection = uicontrol(obj.identify_roi_panel,...
                'Style','popupmenu','FontUnits','normalized','Units','normalized',...
                'FontSize',identify_fontsize,'Position',[newX1 newY statWidth btnHeight],...
                'String',obj.roi_types);
                        
            % Create ROI # display
            newY = newY + btnHeight + Y;
            uicontrol(obj.identify_roi_panel,'Style','text','FontUnits',...
                'normalized','Units','normalized','FontSize',identify_fontsize,...
                'Position',[newX newY statWidth btnHeight],'String',...
                'Displayed ROI #: ');
            newY = newY + 0.02;
            obj.roi_id_display = uicontrol(obj.identify_roi_panel,'Style','edit','FontUnits',...
                'normalized','Units','normalized','FontSize',identify_fontsize,...
                'Position',[newX1 newY statWidth btnHeight],'String',...
                '1','Callback',@(src,~)obj.iterate_ROI(src),'Tag','ROI ID');
            
            % Create Zoom Out display
            newY = newY + btnHeight + Y;
            uicontrol(obj.identify_roi_panel,'Style','text','FontUnits',...
                'normalized','Units','normalized','FontSize',identify_fontsize,...
                'Position',[newX newY statWidth btnHeight],'String',...
                'Zoom out (pixels): ');
            newY = newY + 0.02;
            obj.zoom_out = uicontrol(obj.identify_roi_panel,'Style','edit','FontUnits',...
                'normalized','Units','normalized','FontSize',identify_fontsize,...
                'Position',[newX1 newY statWidth btnHeight],'String',...
                num2str(obj.zoom_out_val),'Callback',@(~,~)obj.display_ROI_and_stats(obj.roi_id));
            
            % Create default designation display
            newY = newY + btnHeight + Y;
            radioWidth = 0.25;
            sel_desig_width = 0.05;
            tempX = (1-(statWidth+radioWidth+sel_desig_width+3*X+statWidth))/2;
            uicontrol(obj.identify_roi_panel,'Style','text','FontUnits',...
                'normalized','Units','normalized','FontSize',identify_fontsize,...
                'Position',[tempX newY statWidth btnHeight],'String',...
                'Next ROI default:');
            newY = newY + 0.02;
            newX = tempX + X + statWidth;
            obj.last_used_btn = uicontrol(obj.identify_roi_panel,'Style','radiobutton','FontUnits',...
                'normalized','Units','normalized','FontSize',identify_fontsize,...
                'Position',[newX newY radioWidth btnHeight],'String','Last Used',...
                'Callback',@(src,~)obj.default_designation(src),'Tag','last','Value',1);
            newX = newX + radioWidth + X;
            obj.sel_desig_btn = uicontrol(obj.identify_roi_panel,'Style','radiobutton','FontUnits',...
                'normalized','Units','normalized','FontSize',identify_fontsize,...
                'Position',[newX newY sel_desig_width btnHeight],'String','',...
                'Callback',@(src,~)obj.default_designation(src),'Tag','selected');
            newX = newX + sel_desig_width + X;
            obj.next_roi_default = uicontrol(obj.identify_roi_panel,...
                'Style','popupmenu','FontUnits','normalized','Units','normalized',...
                'FontSize',identify_fontsize,'Position',[newX newY-0.005 statWidth btnHeight],...
                'String',obj.roi_types);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Create 'Set ROI Designations' Panel %
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            upBtnWidth = 0.5;
            btnHeight = 0.15;
            listHeight = 1-3*btnHeight-4*Y;
            listWidth = upBtnWidth + 4*X;
            add_rmv_Width = listWidth/2 - 2*X;
            list_fontsize = designate_fontsize - 0.2;
            Y = 0.05;
            
            % Create 'Upload' button
            upload_X = 0.5-upBtnWidth/2;
            obj.roi_designation_upload = uicontrol(obj.roi_designation_panel,'Style',...
                'pushbutton','String','Upload ROI Types (.txt or .csv)','FontUnits','normalized',...
                'FontSize',designate_fontsize,'Units','normalized',...
                'Position',[upload_X Y upBtnWidth btnHeight],'Callback',...
                @(~,~)obj.upload_roi_types());
            
            % Create 'Add' button
            newY = 2*Y + btnHeight;
            newX = obj.roi_designation_upload.Position(1)-2*X;
            obj.roi_designation_add = uicontrol(obj.roi_designation_panel,'Style',...
                'pushbutton','String','Add','FontUnits','normalized',...
                'FontSize',designate_fontsize,'Units','normalized',...
                'Position',[newX newY add_rmv_Width btnHeight],'Callback',...
                @(~,~)obj.add_roi_types());
            
            % Create 'Remove' button
            newX = newX + add_rmv_Width + 4*X;
            obj.roi_designation_remove = uicontrol(obj.roi_designation_panel,'Style',...
                'pushbutton','String','Remove','FontUnits','normalized',...
                'FontSize',designate_fontsize,'Units','normalized',...
                'Position',[newX newY add_rmv_Width btnHeight],'Callback',...
                @(~,~)obj.remove_roi_types());
            
            % Create designation listbox
            newY = newY + btnHeight + Y;
            obj.roi_designation_list = uicontrol(obj.roi_designation_panel,'Style',...
                'listbox','String',obj.roi_types,'FontUnits','normalized',...
                'FontSize',list_fontsize,'Units','normalized',...
                'Position',[obj.roi_designation_add.Position(1) newY listWidth listHeight]);
            
            % Create image axes
            obj.image_axes = axes(obj.display_roi_panel,'Units','normalized',...
                'Position',[0 0 1 1],'Visible','off');
            obj.image_axes.Toolbar.Visible = 'off';
            
            obj.blank_fig.Position = [0.3 0.3 obj.blank_fig.Position(3) obj.blank_fig.Position(4)];
            
            parent = obj.parent_handle;
            
            % If given parent, assumed to be image_analysis object. Extract
            % requisite information for ROI identification
            if ~isempty(parent)
                obj.image_handle = getimage(parent.analysis_tool.image_axes) + parent.analysis_tool.image_mask_outlines;
                master_mask = parent.analysis_tool.image_mask_bin;
                connect_val = parent.connectivity;
                obj.roi_master_mask = bwlabel(master_mask,connect_val);
                obj.roi_data = regionprops('table',obj.roi_master_mask,'Area', 'Centroid', 'MajorAxisLength', 'MinorAxisLength','Extrema');
                obj.num_cells = height(obj.roi_data);
                if isempty(parent.roi_id)
                    parent.roi_id = cell([1 obj.num_cells]);
                    parent.roi_id(:) = {'Undefined'}; 
                else
                    obj.roi_types = obj.parent_handle.analysis_tool.roi_types;
                    obj.roi_designation_list.String = obj.roi_types;
                    obj.identify_roi_selection.String = obj.roi_types;
                    obj.next_roi_default.String = obj.roi_types;
                    obj.next_roi_default.Value = length(obj.roi_types);
                    if parent.roi_id_next_default
                        % Indicates 'Next ROI Default' was enabled on last
                        % load
                        obj.last_used_btn.Value = 0; % Disable Last Used
                        obj.last_used = 0; % indicate class-wide not Last Used
                        obj.sel_desig_btn.Value = 1; % Enable Next ROI Default
                        obj.next_roi_default.Value = parent.roi_id_next_default_val;
                    end
                    % Insert code here for enabling/disabling Last Used or
                    % Next ROI Default, and for setting the default

                    % Set the current selection to the ROI designation it
                    % was last on
                    if sel_id <= length(parent.roi_id)
                        % Due to introduction of 'Other' and 'Undefined'
                        % as separate categories, must compare 'Undefined' to 'Other'
                        % to return valid Value for ROI ID. Otherwise,
                        % compare as normal.
                        if strcmp(parent.roi_id(sel_id),'Undefined')
                            obj.identify_roi_selection.Value = find(strcmp('Other',obj.roi_types));
                        else 
                            obj.identify_roi_selection.Value = find(strcmp(parent.roi_id(sel_id),obj.roi_types));
                        end
                    end
                end
                obj.roi_id_display.String = num2str(sel_id);
                obj.iterate_ROI(obj.roi_id_display);
                if obj.num_cells == 1; obj.identify_roi_next.String = 'Finish'; obj.identify_roi_next.Tag = 'Finish'; end
            end
        end
        
        function default_designation(obj,src)
        % DEFAULT_DESIGNATION Sets boolean property to indicate which
        % designation to default to when going to an Undefined ROI.
            if strcmp('last',src.Tag)
                obj.last_used = 1;
                obj.sel_desig_btn.Value = 0;
            else
                obj.last_used = 0;
                obj.last_used_btn.Value = 0;
            end
        end
        
        function obj = button_press(obj,evnt)
        %BUTTON_PRESS Figure button callback; performs specific hotkey
        %actions depending on button pressed.
        % This function allows the user to iterate through ROIs via the
        % 'Enter' key and to switch between ROI designations using keyboard
        % numeric inputs.
        
            key = evnt.Key;
            
            % Check that user isn't editing the ROI number; if so, return
            if (isa(obj.blank_fig.CurrentObject,'matlab.ui.control.UIControl') && strcmp(obj.blank_fig.CurrentObject.Style,'edit')) || isempty(evnt.Character)
                return;
            end
            % Matches either 0-9 or 0-9 on the number pad
            temp = regexp(key,'(^[1-9])|numpad([1-9])','tokens');
            if ~isempty(temp)
                key = str2double(temp{1}{1});
                if key > length(obj.identify_roi_selection.String)
                    key = length(obj.identify_roi_selection.String);
                end
                obj.identify_roi_selection.Value = key;
            elseif strcmp(key,'return')
                obj.iterate_ROI(obj.identify_roi_next);
            end
        end
        
        function obj = exit_function(obj)
        %EXIT_FUNCTION Primary ROI ID tool exit function.
        % If a parent object is present, update the ROI ID property of the
        % parent with changes made. Additionally, update the most recent
        % binary mask used for identification for centroid comparison (used
        % when reordering ROIs and for identifying which designations
        % belong to which ROI) and saves uploaded ROI designations for
        % future uses of the tool. Then deletes figure.
        
           if ~isempty(obj.parent_handle)
            obj.parent_handle.roi_id(obj.roi_id) = obj.roi_types(obj.identify_roi_selection.Value);
            obj.parent_handle.analysis_tool.last_id_mask = obj.parent_handle.analysis_tool.image_mask_bin;
            obj.parent_handle.analysis_tool.roi_types = obj.roi_types;
            obj.parent_handle.analysis_tool.last_zoom = obj.zoom_out_val;
            obj.parent_handle.analysis_tool.id_edited{obj.parent_handle.analysis_tool.mask_indx} = obj.parent_handle.roi_id;
            obj.parent_handle.roi_id_next_default = obj.sel_desig_btn.Value; % if Next Default is 1, set to 1 for next load
            obj.parent_handle.roi_id_next_default_val = obj.next_roi_default.Value; % save next default value for next load
                    
            temp_clear_id = findobj('Tag','identify_clear');
            temp_clear_id.Enable = 'on';
            notify(obj.parent_handle,'Status_Update',Events.ActionData('ROI identification complete.'))
           end
           delete(obj.blank_fig);
        end
        
        function obj = iterate_ROI(obj,src)
        %ITERATE_ROI Changes graphical elements related to iterating through
        % ROIs and updates displayed ROI and statistics.
        % Depending on source input, switches to the next, previous, or
        % numerically defined ROI. Then passes new ROI number to update
        % display and stats function.
           
           % Put ROI identification in its place in array
           % Added if statement to patch error in which starting from
           % selection caused the first ROI to lose its ID
           if ~obj.from_sel
              obj.parent_handle.roi_id(obj.roi_id) = obj.identify_roi_selection.String(obj.identify_roi_selection.Value);
           else
              obj.from_sel = 0;
           end
           % Check source of activation, either previous, next, or finished
           if contains(src.Tag,'Previous')
               % Previous-specific button function
               
               % Change ROI ID
                obj.roi_id = obj.roi_id - 1;
                
                % If initial ROI, disable 'Previous' button
                if obj.roi_id == 1
                    src.Enable = 'off';
                end
                
                % If initial ROI was final ROI, String will be 'Finish'. Update
                % to say 'Next ROI >>'
                if ~contains(obj.identify_roi_next.String,'Next')
                    obj.identify_roi_next.String = 'Next ROI >>';
                    obj.identify_roi_next.Tag = 'Next ROI >>';
                end
           elseif contains(src.Tag,'Next')
               % Next-specific button function
               
               % Change ROI ID
                obj.roi_id = obj.roi_id + 1;
                
                % If current ROI is final ROI, change String to 'Finish'
                if obj.num_cells == obj.roi_id
                    src.String = 'Finish'; 
                    src.Tag = 'Finish';
                end
                obj.identify_roi_previous.Enable = 'on';
           elseif contains(src.Tag,'ID')
               % If edit box was used, chance 'id' is not a valid number;
                % check
                id = src.String;
                id = str2double(id);
                if isnan(id); obj.roi_id_display.String = num2str(obj.roi_id); return; end

                if id < 1
                    id = 1;
                elseif id > obj.num_cells
                    id = obj.num_cells;
                end
                
                 % If initial ROI, disable 'Previous' button
                if id == 1
                    obj.identify_roi_previous.Enable = 'off';
                else
                    obj.identify_roi_previous.Enable = 'on';
                end
                
                % If initial ROI was final ROI, String will be 'Finish'. Update
                % to say 'Next ROI >>'
                if ~contains(obj.identify_roi_next.String,'Next')
                    obj.identify_roi_next.String = 'Next ROI >>';
                    obj.identify_roi_next.Tag = 'Next ROI >>';
                end
                
                % If current ROI is final ROI, change String to 'Finish'
                if obj.num_cells == id
                    obj.identify_roi_next.String = 'Finish'; 
                    obj.identify_roi_next.Tag = 'Finish'; 
                end
                
                obj.roi_id = id;
           else
               obj.exit_function();
               return;
           end
           
           % Update displayed ROI ID
            obj.roi_id_display.String = num2str(obj.roi_id); 
            
            % Display new ROI %
            obj.display_ROI_and_stats(obj.roi_id);
        end
        
        function obj = display_ROI_and_stats(obj,id)
        %DISPLAY_ROI_AND_STATS This function displays the ROI and
        %statistics associated with ROI ID 'id'.
        % Checks the previous ROI ID to include in designation selection if
        % not in the general designation list. Then updates statistics of
        % ROI and displays zoomed preview.
        
            if ~isempty(obj.parent_handle.roi_id)
                prev_id = obj.parent_handle.roi_id(id);
                if ~strcmp(prev_id,'Undefined')
                    logi = strcmp(prev_id,obj.roi_types);
                    if ~any(logi)
                        temp_types = [prev_id obj.roi_types];
                        obj.identify_roi_selection.String = temp_types;
                        obj.identify_roi_selection.Value = 1;
                    else
                        obj.identify_roi_selection.String = obj.roi_types;
                        obj.identify_roi_selection.Value = find(logi==1);
                    end
                else
                    obj.identify_roi_selection.String = obj.roi_types;
                    if ~obj.last_used
                       obj.identify_roi_selection.Value = obj.next_roi_default.Value;
                    end
                end
            end
            
            %%%%%% Display Statistics %%%%%%
            obj.identify_roi_area.String = num2str(table2array(obj.roi_data(id,1)));
            center = round(table2array(obj.roi_data(id,2)),2);
            obj.identify_roi_position.String = ['(' num2str(center(1)) ',' num2str(center(2)) ')'];
            obj.identify_roi_major_axis.String = num2str(table2array(obj.roi_data(id,3)));
            obj.identify_roi_minor_axis.String = num2str(table2array(obj.roi_data(id,4)));
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            if isnan(str2double(obj.zoom_out.String))
               obj.zoom_out.String = num2str(obj.zoom_out_val); 
            else
               obj.zoom_out_val = str2double(obj.zoom_out.String); 
            end
            
            %%%%%% Display ROI
            colors = obj.image_handle;
            zoom_out_value = obj.zoom_out_val;
            m = obj.roi_data.Extrema(id);
            
            matrixm = m{1};
            Xvalues = matrixm(:,1);
            Yvalues = matrixm(:,2);
            
            Xrange_val = (ceil(min(Xvalues))-zoom_out_value):(ceil(max(Xvalues))+zoom_out_value);
            Yrange_val = (ceil(min(Yvalues))-zoom_out_value):(ceil(max(Yvalues))+zoom_out_value);

            Xrange_val = Xrange_val(Xrange_val > 0);
            Yrange_val = Yrange_val(Yrange_val > 0);
            [y_max_length,x_max_length,~] = size(colors);
            Xrange_val = Xrange_val(Xrange_val <= x_max_length);
            Yrange_val = Yrange_val(Yrange_val <= y_max_length);
            
            ROI = obj.image_handle(Yrange_val,Xrange_val,:);
            
            % Update parent figure to same ROI as is being ID'd for quick
            % edits and reference
            set(obj.parent_handle.analysis_tool.image_axes,...
                {'XLim','YLim'},{[Xrange_val(1) Xrange_val(end)],...
                [Yrange_val(1) Yrange_val(end)]});
            obj.parent_handle.analysis_tool.zoom_limits = get(obj.parent_handle.analysis_tool.image_axes,...
                {'XLim','YLim'});
            
            imshow(ROI,'Parent',obj.image_axes);
            %%%%%%%%%%%%%%%
        end
        
        function obj = upload_roi_types(obj)
        %UPLOAD_ROI_TYPES Function for interpreting uploaded ROI types as
        %either text or .csv (comma delimited) files. 
        % ROI Types in either format MUST be comma delimited to be
        % correctly interpreted. Input can be either as a single row or a
        % single column.
        
            % User selects file
            [file,path,indx] = uigetfile({'*.txt','Text Files (.txt)';...
                '*.csv','CSV Files (.csv)'},'Select ROI Types File');
            filename = fullfile(path, file);
            if indx == 0
               return; 
            end
            % Read data from file
            data = readtable(filename,'Delimiter',',','ReadVariableNames',false,'EndOfLine','\r\n');
            data = table2cell(data);
            
            % If a text file, chance of empty char vectors. Check and
            % remove
            if indx == 1
                data = data(~ismissing(data));
            end
            
            % Check if data is a column vector; if so, transpose
            [row,~] = size(data);
            if row > 1
               data = data'; 
            end
            
            % Update ROI type listbox and dropdown. Always keep the
            % 'Other' option.
            obj.roi_types = [data {'Other'}];
            obj.roi_designation_list.String = obj.roi_types;
            obj.next_roi_default.String = obj.roi_types;
            
            curr_id = obj.parent_handle.roi_id(obj.roi_id);
            if any(strcmp(curr_id,obj.roi_types))
                obj.identify_roi_selection.String = obj.roi_types;
            else
                obj.identify_roi_selection.String = [curr_id; obj.roi_types];
            end
            obj.parent_handle.analysis_tool.roi_types = obj.roi_types;
        end
        
        function obj = remove_roi_types(obj)
        %REMOVE_ROI_TYPES Removes the selected ROI designation from the
        %list. Does not allow the user to remove 'Other' from the
        %selection.
            
          % Extract selection.
          sel = obj.roi_designation_list.Value;
          if strcmp(obj.roi_types(sel),'Other')
              return;
          end
          rmv_id = obj.roi_types(sel);
          
          % Keep all designations except selected ROI type
          obj.roi_types = obj.roi_types(~strcmp(obj.roi_types,rmv_id));
          obj.roi_designation_list.String = obj.roi_types;
          obj.identify_roi_selection.String = obj.identify_roi_selection.String(~strcmp(obj.identify_roi_selection.String,rmv_id));
          obj.next_roi_default.String = obj.next_roi_default.String(~strcmp(obj.next_roi_default.String,rmv_id));
          
          % Update parent with new ROI types list
          obj.parent_handle.analysis_tool.roi_types = obj.roi_types;
          id_sel = obj.identify_roi_selection.Value;
          next_sel = obj.next_roi_default.Value;
          if sel-1 ~= 0
            obj.roi_designation_list.Value = sel - 1;
          elseif isempty(obj.roi_designation_list.String)
            obj.roi_designation_remove.Enable = 'off';
            obj.identify_roi_selection.String = 'Disabled';
            obj.identify_roi_selection.Enable = 'off';
          end
          if id_sel-1 ~= 0
              obj.identify_roi_selection.Value = id_sel - 1;
          end
          if next_sel-1 ~= 0
              obj.next_roi_default.Value = next_sel - 1;
          end
        end
        
        function obj = add_roi_types(obj)
        %ADD_ROI_TYPES Allows the user to manually enter a new ROI
        %designation. 
        % Create temporary inputdlg object for user to enter ROI
        % designation string and updates appropriate properties.
        
            % Create inputdlg
            prompt = {'Enter ROI type designation:'};
            dlgtitle = 'Add ROI Type';
            dims = [1 50];
            answer = inputdlg(prompt,dlgtitle,dims);
            obj.roi_types = [answer obj.roi_types];
            
            % If given an answer, update properties
            if ~isempty(answer)
                obj.roi_designation_list.String = obj.roi_types;
                sel = obj.identify_roi_selection.Value;
                sel2 = obj.next_roi_default.Value;
                obj.identify_roi_selection.String = [answer; obj.identify_roi_selection.String];
                obj.next_roi_default.String = obj.identify_roi_selection.String;
                obj.next_roi_default.Value = sel2 + 1;
                obj.identify_roi_selection.Value = sel+1;
                obj.parent_handle.analysis_tool.roi_types = obj.roi_types;
                obj.identify_roi_selection.Enable = 'on';
            end
        end
    end
end

