classdef bckgrnd_sub_interface < handle
%BCKGRND_SUB_INTERFACE Secondary MATLAB tool; child of image_analysis parent class
%      BCKGRND_SUB_INTERFACE creates a new BCKGRND_SUB_INTERFACE class object 
%      instance within the parent class or creates a nonfunctional GUI representation.
%      Class displays a preview of a selected image channel as well as a
%      background-subtracted preview of that channel. User can switch
%      between channels and apply background subtraction separately to
%      each one. Data is stored in companion class 'analyze.m'
%
%      H = BCKGRND_SUB_INTERFACE returns the handle to a new 
%      BCKGRND_SUB_INTERFACE tool.
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
        parent                              % handle to parent 'image_analysis' class
        analyze_tool = [];                  % handle to current 'analyze.m' tool
        
        % Class graphic objects
        blank_fig = [];                 % handle to 'blank_figure.m' class instance
        fig_handle = [];                % handle to 'blank_figure.m' class instance 'figure'
        panel_handle = [];              % handle to fig_handle's inset primary panel
        status_bar = [];                % handle to fig_handle's inset status bar
        raw_image_panel = [];           % handle to the raw image display panel
        bs_image_panel = [];            % handle to the background subtracted image display panel
        options_panel = [];             % handle to the background subtraction options panel
        channel_list = [];              % handle to the channel selection uicontrol listbox
        strel_list = [];                % handle to the structuring element selection uicontrol listbox
        reset_btn = [];                 % handle to the 'Reset Channel' button
        apply_btn = [];                 % handle to the 'Apply' button
        update_btn = [];                % handle to the 'Update Preview' button
        save_close_btn = [];            % handle to the 'Apply & Close' button
        input_text_2 = [];              % handle to the text description of the second input argument
        input_text_1 = [];              % handle to the text description of the first input argument
        input_edit_2 = [];              % handle to the text edit input box of the second input argument
        input_edit_1 = [];              % handle to the text edit input box of the first input argument
        input_argu_1 = [];              % value of the first input argument
        input_argu_2 = [];              % value of the second input argument
        
        % Image properties
        raw_image_axes = [];            % handle to the raw image display axes
        bs_image_axes = [];             % handle to the background subtracted image display axes
        is_two = [];                    % boolean indicating whether a 
                                        % background subtraction option has one or two input arguments
        bs_mask = [];                   % array of the background subtraction 
                                        % values for the selected channel; units 
                                        % match that of raw and bs images
        bs_image = [];                  % handle to the numeric array representing 
                                        % the background subtracted image
        image_handle_bs = [];           % image object containing the background subtracted image
        reset = 1;                      % boolean indicating whether the most 
                                        % recent action taken was to reset the 
                                        % channel; default on open is true
    end
    
    events
       Status_Update        % custom figure event indicating a change in status
       ChannelChanged       % custom class event indicating to the parent's 
                            % channel tool that a change has been made to a 
                            % selected channel; refreshes primary display
    end
    
    methods
        function obj = bckgrnd_sub_interface(parent)
        %BCKGRND_SUB_INTERFACE Class constructor for the background
        %subtraction interface tool.
        %   Builds the graphical elements of the tool, and then,
        %   depending on number of inputs, attaches the parent image
        %   analysis tool or creates a mainly nonfunctional GUI
        %   representation.
        
            % Build the interface
            obj.buildFnc();
            
            % Attach image analysis tool, if present, and subtool analysis
            if nargin == 1 
                obj.parent = parent;            % Parent image analysis tool
                obj.analyze_tool = parent.analysis_tool;        % 'analyze.m' subtool
                obj.bs_image = obj.analyze_tool.image_unedited; % set current background subtracted image to unedited original image
                obj.channel_changed();          % run channel_changed callback to update images
                bs_menu = findobj('Tag','BS');
                bs_menu.Enable = 'off';         % Don't allow user to open multiple tools
            end
            % Notify user that tool is ready
            notify(obj,'Status_Update',Events.ActionData('Ready'));
        end
        
        function buildFnc(obj)
        %BUILDFNC Builds the graphical elements of the class and sets
        %appropriate callbacks.
        
            % Create initial figure and set figure properties
            obj.blank_fig = Figure.blank_figure(1);
            obj.fig_handle = obj.blank_fig.fig_handle;
            obj.status_bar = obj.blank_fig.status_bar;
            obj.fig_handle.Name = 'Background Subtraction Tool';
            obj.fig_handle.Tag = 'Background Subtraction Tool';
            obj.panel_handle = obj.blank_fig.panel_handle;
            
            addlistener(obj,'Status_Update',@(~,evnt)obj.status_bar.update_status(evnt));
            
            % Create panels within primary panel
            options_height = 0.3;
            raw_image_fontsize = 0.03;
            options_fontsize = 0.07;
            X = 0.02;
            Y = 0.12;
            
            obj.options_panel = uipanel(obj.panel_handle,'Units','normalized',...
                'Position',[0 0 1 options_height],'Title','Background Subtraction Options','FontUnits','normalized',...
                'FontSize',options_fontsize,'FontAngle','italic');
            obj.raw_image_panel = uipanel(obj.panel_handle,'Units','normalized',...
                'Position',[0 options_height 0.5 1-options_height],'Title','Raw Image Display','FontUnits','normalized',...
                'FontSize',raw_image_fontsize,'FontAngle','italic');
            obj.bs_image_panel = uipanel(obj.panel_handle,'Units','normalized',...
                'Position',[0.5 options_height 0.5 1-options_height],'Title','Background-Subtracted Image Preview','FontUnits','normalized',...
                'FontSize',raw_image_fontsize,'FontAngle','italic');
            
            %%%%%%%%%%%%%%%%%%%
            % RAW IMAGE PANEL %
            %%%%%%%%%%%%%%%%%%%
            
            obj.raw_image_axes = axes(obj.raw_image_panel,'Units','normalized',...
                    'Position',[0 0 1 1],'Visible','off','Tag','Raw Image Axes');
            obj.raw_image_axes.Toolbar.Visible = 'off';
            
            %%%%%%%%%%%%%%%%%%
            % BS IMAGE PANEL %
            %%%%%%%%%%%%%%%%%%
            
            obj.bs_image_axes = axes(obj.bs_image_panel,'Units','normalized',...
                    'Position',[0 0 1 1],'Visible','off','Tag','BS Image Axes');
            obj.bs_image_axes.Toolbar.Visible = 'off';
            
            %%%%%%%%%%%%%%%%%
            % OPTIONS PANEL %
            %%%%%%%%%%%%%%%%%
            
            spacing = 0.03;
            btn_width = 0.07;
            btn_height = 0.15;
            btn_fontsize = 0.4;
            list_height = 0.3;
            list_width = (1-3*X-2*spacing)/3;
            list_Y = 2*Y + btn_height;
            list_fontsize = 0.2;
            txt_fontsize = 0.7;
            descr_Y = list_Y + list_height; 
            descr_fontsize = 0.47;
            
            % Listbox of color channels
            obj.channel_list = uicontrol(obj.options_panel,'Style','listbox','String',{'Red','Green','Blue'},...
               'Units','normalized','Position',[X list_Y list_width list_height],...
               'FontUnits','normalized','FontSize',list_fontsize,'Callback',@(~,~)obj.channel_changed());
            uicontrol(obj.options_panel,'Style','text','String','Channel Selection',...
               'Units','normalized','Position',[X descr_Y list_width btn_height],...
               'FontUnits','normalized','FontSize',descr_fontsize,'FontWeight','bold');
           
            newX = X+list_width+spacing;
            
            % Listbox of background subtraction structuring element options
            obj.strel_list = uicontrol(obj.options_panel,'Style','popupmenu','String',{'Disk','Diamond','Octagon','Line','Rectangle','Square'},...
               'Units','normalized','Position',[newX list_Y list_width list_height],...
               'FontUnits','normalized','FontSize',list_fontsize,'Callback',@(~,~)obj.strel_changed());
            uicontrol(obj.options_panel,'Style','text','String','''Rolling Ball'' Shape Selection',...
               'Units','normalized','Position',[newX descr_Y list_width btn_height],...
               'FontUnits','normalized','FontSize',descr_fontsize,'FontWeight','bold');
           
            newX = newX+list_width+spacing;
            text_height = (list_height-Y)/2;
            text_width = (list_width-X)/2;
            
            obj.input_text_2 = uicontrol(obj.options_panel,'Style','text','String','',...
               'Units','normalized','Position',[newX list_Y text_width text_height],...
               'FontUnits','normalized','FontSize',txt_fontsize,'Visible','off','Enable','off');
            
            newX2 = newX + text_width + X;
           
            obj.input_edit_2 = uicontrol(obj.options_panel,'Style','edit',...
               'Units','normalized','Position',[newX2 list_Y text_width text_height],...
               'FontUnits','normalized','FontSize',txt_fontsize,'Visible','off','Enable','off',...
               'Tag','2','Callback',@(src,~)obj.input_argument_set(src));
            
            newY = list_Y + text_height + Y;
            
            obj.input_text_1 = uicontrol(obj.options_panel,'Style','text','String','',...
               'Units','normalized','Position',[newX newY text_width text_height],...
               'FontUnits','normalized','FontSize',txt_fontsize,'Visible','on','Enable','on');
            obj.input_edit_1 = uicontrol(obj.options_panel,'Style','edit',...
               'Units','normalized','Position',[newX2 newY text_width text_height],...
               'FontUnits','normalized','FontSize',txt_fontsize,'Visible','on','Enable','on',...
               'Tag','1','Callback',@(src,~)obj.input_argument_set(src));
            
           % Reset, Update, and Apply buttons
           
            obj.reset_btn = uicontrol(obj.options_panel,'Style','pushbutton','String','Reset Channel',...
               'Units','normalized','Position',[X Y btn_width btn_height],...
               'FontUnits','normalized','FontSize',btn_fontsize,'Callback',@(~,~)obj.reset_channel());
            
            btn_X3 = newX2 + text_width - btn_width;
            btn_X2 = btn_X3 - X - btn_width;
            btn_X1 = btn_X2 - X - btn_width;
            
            obj.update_btn = uicontrol(obj.options_panel,'Style','pushbutton','String','Update Preview',...
               'Units','normalized','Position',[btn_X3 Y btn_width btn_height],...
               'FontUnits','normalized','FontSize',btn_fontsize,'Callback',@(src,~)obj.apply_close(src));
            
            obj.apply_btn = uicontrol(obj.options_panel,'Style','pushbutton','String','Apply',...
               'Units','normalized','Position',[btn_X2 Y btn_width btn_height],...
               'FontUnits','normalized','FontSize',btn_fontsize,'Callback',@(src,~)obj.apply_close(src),...
               'Tag','Apply');
            
            obj.save_close_btn = uicontrol(obj.options_panel,'Style','pushbutton','String','Apply & Close',...
               'Units','normalized','Position',[btn_X1 Y btn_width btn_height],...
               'FontUnits','normalized','FontSize',btn_fontsize,'Callback',@(src,~)obj.apply_close(src),...
               'Tag','Apply & Close');
            
           
            % Reset figure size to 'full' position
            obj.fig_handle.Position = [0.05 0.1 0.8 0.7];
            
            % Set figure close callback
            obj.fig_handle.CloseRequestFcn = @(~,~)obj.close();
            
            obj.strel_changed(); % Update input argument display
        end
 
        %%%%%%%%%%%%%
        % CALLBACKS %
        %%%%%%%%%%%%%
        
        function channel_changed(obj)
        %CHANNEL_CHANGED Updates displayed images when selected channel has
        %been changed.
        
            % Grab selected channel; 1 = Red, 2 = Blue, 3 = Green
            channel_slice = obj.analyze_tool.image_unedited(:,:,obj.channel_list.Value);
            
            % Normalize unedited channel for display
            temp_slice = double(channel_slice);
            temp_slice = temp_slice - min(temp_slice(:));
            temp_slice = temp_slice / max(temp_slice(:));
            temp_slice = im2uint8(temp_slice);
            
            % Display raw channel image
            imshow(temp_slice,'Parent',obj.raw_image_axes)
            
            % Grab any preexisting background subtraction mask
            obj.bs_mask = obj.analyze_tool.bs_arr(:,:,obj.channel_list.Value);
            
            % Create background subtracted image
            obj.bs_image = channel_slice-obj.bs_mask;
            
            % Update user on status
            notify(obj,'Status_Update',Events.ActionData(['Channel changed to ''' obj.channel_list.String{obj.channel_list.Value} '''']));
           
            % Update preview
            obj.update_prev();
        end
        
        function err_code = input_argument_set(obj,src)
        %INPUT_ARGUMENT_SET Checks and sets given inputs with regard to
        %selected background type
        
            input = str2double(src.String);
            
            err_code = 1;
            
            strel_string = obj.strel_list.String{obj.strel_list.Value};
            switch strel_string
                case 'Octagon'
                    % First nonnegative integers
                    if strcmp(src.Tag,'1')
                        if isnan(input) || input < 0 || mod(input,1) ~= 0 % Check if NaN, negative, or fractional
                            notify(obj,'Status_Update',Events.ActionData('First input must be a nonnegative integer.'))
                            src.String = '';
                            return;
                        end
                    else
                    % Second must be nonnegative multiple of 3
                        if isnan(input) || input < 0 || mod(input,3) ~= 0 % Check if NaN, negative, or not multiple of 3
                            notify(obj,'Status_Update',Events.ActionData('Second input must be a nonnegative multiple of 3.'))
                            src.String = '';
                            return;
                        end
                    end
                case 'Line'
                    % First Length must be nonnegative integer
                    if strcmp(src.Tag,'1')
                        if isnan(input) || input < 0 || mod(input,1) ~= 0 % Check if NaN, negative, or fractional
                            notify(obj,'Status_Update',Events.ActionData('First input must be a nonnegative integer.'))
                            src.String = '';
                            return;
                        end
                    else
                    % Second angle must be numeric
                        if isnan(input) % Check if NaN
                            notify(obj,'Status_Update',Events.ActionData('Second input must be numeric.'))
                            src.String = '';
                            return;
                        end
                    end
                case 'Disk'
                    % First Length must be nonnegative integer
                    if strcmp(src.Tag,'1')
                        if isnan(input) || input < 0 || mod(input,1) ~= 0 % Check if NaN, negative, or fractional
                            notify(obj,'Status_Update',Events.ActionData('First input must be a nonnegative integer.'))
                            src.String = '';
                            return;
                        end
                    else
                    % Second angle must be nonnegative integer
                        if isempty(src.String)
                            % specifically for the second argument of disk,
                            % which is optional, String can be empty
                            obj.is_two = 0;
                        elseif isnan(input) || input < 0 || ~any(input==[0 4 6 8]) % Check if NaN, negative, or not multiple of 2
                            notify(obj,'Status_Update',Events.ActionData('Optional: second input must be 0, 4, 6, or 8'))
                            src.String = '';
                            obj.is_two = 0;
                            return;
                        else
                            obj.is_two = 1; % valid input; allow it to go through
                        end
                    end
                case {'Rectangle','Square','Diamond'}
                    % All remaining inputs must only be nonnegative integers
                    if isnan(input) || input < 0 || mod(input,1) ~= 0 % Check if NaN, negative, or fractional
                        notify(obj,'Status_Update',Events.ActionData('Input must be a nonnegative integer.'))
                        src.String = '';
                        return;
                    end
            end 
            
            % Account for Rectangle special case; two inputs, one argument
            if strcmp(src.Tag,'1')
                if strcmp(strel_string,'Rectangle')
                    obj.input_argu_1(1) = input;
                else
                    obj.input_argu_1 = input;
                end
            else
                if strcmp(strel_string,'Rectangle')
                    obj.input_argu_1(2) = input;
                else
                    obj.input_argu_2 = input;
                end
            end
            
            err_code = 0;
            obj.reset = 0;
            
        end
        
        function strel_changed(obj)
        %STREL_CHANGED Callback for when background subtraction shape changes.
        % Changes displayed valid input arguements depending on chosen shape and
        % updates their description.
        
            % Grab strel shape name; 'Disk', 'Diamond', etc..
            strel_string = obj.strel_list.String{obj.strel_list.Value};
            
            % Reset input argument values
            obj.input_edit_2.Tooltip = '';
            obj.input_edit_1.Tooltip = '';
            obj.input_argu_1 = [];
            obj.input_argu_2 = [];
            
            % Switch-case changing input arguement descriptions based on new
            % selected strel shape
            switch strel_string
                case 'Diamond'
                    obj.is_two = 0; % only one input argument
                    obj.input_text_1.String = 'Dist. from Origin to Diamond Points';
                    set([obj.input_text_2;obj.input_edit_2],{'Visible','Enable'},{'off','off';'off','off'});
                case 'Disk'
                    obj.is_two = 1; % two potential input arguments
                    obj.input_text_1.String = 'Disk Radius';
                    obj.input_text_2.String = '# of Lines for Disk Approx.';
                    obj.input_text_2.Tooltip = 'Specify the number of linear structuring elements used to approximate a disk shape. Check the manual for greater detail.';
                    obj.input_edit_2.Tooltip = 'Optional: second input must be 0, 4, 6, or 8';
                    set([obj.input_text_2;obj.input_edit_2],{'Visible','Enable'},{'on','on';'on','on'});
                case 'Octagon'
                    obj.is_two = 0; % one required input
                    obj.input_text_1.String = 'Dist. from Origin to Octagon Sides';
                    obj.input_edit_1.Tooltip = 'Must be a nonnegative multiple of 3';
                    set([obj.input_text_2;obj.input_edit_2],{'Visible','Enable'},{'off','off';'off','off'});
                case 'Line'
                    obj.is_two = 1; % two required inputs
                    obj.input_text_1.String = 'Linear Element Length';
                    obj.input_text_2.String = 'Linear Element Angle (deg)';
                    obj.input_edit_2.Tooltip = 'Angle is measured in counterclockwise degrees from east';
                    set([obj.input_text_2;obj.input_edit_2],{'Visible','Enable'},{'on','on';'on','on'});
                case 'Rectangle'
                    obj.is_two = 0; % one required input
                    obj.input_argu_1 = [0 0]; % special case rectangle input
                    obj.input_text_1.String = '# Rows (pixels)';
                    obj.input_text_2.String = '# Columns (pixels)';
                    set([obj.input_text_2;obj.input_edit_2],{'Visible','Enable'},{'on','on';'on','on'});
                case 'Square'
                    obj.is_two = 0; % one required input
                    obj.input_text_1.String = 'Side Length (pixels)';
                    set([obj.input_text_2;obj.input_edit_2],{'Visible','Enable'},{'off','off';'off','off'});
            end
            % Update user strel shape was changed successfully
            notify(obj,'Status_Update',Events.ActionData(['Structuring element changed to ''' strel_string '''']));        
        end
        
        function update_prev(obj)
        %UPDATE_PREV Updates the displayed background subtraction preview
            
            % Normalize current background subtracted image for display
            temp_bs_image = double(obj.bs_image);
            temp_bs_image = temp_bs_image - min(temp_bs_image(:));
            temp_bs_image = temp_bs_image / max(temp_bs_image(:));
            temp_bs_image = im2uint8(temp_bs_image);
            
            % Display background subtracted image
            obj.image_handle_bs = imshow(temp_bs_image,'Parent',obj.bs_image_axes);
            
            % Update user
            notify(obj,'Status_Update',Events.ActionData('Preview updated successfully.'));
        end
        
        function reset_channel(obj)
        %RESET_CHANNEL Removes background subtraction from the selected
        %channel.
        % Removes any background subtraction on the selected channel and
        % updates the preview accordingly
        
            obj.reset = 1; % indicate most recent action was channel reset
            obj.bs_mask = uint16(zeros(size(obj.bs_image))); % set background subtraction mask to zeros
            obj.bs_image = obj.analyze_tool.image_unedited(:,:,obj.channel_list.Value); % set background subtraction image to original image
            
            % Redisplay background subtracted image
            obj.update_prev();
            
            % Empty inputs
            obj.input_edit_1.String = '';
            obj.input_edit_2.String = '';
            
            % Update user
            notify(obj,'Status_Update',Events.ActionData([obj.channel_list.String{obj.channel_list.Value} ' channel reset successfully.']));
        end
        
        function apply_close(obj,src)
        %APPLY_CLOSE Applies background subtraction and closes figure.
        % Performs background subtraction method on selected channel,
        % updates displayed preview, and depending on source, closes the
        % figure.
        
            % If most recent action was an image reset, skip checking
            % inputs and performing background subtraction
            if ~obj.reset
                % In case it was not caught, run input argument checks again
                % Check argument 2, if needed
                if strcmp(obj.input_edit_2.Enable,'on')
                    err_code = obj.input_argument_set(obj.input_edit_2);
                    if err_code; return; end
                end

                % Check argument 1, if needed
                err_code = obj.input_argument_set(obj.input_edit_1);
                if err_code; return; end
            
                % Perform background subtraction and update the preview
                obj.bckgrndSubtraction();
                obj.update_prev();
            end
            
            % Set analyze background subtracted mask property of
            % appropriate channel
            if contains(src.Tag,'Apply')
                obj.analyze_tool.bs_arr(:,:,obj.channel_list.Value) = obj.bs_mask;
                
                obj.analyze_tool.bs_shapes{obj.channel_list.Value} = obj.strel_list.String{obj.strel_list.Value};
                obj.analyze_tool.bs_input_parameters{obj.channel_list.Value} = [obj.input_argu_1 obj.input_argu_2]; 
                
                % Act as though channel tool has sent a swap command; updates
                % primary mask with bs_arr and redisplays
                notify(obj,'Status_Update',Events.ActionData('Background subtraction applied successfully.'));
                obj.parent.channel_tool.UserData = 'Channel_Changed';
                notify(obj.parent.channel_tool,'ChannelChanged')
            end
            
            % If 'Apply & Close', close the figure
            if contains(src.Tag,'Close')
                obj.close();
            end
        end
        
        function close(obj)
        %CLOSE Closes figure and deletes object.
            notify(obj,'Status_Update',Events.ActionData('Closing...'));
            bs_menu = findobj('Tag','BS');
            if ~isempty(bs_menu)
                bs_menu.Enable = 'on';
            end
            delete(obj.fig_handle);
            delete(obj);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%
        % BACKGROUND SUBTRACTION %
        %%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function bckgrndSubtraction(obj)
        %BCKGRNDSUBTRACTION Performs background subtraction on selected
        %channel with selected morphological opening type.
            
            % Notify user system is busy
            obj.fig_handle.Pointer = 'watch';
            pause(0.1); % force GUI to update
            
            notify(obj,'Status_Update',Events.ActionData('Performing background subtraction...'));

            % Grab background subtraction type
            bs_type = lower(obj.strel_list.String{obj.strel_list.Value});
            
            image_unedited = obj.analyze_tool.image_unedited;
            channel_slice = image_unedited(:,:,obj.channel_list.Value);
            
            % Check if BS type requires two inputs and morphologically open
            % as needed
            if obj.is_two
                obj.bs_mask = imopen(channel_slice,strel(bs_type,obj.input_argu_1,obj.input_argu_2)); 
            else
                obj.bs_mask = imopen(channel_slice,strel(bs_type,obj.input_argu_1)); 
            end
            
            % Create background subtraction image
            obj.bs_image = channel_slice-obj.bs_mask;
            
            % Change pointer back to arrow and update user
            obj.fig_handle.Pointer = 'arrow';
            notify(obj,'Status_Update',Events.ActionData('Background subtraction complete.'));

        end
        
    end
end

