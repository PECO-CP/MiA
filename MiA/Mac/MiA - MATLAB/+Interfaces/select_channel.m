classdef select_channel < handle
%SELECT_CHANNEL Secondary MATLAB tool; child of image_analysis 
% parent class
%      SELECT_CHANNEL creates a new SELECT_CHANNEL class object instance 
%      within the parent class or creates a nonfunctional GUI representation.
%
%      H = SELECT_CHANNEL returns the handle to a new SELECT_CHANNEL tool, 
%      displaying GUI interfaces and handling input values relevant to 
%      defining color channels for selected image.
% 
%      This class was constructed to operate solely with the properties and 
%      objects of parent class analyze in package Interfaces.
% 
%      This class can be run on its own; in that case, it is a nonfunctional 
%      representation of the graphic objects inherent in this class. This 
%      is primarily used for troubleshooting and preview purposes.

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
        % Analyze class objects
        analyze_tool = [];          % handle to parent Interfaces.analyze class
        
        % Class graphic properties
        fig_handle = [];            % handle to class figure within blank_figure object
        panel_handle = [];          % handle to uipanel within class figure
        blank = [];                 % handle to class blank_figure
        channel_select_panel = [];  % handle to uipanel holding dropdowns for channel names
        channel_name_panel = [];    % handle to uipanel holding dropdowns for channel color selection
        done = [];                  % handle to uicontrol 'Done' signifying channel and channel color selection is complete
        cancel = [];                % handle to uicontrol 'Cancel' signifying that channel selection was not completed
        
        % Channel selection values
        channel_name_1 = [];        % handle to channel 1 name dropdown selection
        channel_name_2 = [];        % handle to channel 2 name dropdown selection
        channel_name_3 = [];        % handle to channel 3 name dropdown selection
        channel_name_1_label = [];  % handle to channel 1 name dropdown label
        channel_name_2_label = [];  % handle to channel 2 name dropdown label
        channel_name_3_label = [];  % handle to channel 3 name dropdown label
        channel_color_1 = [];       % handle to channel 1 color dropdown label
        channel_color_2 = [];       % handle to channel 2 color dropdown label
        channel_color_3 = [];       % handle to channel 3 color dropdown label
        channel_selection = [];     % double array holding color selection for each channel in the order channels were selected
    end
    
    events
       ChannelsSelected     % ChannelsSelected event, indicating the user has finished selecting the color channels for a CZI or grayscale image.
       Status_Update        % Status_Update event, indicating an event has occurred significant enough to display to the user
    end
    
    methods
        function obj = select_channel(channel_names,color_order)
        %SELECT_CHANNEL Build function for the select_channel object.
        % Creates a channel selection user interface. Allows the user to
        % select color channels for non-RGB images. Expects input
        % 'channel_names' to be a cell array of character/string values. If
        % not input is given, assumes three blank grayscale images instead.
        
            % Create figure interface
            obj.blank = Figure.blank_figure();
            obj.fig_handle = obj.blank.fig_handle;
            obj.panel_handle = obj.blank.panel_handle;
            obj.fig_handle.Visible = 'off';
            obj.fig_handle.Name = 'Channel Select';
            obj.fig_handle.Tag = 'Channel Select Tool';
            
            % Set Graphic constants
            btnWidth = 0.10;
            btnHeight = 0.10;
            dropWidth = 0.80;
            dropHeight = 0.12;
            X = 0.01;
            Y = 0.01;
            fontsize = 12;
            
            cancel_pos = [1-btnWidth-X Y btnWidth btnHeight];
            done_pos = [cancel_pos(1)-X-btnWidth Y btnWidth btnHeight];
            panel_Y = done_pos(2)+done_pos(4) + Y;
            spacing = 17*Y;
            channel_select_panel_pos = [0 panel_Y 0.75 1-panel_Y];
            channel_name_panel_pos = [channel_select_panel_pos(3) panel_Y 1-channel_select_panel_pos(3) 1-panel_Y];
            
            channel_name_1_label_pos = [X 1-spacing-dropHeight btnWidth dropHeight];
            channel_name_2_label_pos = [X channel_name_1_label_pos(2)-dropHeight-spacing btnWidth dropHeight];
            channel_name_3_label_pos = [X channel_name_2_label_pos(2)-dropHeight-spacing btnWidth dropHeight];
            
            newX = channel_name_1_label_pos(1) + channel_name_1_label_pos(3) + X;
            channel_name_1_pos = [newX channel_name_1_label_pos(2) dropWidth dropHeight];
            channel_name_2_pos = [newX channel_name_2_label_pos(2) dropWidth dropHeight];
            channel_name_3_pos = [newX channel_name_3_label_pos(2) dropWidth dropHeight];
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % BUILD DROPDOWN & CHANNEL SELECTION PANELS %
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % Check if user gave channel names
            if nargin == 0
               channel_names = {'Grayscale 1'; 'Grayscale 2'; 'Grayscale 3'};
               
            % Check that user gave a cell array
            elseif ~iscell(channel_names)
                error('Input must be cell array of string or character vectors.')
            else
                % Check that each value in the cell array is a string or
                % character vector
                for i = 1:length(channel_names)
                   if ~isstring(channel_names{i}) && ~ischar(channel_names{i})
                       error('Input must be cell array of string or character vectors.')
                   end
                end
            end
            
            % Check if channel names is a filepath; if so, reduce to
            % filename
            
            for i = 1:length(channel_names)
                new_name = regexp(channel_names{i},'([^\\/]+)(?!\\/)','tokens');
                if ~isempty(new_name)
                   channel_names{i} = new_name{end}{1}; 
                end
            end
            
            % Check that three channel names were given; if not, pad the
            % array
            if length(channel_names) < 3
                while length(channel_names) < 3
                   channel_names{end+1} = ['Grayscale ' num2str(3-length(channel_names))]; 
                end
            end
            
            if nargin == 0 || nargin == 1
               color_order = [1 2 3]; 
            end
            
            channel_colors = {'Red';'Green';'Blue'};
            
            obj.done = uicontrol(obj.panel_handle,'Style','pushbutton',...
                'String','Done','Callback',@(~,~)obj.ready(),'Units','normalized',...
                'Position',done_pos);
            obj.cancel = uicontrol(obj.panel_handle,'Style','pushbutton',...
                'String','Cancel','Callback',@(~,~)obj.exit(),'Units','normalized',...
                'Position',cancel_pos);
            
            obj.channel_name_panel = uipanel(obj.panel_handle,'Units',...
                'normalized','Position',channel_select_panel_pos,'Title',...
                'Loaded channels/images');
            obj.channel_select_panel = uipanel(obj.panel_handle,'Units',...
                'normalized','Position',channel_name_panel_pos,'Title',...
                'Color Channel');
            
            obj.channel_name_1_label = uicontrol(obj.channel_name_panel,'Style',...
                'text','Units','normalized','Position',channel_name_1_label_pos,...
                'String','1','FontSize',fontsize);
            obj.channel_name_2_label = uicontrol(obj.channel_name_panel,'Style',...
                'text','Units','normalized','Position',channel_name_2_label_pos,...
                'String','2','FontSize',fontsize);
            obj.channel_name_3_label = uicontrol(obj.channel_name_panel,'Style',...
                'text','Units','normalized','Position',channel_name_3_label_pos,...
                'String','3','FontSize',fontsize);
            
            obj.channel_name_1 = uicontrol(obj.channel_name_panel,'Style',...
                'popupmenu','Units','normalized','Position',channel_name_1_pos,...
                'String',channel_names,'Value',1);
            obj.channel_name_2 = uicontrol(obj.channel_name_panel,'Style',...
                'popupmenu','Units','normalized','Position',channel_name_2_pos,...
                'String',channel_names,'Value',2);
            obj.channel_name_3 = uicontrol(obj.channel_name_panel,'Style',...
                'popupmenu','Units','normalized','Position',channel_name_3_pos,...
                'String',channel_names,'Value',3);
            
            obj.channel_color_1 = uicontrol(obj.channel_select_panel,'Style',...
                'popupmenu','Units','normalized','Position',channel_name_1_pos,...
                'String',channel_colors,'Value',color_order(1));
            obj.channel_color_2 = uicontrol(obj.channel_select_panel,'Style',...
                'popupmenu','Units','normalized','Position',channel_name_2_pos,...
                'String',channel_colors,'Value',color_order(2));
            obj.channel_color_3 = uicontrol(obj.channel_select_panel,'Style',...
                'popupmenu','Units','normalized','Position',channel_name_3_pos,...
                'String',channel_colors,'Value',color_order(3));
            
            % Resize figure and enable visibility
            obj.fig_handle.Position(3) = 0.35;
            obj.fig_handle.Position(4) = 0.25;
            obj.fig_handle.Visible = 'on';
            
            % Set custom close request function
            obj.fig_handle.CloseRequestFcn = @(~,~)obj.exit();
        end
        
        
        function obj = ready(obj)
        %READY Callback function for the 'Done' pushbutton.
        % Function activates when user indicates that they have selected
        % color channels for three input channels. Notifies 'Status_Update' 
        % and 'ChannelsSelected' event listeners.
        
            % Collect channel and color values
            channel_vals = [obj.channel_name_1.Value obj.channel_name_2.Value obj.channel_name_3.Value];
            channel_color_vals = [obj.channel_color_1.Value obj.channel_color_2.Value obj.channel_color_3.Value];
            
            % Ensure the user selected unique channels
            if length(channel_vals) ~= length(unique(channel_vals))
                notify(obj,'Status_Update',Events.ActionData('Must select unique channels'));
                return;
            end
            
            % Ensure the user selected  unique color channels
            if length(channel_color_vals) ~= length(unique(channel_color_vals))
                notify(obj,'Status_Update',Events.ActionData('Must select unique color channels'));
                return;
            end
            
            % Initialize channel selection array
            obj.channel_selection = zeros(1,3);
            
            % Set channel selection properties
            obj.channel_selection(channel_vals(1)) = channel_color_vals(1);
            obj.channel_selection(channel_vals(2)) = channel_color_vals(2);
            obj.channel_selection(channel_vals(3)) = channel_color_vals(3);
            
            % Notify 'Status_Update' and 'ChannelsSelected' event listeners
            notify(obj,'Status_Update',Events.ActionData('Channels Selected'));
            pause(0.1);
            notify(obj,'ChannelsSelected',Events.ActionData(obj.channel_selection))
            
            % Remove figure
            delete(obj.fig_handle);
        end
        
        function obj = exit(obj)
        %EXIT Callback function for the 'Cancel' pushbutton and figure
        %close.
        % Function activates when user indicates that they have canceled
        % image channel selection or choose to close the figure.
            
            % Reset status
            notify(obj,'ChannelsSelected',Events.ActionData(-1))
            notify(obj,'Status_Update',Events.ActionData('Ready to Load Image'));
            
            % Delete figure
            delete(obj.fig_handle);
        end
        
    end
    
    
    
    
    
end
