classdef channel < handle
%CHANNEL Secondary MATLAB tool; child of image_analysis parent class
%      CHANNEL creates a new CHANNEL class object instance within the parent 
%      class or creates a nonfunctional GUI representation.
%
%      H = CHANNEL returns the handle to a new CHANNEL tool, displaying GUI
%      interfaces and holding data values relevant to controlling image
%      channels.
% 
%      This class was constructed to operate solely with the properties and 
%      objects of parent class image_analysis and sub classes select_channel
%      and analyze in package Interfaces. This may change in future releases.
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

   properties(Access = public)
       % Parent class objects
       parent = [];                    % parent class handle
       display_tab = [];               % display tab handle
       property_tab = [];              % property tab handle
       image_tab = [];                 % image property tab handle
       
       % Analysis tool object
       analysis_tool = [];             % handle to partner analyze class object
       default_channel_names = [];     % stores initial original channel names, if any
       default_exp_times = [];         % stores initial original channel exposure times, if any
       
       % Red Channel GUI Objects
       red_panel = [];                 % handle to red channel uipanel
       red_property_panel = [];        % handle to red channel property uipanel
       red_channel_plot = [];          % handle to red channel imhist intensity plot
       red_bar_plot = [];              % handle to red channel imhist data
       red_channel_min_slider = [];    % handle to red channel 'min' intensity slider
       red_channel_min_edit = [];      % handle to red channel 'min' intensity text edit box
       red_channel_max_slider = [];    % handle to red channel 'max' intensity slider
       red_channel_max_edit = [];      % handle to red channel 'max' intensity text edit box
       red_min_line = [];              % handle to red channel minimum vertical plot indicator
       red_max_line = [];              % handle to red channel maximum vertical plot indicator
       red_check_box = [];             % handle to red channel enabled check box
       red_channel_name = [];          % handle to current selected red channel
       red_channel_exp = [];           % handle to current red color channel exposure time
       red_channel_editable_name = []; % handle to current red color channel name
       
       % Green Channel GUI Objects
       green_panel = [];               % handle to green channel uipanel
       green_property_panel = [];      % handle to green channel property uipanel
       green_channel_plot = [];        % handle to green channel imhist intensity plot
       green_bar_plot = [];            % handle to green channel imhist data
       green_channel_min_slider = [];  % handle to green channel 'min' intensity slider
       green_channel_min_edit = [];    % handle to green channel 'min' intensity text edit box
       green_channel_max_slider = [];  % handle to green channel 'max' intensity slider
       green_channel_max_edit = [];    % handle to green channel 'max' intensity text edit box
       green_min_line = [];            % handle to green channel minimum vertical plot indicator
       green_max_line = [];            % handle to green channel maximum vertical plot indicator
       green_check_box = [];           % handle to green channel enabled check box
       green_channel_name = [];        % handle to current selected green channel
       green_channel_exp = [];         % handle to current green color channel exposure time
       green_channel_editable_name = []; % handle to current green color channel name
       
       % Blue Channel GUI Objects
       blue_panel = [];                % handle to blue channel uipanel
       blue_property_panel = [];       % handle to blue channel property uipanel
       blue_channel_plot = [];         % handle to green channel imhist intensity plot
       blue_bar_plot = [];             % handle to blue channel imhist data
       blue_channel_min_slider = [];   % handle to green channel 'min' intensity slider
       blue_channel_min_edit = [];     % handle to green channel 'min' intensity text edit box
       blue_channel_max_slider = [];   % handle to green channel 'max' intensity slider
       blue_channel_max_edit = [];     % handle to green channel 'max' intensity text edit box
       blue_min_line = [];             % handle to green channel minimum vertical plot indicator
       blue_max_line = [];             % handle to green channel maximum vertical plot indicator
       blue_check_box = [];            % handle to green channel enabled check box
       blue_channel_name = [];         % handle to current selected blue channel
       blue_channel_exp = [];          % handle to current blue color channel exposure time
       blue_channel_editable_name = [];% handle to current blue color channel name
       
       % Image Prop GUI Objects
       image_panel = [];               % handle to image property uipanel
       image_prop_image = [];          % handle to image property image axes
       image_type_txt = [];            % handle to image type text
       image_filepath_txt = [];        % handle to image location text
       image_bit_depth = [];           % handle to image bit depth text
       image_dimensions = [];          % handle to image dimensions text
       image_file_size = [];           % handle to image file size text
       image_name = [];                % handle to image name textbox
       image_prop_image_dir = [];      % handle to image logo directory
       
       UserData = 'Default';           % handle to user-specified data; changes callback to callback
   end
   
   events
      Status_Update     % Status_Update event, indicating an event has occurred significant enough to display to the user
      SelectionMade     % SelectionMade event, indicating an image(s) has been selected (not used in this class directly; acts as a carrier)
      ChannelChanged    % ChannelChanged event, indicating a channel's contrast has been changed, or a channel has been disabled/enabled.
      ChannelsSelected  % ChannelsSelected event, indicating the user has finished selecting the color channels for a CZI or grayscale image.
   end
   
   methods
       function obj = channel(parent)
        %CHANNEL Creates a new 'Channel' object.
        % This function can be called with one or no arguments. If it is
        % called with no arguments, the function creates a nonfunctional
        % GUI representation. Otherwise, the function expects a parent
        % object of class image_analysis.
        
           % Check number of input arguments
           if nargin == 0
               temp_handle = Figure.blank_figure().fig_handle;
               obj.parent = uitabgroup(temp_handle,'Units','normalized','Position',[0 0 1 1]);
               uitab(obj.parent,'Title','Displayed Properties');
               uitab(obj.parent,'Title','Channel Properties');
               uitab(obj.parent,'Title','Image Properties');
           else
              obj.parent = parent; 
           end
           
           % Run GUI build function
           obj.buildFnc(obj.parent);
       end
       
       function obj = buildFnc(obj,parent)
       %CHANNEL Builds the graphical components of the 'Channel' panel.
       % This function builds the graphical components of the 'Channel'
       % panel into the input argument 'parent'. The purpose of these
       % graphical components is to control image color channel contrast
       % levels for the class image_analysis.
            
           % Set graphical constants
           obj.display_tab = parent.Children(1);
           obj.property_tab = parent.Children(2);
           obj.image_tab = parent.Children(3);
           
           image_side = 0.2;
           X = 0.02;
           Y = 0.02;
           im_offset = 0.035;
           
           panel_height = 1/3;
           min_max_font_size = 0.7;
           enabled_font_size = 0.25;
           slider_width = 0.65;           
           plot_x = 0.06;
           plot_width = slider_width - 2*plot_x;
           enabled_X = plot_x + plot_width +0.01;
           slider_height = 0.1;
           enabled_height = slider_height*2;
           name_exp_text_width = 1-slider_width;
           text_width = name_exp_text_width/2;
           check_text_pos_fix = 0.019;
           check_X = slider_width+text_width;
           enabled_width = check_X - enabled_X;
           
           
           im_label_width = 0.35;
           im_text_width = 1-3*X-im_label_width;
           im_text_x = 2*X+im_label_width;
           im_label_height = 0.025;
           im_text_fontsize = 0.7;
           icon_fontsize = im_text_fontsize-0.2;
           
           % Initialize three uipanels, one for each color channel, in each
           % tab
           obj.blue_panel = uipanel(obj.display_tab,'Units','normalized','Position',...
               [0 0 1 panel_height]);
           obj.blue_property_panel = uipanel(obj.property_tab,'Units','normalized','Position',...
               [0 0 1 panel_height]);
           obj.image_panel = uipanel(obj.image_tab,'Units','normalized','Position',...
               [0 0 1 1]);
           
           newY = obj.blue_panel.Position(2) + obj.blue_panel.Position(4);
           obj.green_panel = uipanel(obj.display_tab,'Units','normalized','Position',...
               [0 newY 1 panel_height]);
           obj.green_property_panel = uipanel(obj.property_tab,'Units','normalized','Position',...
               [0 newY 1 panel_height]);
           
           newY = obj.green_panel.Position(2) + obj.green_panel.Position(4);
           obj.red_panel = uipanel(obj.display_tab,'Units','normalized','Position',...
               [0 newY 1 panel_height]);
           obj.red_property_panel = uipanel(obj.property_tab,'Units','normalized','Position',...
               [0 newY 1 panel_height]);
           
           %%%%%%%%%%%%%%%%%%%%
           % IMAGE PROP PANEL %
           %%%%%%%%%%%%%%%%%%%%
           
           % Extract current filepath
           obj.image_prop_image_dir = mfilename('fullpath');
           indx = strfind(obj.image_prop_image_dir,'+Interfaces') - 1;
           obj.image_prop_image_dir = [obj.image_prop_image_dir(1:indx) '+Figure/'];
           
           % Image icon
           obj.image_prop_image = axes(obj.image_panel,'Units','normalized',...
               'Position',[X 1+im_offset-image_side image_side image_side],'Visible','off');
           obj.image_prop_image.Toolbar.Visible = 'off';
           imshow(imread([obj.image_prop_image_dir 'PlaceHolderImage_72.png']),'Parent',obj.image_prop_image);
           im_name_Y = obj.image_prop_image.Position(2)+obj.image_prop_image.Position(4)/2-im_label_height/2;
           im_temp_X = obj.image_prop_image.Position(1)+obj.image_prop_image.Position(3)+X;
           im_temp_width = 1-im_temp_X;
           im_temp_height = im_label_height+0.01;
           obj.image_name = uicontrol(obj.image_panel,'Style','edit',...
               'String','','Units','normalized','Position',...
               [im_temp_X im_name_Y im_temp_width im_temp_height],'FontUnits',...
               'normalized','FontSize',icon_fontsize,'HorizontalAlignment',...
               'center','Enable','inactive');
           
           % Image type label and textbox
           im_Y = obj.image_prop_image.Position(2) - im_label_height + Y;
           uicontrol(obj.image_panel,'Style','text','String','Image Type:',...
               'Units','normalized','Position',[X im_Y im_label_width im_label_height],...
               'FontUnits','normalized','FontSize',im_text_fontsize,...
               'HorizontalAlignment','left');
           obj.image_type_txt = uicontrol(obj.image_panel,'Style','text',...
               'String','','Units','normalized','Position',...
               [im_text_x im_Y im_text_width im_label_height],'FontUnits',...
               'normalized','FontSize',im_text_fontsize,'HorizontalAlignment',...
               'left');
              
           % Image filepath label and textbox
           im_Y = im_Y - im_label_height - Y;
           uicontrol(obj.image_panel,'Style','text','String','Location:',...
               'Units','normalized','Position',[X im_Y im_label_width im_label_height],...
               'FontUnits','normalized','FontSize',im_text_fontsize,...
               'HorizontalAlignment','left');
           obj.image_filepath_txt = uicontrol(obj.image_panel,'Style','text',...
               'String','','Units','normalized','Position',...
               [im_text_x im_Y im_text_width im_label_height],'FontUnits',...
               'normalized','FontSize',im_text_fontsize,'HorizontalAlignment',...
               'left'); 
           
           % Image bit depth label and textbox
           im_Y = im_Y - im_label_height - Y;
           uicontrol(obj.image_panel,'Style','text','String','Bit Depth:',...
               'Units','normalized','Position',[X im_Y im_label_width im_label_height],...
               'FontUnits','normalized','FontSize',im_text_fontsize,...
               'HorizontalAlignment','left');
           obj.image_bit_depth = uicontrol(obj.image_panel,'Style','text',...
               'String','','Units','normalized','Position',...
               [im_text_x im_Y im_text_width im_label_height],'FontUnits',...
               'normalized','FontSize',im_text_fontsize,'HorizontalAlignment',...
               'left'); 
           
           % Image dimension label and textbox
           im_Y = im_Y - im_label_height - Y;
           uicontrol(obj.image_panel,'Style','text','String','Image Dimensions:',...
               'Units','normalized','Position',[X im_Y im_label_width im_label_height],...
               'FontUnits','normalized','FontSize',im_text_fontsize,...
               'HorizontalAlignment','left');
           obj.image_dimensions = uicontrol(obj.image_panel,'Style','text',...
               'String','','Units','normalized','Position',...
               [im_text_x im_Y im_text_width im_label_height],'FontUnits',...
               'normalized','FontSize',im_text_fontsize,'HorizontalAlignment',...
               'left'); 
           
           % Image file size label and textbox
           im_Y = im_Y - im_label_height - Y;
           uicontrol(obj.image_panel,'Style','text','String','File Size:',...
               'Units','normalized','Position',[X im_Y im_label_width im_label_height],...
               'FontUnits','normalized','FontSize',im_text_fontsize,...
               'HorizontalAlignment','left');
           obj.image_file_size = uicontrol(obj.image_panel,'Style','text',...
               'String','','Units','normalized','Position',...
               [im_text_x im_Y im_text_width im_label_height],'FontUnits',...
               'normalized','FontSize',im_text_fontsize,'HorizontalAlignment',...
               'left'); 
           
           %%%%%%%%%%%%%%%%%%%%
           % BUILD BLUE PANEL %
           %%%%%%%%%%%%%%%%%%%%
           
           % Blue Max Slider
           obj.blue_channel_max_slider = uicontrol(obj.blue_panel,'Style','slider','Min',0,...
               'Max',255,'Units','normalized','Position', [0 0 slider_width slider_height],... 
               'Callback',@(src,~)obj.update_blue(src),'Value',255,...
               'Tag','Max Slider','Enable','off');
           % Blue Max Text
           newX1 = slider_width+0.008;
           sideplot_X = 0;
           name_exp_text_width = 1-sideplot_X;
           uicontrol(obj.blue_panel,'Style','text','String','Max:','Units','normalized',...
               'Position',[newX1 0 text_width slider_height],'FontUnits','normalized','FontSize',min_max_font_size);
           % Blue Max Edit Box
           newX2 = newX1 + text_width;
           obj.blue_channel_max_edit = uicontrol(obj.blue_panel,'Style','edit','String','255',...
               'Units','normalized','Position',[newX2 0 text_width slider_height],...
               'Callback',@(src,~)obj.update_blue(src),'Tag','Max Edit','Enable','off',...
               'FontUnits','normalized','FontSize',min_max_font_size);
           
           % Blue Min Slider
           newY = slider_height;
           obj.blue_channel_min_slider = uicontrol(obj.blue_panel,'Style','slider','Min',0,...
               'Max',255,'Units','normalized','Position', [0 newY slider_width slider_height],... 
               'Callback',@(src,~)obj.update_blue(src),'Value',0,...
               'Tag','Min Slider','Enable','off');
           % Blue Min Text
           uicontrol(obj.blue_panel,'Style','text','String','Min:','Units','normalized',...
               'Position',[newX1 newY text_width slider_height],'FontUnits','normalized','FontSize',min_max_font_size);
           % Blue Min Edit Box
           obj.blue_channel_min_edit = uicontrol(obj.blue_panel,'Style','edit','String','0',...
               'Units','normalized','Position',[newX2 newY text_width slider_height],...
               'Callback',@(src,~)obj.update_blue(src),'Tag','Min Edit','Enable','off',...
               'FontUnits','normalized','FontSize',min_max_font_size);
           
           % Blue Plot
           newY = newY + slider_height;
           blue_axes = axes('Parent',obj.blue_panel,'Units','normalized',...
               'Position',[plot_x newY plot_width 1-newY],'XLim',[0 255],...
               'XTick',[],'YTick',[]);
           blue_axes.Toolbar.Visible = 'off';
           obj.blue_channel_plot = blue_axes;
           hold(obj.blue_channel_plot,'on')
           obj.blue_max_line = xline(255,'Parent',obj.blue_channel_plot);
           obj.blue_min_line = xline(1,'Parent',obj.blue_channel_plot);
           
           % Blue Channel Exposure Time
           newYE = slider_height;
           obj.blue_channel_exp = uicontrol(obj.blue_property_panel,'Style','edit','String','',...
               'Units','normalized','Position',[sideplot_X newYE name_exp_text_width slider_height],...
               'Tag','Blue Exp','Enable','off','Callback',@(src,~)obj.change_name_exp(src),...
               'FontUnits','normalized','FontSize',min_max_font_size);
           newYE = newYE + slider_height;
           uicontrol(obj.blue_property_panel,'Style','text','Units','normalized',...
               'FontUnits','normalized','FontSize',min_max_font_size,'String','Blue Channel Exposure Time',...
               'Position',[sideplot_X newYE name_exp_text_width slider_height]);
                     
           % Blue Channel Dropdown Selection
           newYE = newYE + slider_height*2;
           obj.blue_channel_name = uicontrol(obj.blue_property_panel,'Style','popupmenu','String',' ',...
               'Units','normalized','Position',[sideplot_X newYE name_exp_text_width slider_height],...
               'Tag','Blue Name','Enable','off','Callback',@(src,~)obj.change_name_exp(src),...
               'FontUnits','normalized','FontSize',min_max_font_size);
           newYE = newYE + slider_height;
           uicontrol(obj.blue_property_panel,'Style','text','Units','normalized',...
               'FontUnits','normalized','FontSize',min_max_font_size,'String','Selected Blue Channel',...
               'Position',[sideplot_X newYE name_exp_text_width slider_height]);
           
           % Blue Channel Name
           newYE = newYE + slider_height*2;
           obj.blue_channel_editable_name = uicontrol(obj.blue_property_panel,'Style','edit','String','',...
               'Units','normalized','Position',[sideplot_X newYE name_exp_text_width slider_height],...
               'Tag','Blue Edit Name','Enable','off','Callback',@(src,~)obj.change_name(src),...
               'FontUnits','normalized','FontSize',min_max_font_size);
           newYE = newYE + slider_height;
           uicontrol(obj.blue_property_panel,'Style','text','Units','normalized',...
               'FontUnits','normalized','FontSize',min_max_font_size,'String','Blue Channel Name',...
               'Position',[sideplot_X newYE name_exp_text_width slider_height]);
           
           % Blue channel state checkbox
           newY = obj.blue_channel_plot.Position(2) + obj.blue_channel_plot.Position(4) - enabled_height;
           uicontrol(obj.blue_panel,'Style','text','Units','normalized',...
               'FontUnits','normalized','FontSize',enabled_font_size,'String','Blue Enabled:',...
               'Position',[enabled_X newY-check_text_pos_fix enabled_width enabled_height],...
               'HorizontalAlignment','left');
           newY = newY+enabled_height/2;
           obj.blue_check_box = uicontrol(obj.blue_panel,'Style','checkbox',...
               'Units','normalized','Position',[check_X newY text_width slider_height],...
               'Callback',@(~,~)obj.set_blue_channel_state(),'Enable','off',...
               'Min',0,'Max',1,'Value',1);
           
           %%%%%%%%%%%%%%%%%%%%%
           % BUILD GREEN PANEL %
           %%%%%%%%%%%%%%%%%%%%%
           
           % Green Max Slider
           obj.green_channel_max_slider = uicontrol(obj.green_panel,'Style','slider','Min',0,...
               'Max',255,'Units','normalized','Position', [0 0 slider_width slider_height],... 
               'Callback',@(src,~)obj.update_green(src),'Value',255,...
               'Tag','Max Slider','Enable','off');
           % Green Max Text
           uicontrol(obj.green_panel,'Style','text','String','Max:','Units','normalized',...
               'Position',[newX1 0 text_width slider_height],'FontUnits','normalized','FontSize',min_max_font_size);
           % Green Max Edit Box
           newX2 = newX1 + text_width;
           obj.green_channel_max_edit = uicontrol(obj.green_panel,'Style','edit','String','255',...
               'Units','normalized','Position',[newX2 0 text_width slider_height],...
               'Callback',@(src,~)obj.update_green(src),'Tag','Max Edit','Enable','off',...
               'FontUnits','normalized','FontSize',min_max_font_size);
           
           % Green Min Slider
           newY = slider_height;
           obj.green_channel_min_slider = uicontrol(obj.green_panel,'Style','slider','Min',0,...
               'Max',255,'Units','normalized','Position', [0 newY slider_width slider_height],... 
               'Callback',@(src,~)obj.update_green(src),'Value',0,...
               'Tag','Min Slider','Enable','off');
           % Green Min Text
           uicontrol(obj.green_panel,'Style','text','String','Min:','Units','normalized',...
               'Position',[newX1 newY text_width slider_height],'FontUnits','normalized',...
               'FontSize',min_max_font_size);
           % Green Min Edit Box
           obj.green_channel_min_edit = uicontrol(obj.green_panel,'Style','edit','String','0',...
               'Units','normalized','Position',[newX2 newY text_width slider_height],...
               'Callback',@(src,~)obj.update_green(src),'Tag','Min Edit','Enable','off',...
               'FontUnits','normalized','FontSize',min_max_font_size);
           
           % Green Plot
           newY = newY + slider_height;
           green_axes = axes('Parent',obj.green_panel,'Units','normalized',...
               'Position',[plot_x newY plot_width 1-newY],'XLim',[0 255],...
               'XTick',[],'YTick',[]);
           green_axes.Toolbar.Visible = 'off';
           obj.green_channel_plot = green_axes;
           hold(obj.green_channel_plot,'on')
           obj.green_max_line = xline(255,'Parent',obj.green_channel_plot);
           obj.green_min_line = xline(1,'Parent',obj.green_channel_plot);
           
           % Green Channel Exposure Time
           newYE = slider_height;
           obj.green_channel_exp = uicontrol(obj.green_property_panel,'Style','edit','String','',...
               'Units','normalized','Position',[sideplot_X newYE name_exp_text_width slider_height],...
               'Tag','Green Exp','Enable','off','Callback',@(src,~)obj.change_name_exp(src),...
               'FontUnits','normalized','FontSize',min_max_font_size);
           newYE = newYE + slider_height;
           uicontrol(obj.green_property_panel,'Style','text','Units','normalized',...
               'FontUnits','normalized','FontSize',min_max_font_size,'String','Green Channel Exposure Time',...
               'Position',[sideplot_X newYE name_exp_text_width slider_height]);
                     
           % Green Channel Dropdown Selection
           newYE = newYE + slider_height*2;
           obj.green_channel_name = uicontrol(obj.green_property_panel,'Style','popupmenu','String',' ',...
               'Units','normalized','Position',[sideplot_X newYE name_exp_text_width slider_height],...
               'Tag','Green Name','Enable','off','Callback',@(src,~)obj.change_name_exp(src),...
               'FontUnits','normalized','FontSize',min_max_font_size);
           newYE = newYE + slider_height;
           uicontrol(obj.green_property_panel,'Style','text','Units','normalized',...
               'FontUnits','normalized','FontSize',min_max_font_size,'String','Selected Green Channel',...
               'Position',[sideplot_X newYE name_exp_text_width slider_height]);
           
           % Green Channel Name
           newYE = newYE + slider_height*2;
           obj.green_channel_editable_name = uicontrol(obj.green_property_panel,'Style','edit','String','',...
               'Units','normalized','Position',[sideplot_X newYE name_exp_text_width slider_height],...
               'Tag','Green Edit Name','Enable','off','Callback',@(src,~)obj.change_name(src),...
               'FontUnits','normalized','FontSize',min_max_font_size);
           newYE = newYE + slider_height;
           uicontrol(obj.green_property_panel,'Style','text','Units','normalized',...
               'FontUnits','normalized','FontSize',min_max_font_size,'String','Green Channel Name',...
               'Position',[sideplot_X newYE name_exp_text_width slider_height]);
           
           % Green state check box
           newY = obj.green_channel_plot.Position(2) + obj.green_channel_plot.Position(4) - enabled_height;
           uicontrol(obj.green_panel,'Style','text','Units','normalized',...
               'FontUnits','normalized','FontSize',enabled_font_size,'String','Green Enabled:',...
               'Position',[enabled_X newY-check_text_pos_fix enabled_width enabled_height],...
               'HorizontalAlignment','left');
           newY = newY+enabled_height/2;
           
           obj.green_check_box = uicontrol(obj.green_panel,'Style','checkbox',...
               'Units','normalized','Position',[check_X newY text_width slider_height],...
               'Callback',@(~,~)obj.set_green_channel_state(),'Enable','off',...
               'Min',0,'Max',1,'Value',1);
           
           %%%%%%%%%%%%%%%%%%%
           % BUILD RED PANEL %
           %%%%%%%%%%%%%%%%%%%
           
           % Red Max Slider
           obj.red_channel_max_slider = uicontrol(obj.red_panel,'Style','slider','Min',0,...
               'Max',255,'Units','normalized','Position', [0 0 slider_width slider_height],... 
               'Callback',@(src,~)obj.update_red(src),'Value',255,...
               'Tag','Max Slider','Enable','off');
           % Red Max Text
           uicontrol(obj.red_panel,'Style','text','String','Max:','Units','normalized',...
               'Position',[newX1 0 text_width slider_height],'FontUnits','normalized','FontSize',min_max_font_size);
           % Red Max Edit Box
           newX2 = newX1 + text_width;
           obj.red_channel_max_edit = uicontrol(obj.red_panel,'Style','edit','String','255',...
               'Units','normalized','Position',[newX2 0 text_width slider_height],...
               'Callback',@(src,~)obj.update_red(src),'Tag','Max Edit','Enable','off',...
               'FontUnits','normalized','FontSize',min_max_font_size);
           
           % Red Min Slider
           newY = slider_height;
           obj.red_channel_min_slider = uicontrol(obj.red_panel,'Style','slider','Min',0,...
               'Max',255,'Units','normalized','Position', [0 newY slider_width slider_height],... 
               'Callback',@(src,~)obj.update_red(src),'Value',0,...
               'Tag','Min Slider','Enable','off');
           % Red Min Text
           uicontrol(obj.red_panel,'Style','text','String','Min:','Units','normalized',...
               'Position',[newX1 newY text_width slider_height],'FontUnits','normalized','FontSize',min_max_font_size);
           % Red Min Edit Box
           obj.red_channel_min_edit = uicontrol(obj.red_panel,'Style','edit','String','0',...
               'Units','normalized','Position',[newX2 newY text_width slider_height],...
               'Callback',@(src,~)obj.update_red(src),'Tag','Min Edit','Enable','off',...
               'FontUnits','normalized','FontSize',min_max_font_size);
           
           % Red Plot
           newY = newY + slider_height;
           red_axes = axes('Parent',obj.red_panel,'Units','normalized',...
               'Position',[plot_x newY plot_width 1-newY],'XLim',[0 255],...
               'XTick',[],'YTick',[]);
           red_axes.Toolbar.Visible = 'off';
           obj.red_channel_plot = red_axes;
           hold(obj.red_channel_plot,'on')
           obj.red_max_line = xline(255,'Parent',obj.red_channel_plot);
           obj.red_min_line = xline(1,'Parent',obj.red_channel_plot);
           
           % Red Channel Exposure Time
           newYE = slider_height;
           obj.red_channel_exp = uicontrol(obj.red_property_panel,'Style','edit','String','',...
               'Units','normalized','Position',[sideplot_X newYE name_exp_text_width slider_height],...
               'Tag','Red Exp','Enable','off','Callback',@(src,~)obj.change_name_exp(src),...
               'FontUnits','normalized','FontSize',min_max_font_size);
           newYE = newYE + slider_height;
           uicontrol(obj.red_property_panel,'Style','text','Units','normalized',...
               'FontUnits','normalized','FontSize',min_max_font_size,'String','Red Channel Exposure Time',...
               'Position',[sideplot_X newYE name_exp_text_width slider_height]);
                     
           % Red Channel Dropdown Selection
           newYE = newYE + slider_height*2;
           obj.red_channel_name = uicontrol(obj.red_property_panel,'Style','popupmenu','String',' ',...
               'Units','normalized','Position',[sideplot_X newYE name_exp_text_width slider_height],...
               'Tag','Red Name','Enable','off','Callback',@(src,~)obj.change_name_exp(src),...
               'FontUnits','normalized','FontSize',min_max_font_size);
           newYE = newYE + slider_height;
           uicontrol(obj.red_property_panel,'Style','text','Units','normalized',...
               'FontUnits','normalized','FontSize',min_max_font_size,'String','Selected Red Channel',...
               'Position',[sideplot_X newYE name_exp_text_width slider_height]);
           
           % Red Channel Name
           newYE = newYE + slider_height*2;
           obj.red_channel_editable_name = uicontrol(obj.red_property_panel,'Style','edit','String','',...
               'Units','normalized','Position',[sideplot_X newYE name_exp_text_width slider_height],...
               'Tag','Red Edit Name','Enable','off','Callback',@(src,~)obj.change_name(src),...
               'FontUnits','normalized','FontSize',min_max_font_size);
           newYE = newYE + slider_height;
           uicontrol(obj.red_property_panel,'Style','text','Units','normalized',...
               'FontUnits','normalized','FontSize',min_max_font_size,'String','Red Channel Name',...
               'Position',[sideplot_X newYE name_exp_text_width slider_height]);
           
           % Red state check box
           newY = obj.red_channel_plot.Position(2) + obj.red_channel_plot.Position(4) - enabled_height;
           uicontrol(obj.red_panel,'Style','text','Units','normalized',...
               'FontUnits','normalized','FontSize',enabled_font_size,'String','Red Enabled:',...
               'Position',[enabled_X newY-check_text_pos_fix enabled_width enabled_height],...
               'HorizontalAlignment','left');
           newY = newY+enabled_height/2;
           obj.red_check_box = uicontrol(obj.red_panel,'Style','checkbox',...
               'Units','normalized','Position',[check_X newY text_width slider_height],...
               'Callback',@(~,~)obj.set_red_channel_state(),'Enable','off',...
               'Min',0,'Max',1,'Value',1);
           
       end
   
       function change_name(obj,src)
       %CHANGE_NAME Changes the name of a selected channel to a new entry;
       %if channel name is identical to another channel, notifies the user
       %and does not change the channel name.
           
           names = obj.analysis_tool.channel_names;
           names_orig = obj.analysis_tool.channel_names_orig;
           
           % Identify which color channel was changed
           color = regexp(src.Tag,'(Red|Green|Blue)','tokens');
           color = color{1}{1};
           logi_colors = strcmp(color,{'Red','Green','Blue'});
           
           replaced_name = names{logi_colors};
               
           % Check that name is unique
            if any(strcmp(src.String,names))
               if ~strcmp(src.String,replaced_name)
                   % indicates user selected a channel already assigned
                   % to a color
                   status_text = 'Channel names must be unique.';
                   notify(obj,'Status_Update',Events.ActionData(status_text));
                   src.String = replaced_name;
               end
               return;
            end
            
            
           % Update channel_names with new name
           names{logi_colors} = src.String;
           obj.analysis_tool.channel_names = names;
           obj.analysis_tool.channel_names_orig{strcmp(replaced_name,names_orig)} = src.String;
           
           obj.red_channel_name.String = obj.analysis_tool.channel_names_orig;
           obj.green_channel_name.String = obj.analysis_tool.channel_names_orig;
           obj.blue_channel_name.String = obj.analysis_tool.channel_names_orig;
              
           status_text = strcat([color ' channel name ''' replaced_name ''' changed to ''' src.String '''.']);
           notify(obj,'Status_Update',Events.ActionData(status_text));
       end
       
       function change_name_exp(obj,src)
        %CHANGE_NAME_EXP Callback function for all color channel's names
        %and exposure times text edit boxes.
        % Updates the internally stored properties dependent on which
        % uicontrol activated the callback function.
        
           % Extract current RGB channel names and full list of original
           % channel data
           names = obj.analysis_tool.channel_names;
           exp_times = obj.analysis_tool.channel_exp;
           names_orig = obj.analysis_tool.channel_names_orig;
           exp_times_orig = obj.analysis_tool.channel_exp_orig;
           
           % Identify which color channel was changed
           color = regexp(src.Tag,'(Red|Green|Blue)','tokens');
           color = color{1}{1};
           logi_colors = strcmp(color,{'Red','Green','Blue'});
           
           % Reset swapped channel's background subtraction mask
           obj.analysis_tool.bs_arr(:,:,logi_colors) = uint16(zeros(size(obj.analysis_tool.image_unedited(:,:,logi_colors))));
           
           % Check whether the activation source was a channel name or
           % channel exposure time
           if contains(src.Tag,'Name')
               % Set channel_names property to new value
               replaced_name = names{logi_colors};
               
               % Check if 'None' was selected
               if strcmp(src.String{src.Value},'None')
                      % indicates the user has selected to replace the
                      % color channel with a blank channel
                       
                       % Disable the selected channel if it hasn't already
                       % been disabled and set exposure time to 0
                       if logi_colors(1)
                           obj.analysis_tool.channel_exp{1} = 0;
                           if obj.red_check_box.Value == 1
                              obj.enable_red(); 
                           end
                           obj.red_check_box.Enable = 'off';
                       elseif logi_colors(2)
                           obj.analysis_tool.channel_exp{2} = 0;
                           if obj.green_check_box.Value == 1
                              obj.enable_green(); 
                           end
                           obj.green_check_box.Enable = 'off';
                       else
                           obj.analysis_tool.channel_exp{3} = 0;
                           if obj.blue_check_box.Value == 1
                              obj.enable_blue(); 
                           end
                           obj.blue_check_box.Enable = 'off';
                       end
                       exp_obj = findobj('Tag',[color ' Exp']);
                       name_obj = findobj('Tag',[color ' Edit Name']);
                       name_obj.String = 'None';
                       exp_obj.String = '0';

                       % Update channel_names with new name
                       names{logi_colors} = src.String{src.Value};
                       obj.analysis_tool.channel_names = names;

                       % Set UserData to indicate a significant channel
                       % change has occurred
                       obj.UserData = 'Channel_Changed';
                       status_text = strcat([color ' channel ''' replaced_name ''' changed to ''' src.String{src.Value} '''.']);
                       
                       % Notify 'Status_Update' and 'ChannelChanged' event listeners
                       notify(obj,'Status_Update',Events.ActionData(status_text));
                       notify(obj,'ChannelChanged')
                       return;
               end
               
               % Check if new name matches any channel name. 
               % If so, check if new name matches replaced name. If so,
               % return. Otherwise, reject name and notify user.
               if any(strcmp(src.String{src.Value},names))
                   if ~strcmp(src.String{src.Value},replaced_name)
                       % indicates user selected a channel already assigned
                       % to a color
                       status_text = 'Selected channels must be unique.';
                       notify(obj,'Status_Update',Events.ActionData(status_text));
                       idx = find(strcmp(replaced_name,names_orig)==1);
                       src.Value = idx;
                   end
                   return;
               end
               
               if logi_colors(1)
                   if obj.red_check_box.Value == 0
                      obj.enable_red(); 
                   end
                   obj.red_check_box.Enable = 'on';
               elseif logi_colors(2)
                   if obj.green_check_box.Value == 0
                      obj.enable_green(); 
                   end
                   obj.green_check_box.Enable = 'on';
               else
                   if obj.blue_check_box.Value == 0
                      obj.enable_blue(); 
                   end
                   obj.blue_check_box.Enable = 'on';
               end
               
               % Update exposure times
               obj.analysis_tool.channel_exp{logi_colors} = exp_times_orig{src.Value};
               exp_obj = findobj('Tag',[color ' Exp']);
               exp_obj.String = num2str(exp_times_orig{src.Value});
               
               % Update channel_names with new name
               names{logi_colors} = src.String{src.Value};
               obj.analysis_tool.channel_names = names;
               name_obj = findobj('Tag',[color ' Edit Name']);
               name_obj.String = src.String{src.Value};
               % Configure UserData to indicate a significant channel
               % change
               obj.UserData = 'Channel_Changed';
               
               % Create status update text
               status_text = strcat([color ' channel ''' replaced_name ''' changed to ''' src.String{src.Value} '''.']);
               
               % Notify 'ChannelChanged' event listeners that a significant
               % channel event has occurred
               notify(obj,'ChannelChanged')
               
           elseif contains(src.Tag,'Exp')
               % Set channel_exp property to new value
               replaced_exp = exp_times{logi_colors};
               if isnan(str2double(src.String))
                   status_text = 'Exposure times must be numerical values.';
                   notify(obj,'Status_Update',Events.ActionData(status_text));
                   src.String = num2str(replaced_exp);
                   return;
               end
               exp_times{logi_colors} = str2double(src.String);
               obj.analysis_tool.channel_exp = exp_times;
                              
               % Set the value in channel_exp_orig to the new exposure time at the
               % correct index by comparing channel names; names are used
               % since exposure time multiples are allowed, interfering
               % with logical indexing
               src_channel = findobj('Tag',[color ' Name']);
               src_channel_name = src_channel.String{src_channel.Value};
               obj.analysis_tool.channel_exp_orig{strcmp(src_channel_name,names_orig)} = str2double(src.String);
               status_text = strcat([color ' channel exposure time ''' num2str(replaced_exp) ''' changed to ''' src.String '''.']);
           else
               % If source is not recognized, warn the user that nothing
               % was changed internally
               warning('Callback activated but src.Tag not recognized. Exposure times and names unchanged.')
               status_text = 'Callback activated but src.Tag not recognized. Exposure times and names unchanged.';
           end
           % Notify event listener 'Status_Update' and pass updated status
           notify(obj,'Status_Update',Events.ActionData(status_text));
       end
       
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       % UPDATE CHANNEL CONTRAST FUNCTIONS %
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       
       function update_blue(obj,src)
        %UPDATE_BLUE Callback function for the Blue max slider & edit text 
        %box, and Blue min slider & edit text box. 
        % Updates the Blue color channel sliders, edit text boxes, and plot 
        % intensity vertical line markers. After the update, notifies
        % image class 'analyze' that channel contrast values have been
        % changed.
           
           obj.analysis_tool.check_zoom();
           
           % Check which GUI object activated the callback and update the
           % other GUI objects accordingly
           if strcmp(src.Tag,'Max Slider')
               if obj.blue_min_line.Value >= src.Value
                obj.blue_max_line.Value = obj.blue_min_line.Value + 1;
                obj.blue_channel_max_edit.String = num2str(obj.blue_min_line.Value + 1); 
                src.Value = obj.blue_min_line.Value + 1;
               else
                src.Value = round(src.Value);
                obj.blue_max_line.Value = src.Value;
                obj.blue_channel_max_edit.String = num2str(src.Value);
               end
               data = Events.ActionData(['Blue channel ''Max Slider'' set to '  num2str(src.Value)]);
           elseif strcmp(src.Tag,'Min Slider')
               if obj.blue_max_line.Value <= src.Value
                obj.blue_min_line.Value = obj.blue_max_line.Value - 1;
                obj.blue_channel_min_edit.String = num2str(obj.blue_max_line.Value - 1);
                src.Value = obj.blue_max_line.Value - 1;
               else
                src.Value = round(src.Value);
                obj.blue_min_line.Value = src.Value;
                obj.blue_channel_min_edit.String = num2str(src.Value);
               end
               data = Events.ActionData(['Blue channel ''Min Slider'' set to '  num2str(src.Value)]);
           elseif strcmp(src.Tag,'Min Edit')
               val = round(str2double(src.String));
               if val > 255
                   val = 255;
                   src.String = '255';
               elseif val < 0
                  val = 0;
                  src.String = '0';
               end
               
               if val >= obj.blue_max_line.Value
                obj.blue_min_line.Value = obj.blue_max_line.Value - 1;
                obj.blue_channel_min_slider.Value = obj.blue_max_line.Value - 1;
                src.String = num2str(obj.blue_max_line.Value - 1);
               else
                src.String = num2str(val);
                obj.blue_min_line.Value = val;
                obj.blue_channel_min_slider.Value = val;
               end
               data = Events.ActionData(['Blue channel ''Min Edit'' set to '  num2str(val)]);
           else
               val = round(str2double(src.String));
               if val > 255
                   val = 255;
                   src.String = '255';
               elseif val < 0
                  val = 0;
                  src.String = '0';
               end
               
               if val <= obj.blue_min_line.Value
                obj.blue_max_line.Value = obj.blue_min_line.Value + 1;
                obj.blue_channel_max_slider.Value = obj.blue_min_line.Value + 1;
                src.String = num2str(obj.blue_min_line.Value + 1);
               else
                src.String = num2str(val);
                obj.blue_max_line.Value = val;
                obj.blue_channel_max_slider.Value = val;
               end
               data = Events.ActionData(['Blue channel ''Max Edit'' set to '  num2str(val)]);
           end
           obj.UserData = 'Default';
           % Notify analyze class that channel values have been changed
           notify(obj,'Status_Update',data);
           notify(obj,'ChannelChanged')
       end
       
       function update_green(obj,src) 
        %UPDATE_GREEN Callback function for the Green max slider & edit text 
        %box, and Green min slider & edit text box. 
        % Updates the Green color channel sliders, edit text boxes, and plot 
        % intensity vertical line markers. After the update, notifies
        % image class 'analyze' that channel contrast values have been
        % changed.
        
           obj.analysis_tool.check_zoom();
        
           % Check which GUI object activated the callback and update the
           % other GUI objects accordingly
           if strcmp(src.Tag,'Max Slider')
               if obj.green_min_line.Value >= src.Value
                obj.green_max_line.Value = obj.green_min_line.Value + 1;
                obj.green_channel_max_edit.String = num2str(obj.green_min_line.Value + 1); 
                src.Value = obj.green_min_line.Value + 1;
               else
                src.Value = round(src.Value);
                obj.green_max_line.Value = src.Value;
                obj.green_channel_max_edit.String = num2str(src.Value);
               end
               data = Events.ActionData(['Green channel ''Max Slider'' set to '  num2str(src.Value)]);
           elseif strcmp(src.Tag,'Min Slider')
               if obj.green_max_line.Value <= src.Value
                obj.green_min_line.Value = obj.green_max_line.Value - 1;
                obj.green_channel_min_edit.String = num2str(obj.green_max_line.Value - 1);
                src.Value = obj.green_max_line.Value - 1;
               else
                src.Value = round(src.Value);
                obj.green_min_line.Value = src.Value;
                obj.green_channel_min_edit.String = num2str(src.Value);
               end
               data = Events.ActionData(['Green channel ''Min Slider'' set to '  num2str(src.Value)]);
           elseif strcmp(src.Tag,'Min Edit')
               val = round(str2double(src.String));
               if val > 255
                   val = 255;
                   src.String = '255';
               elseif val < 0
                  val = 0;
                  src.String = '0';
               end
               
               if val >= obj.green_max_line.Value
                obj.green_min_line.Value = obj.green_max_line.Value - 1;
                obj.green_channel_min_slider.Value = obj.green_max_line.Value - 1;
                src.String = num2str(obj.green_max_line.Value - 1);
               else
                src.String = num2str(val);
                obj.green_min_line.Value = val;
                obj.green_channel_min_slider.Value = val;
               end
               data = Events.ActionData(['Green channel ''Min Edit'' set to '  num2str(val)]);
           else
               val = round(str2double(src.String));
               if val > 255
                   val = 255;
                   src.String = '255';
               elseif val < 0
                  val = 0;
                  src.String = '0';
               end
               
               if val <= obj.green_min_line.Value
                obj.green_max_line.Value = obj.green_min_line.Value + 1;
                obj.green_channel_max_slider.Value = obj.green_min_line.Value + 1;
                src.String = num2str(obj.green_min_line.Value + 1);
               else
                src.String = num2str(val);
                obj.green_max_line.Value = val;
                obj.green_channel_max_slider.Value = val;
               end
               data = Events.ActionData(['Green channel ''Max Edit'' set to '  num2str(val)]);
           end
           obj.UserData = 'Default';
           % Notify analyze class that channel values have been changed
           notify(obj,'Status_Update',data);
           notify(obj,'ChannelChanged')
       end
       
       function update_red(obj,src) 
        %UPDATE_RED Callback function for the Red max slider & edit text 
        %box, and Red min slider & edit text box. 
        % Updates the Red color channel sliders, edit text boxes, and plot 
        % intensity vertical line markers. After the update, notifies
        % image class 'analyze' that channel contrast values have been
        % changed.
        
           obj.analysis_tool.check_zoom();
        
           % Check which GUI object activated the callback and update the
           % other GUI objects accordingly
           if strcmp(src.Tag,'Max Slider')
               if obj.red_min_line.Value >= src.Value
                obj.red_max_line.Value = obj.red_min_line.Value + 1;
                obj.red_channel_max_edit.String = num2str(obj.red_min_line.Value + 1); 
                src.Value = obj.red_min_line.Value + 1;
               else
                src.Value = round(src.Value);
                obj.red_max_line.Value = src.Value;
                obj.red_channel_max_edit.String = num2str(src.Value);
               end
               data = Events.ActionData(['Red channel ''Max Slider'' set to '  num2str(src.Value)]);
           elseif strcmp(src.Tag,'Min Slider')
               if obj.red_max_line.Value <= src.Value
                obj.red_min_line.Value = obj.red_max_line.Value - 1;
                obj.red_channel_min_edit.String = num2str(obj.red_max_line.Value - 1);
                src.Value = obj.red_max_line.Value - 1;
               else
                src.Value = round(src.Value);
                obj.red_min_line.Value = src.Value;
                obj.red_channel_min_edit.String = num2str(src.Value);
               end
               data = Events.ActionData(['Red channel ''Min Slider'' set to '  num2str(src.Value)]);
           elseif strcmp(src.Tag,'Min Edit')
               val = round(str2double(src.String));
               if val > 255
                   val = 255;
                   src.String = '255';
               elseif val < 0
                  val = 0;
                  src.String = '0';
               end
               
               if val >= obj.red_max_line.Value
                obj.red_min_line.Value = obj.red_max_line.Value - 1;
                obj.red_channel_min_slider.Value = obj.red_max_line.Value - 1;
                src.String = num2str(obj.red_max_line.Value - 1);
               else
                src.String = num2str(val);
                obj.red_min_line.Value = val;
                obj.red_channel_min_slider.Value = val;
               end
               data = Events.ActionData(['Red channel ''Min Edit'' set to '  num2str(val)]);
           else
               val = str2double(src.String);
               if val > 255
                   val = 255;
                   src.String = '255';
               elseif val < 0
                  val = 0;
                  src.String = '0';
               end
               
               if val <= obj.red_min_line.Value
                obj.red_max_line.Value = obj.red_min_line.Value + 1;
                obj.red_channel_max_slider.Value = obj.red_min_line.Value + 1;
                src.String = num2str(obj.red_min_line.Value + 1);
               else
                src.String = num2str(val);
                obj.red_max_line.Value = val;
                obj.red_channel_max_slider.Value = val;
               end
               data = Events.ActionData(['Red channel ''Max Edit'' set to '  num2str(val)]);
           end
           obj.UserData = 'Default';
           % Notify analyze class that channel values have been changed
           notify(obj,'Status_Update',data);
           notify(obj,'ChannelChanged')
       end
       
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%
       % CHANNEL ENABLE FUNCTIONS %
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%
       
       function enable_red(obj)
        %ENABLE_RED Enable/disable function for red color channel GUI objects.
        % Function checks if red channel is enabled, and if so, disables
        % it. If red channel is disabled, enables the channel.
        if ~isempty(obj.analysis_tool)
            obj.analysis_tool.check_zoom();
        end
           % Extract the current state of red GUI objects
           state = obj.red_channel_max_slider.Enable;
           if strcmp(state,'off')
               state = 'on';
               val = 1;
           else
               state = 'off';
               val = 0;
           end
           
           % Set all red GUI objects to the opposite of previous state
           obj.red_check_box.Value = val;
           obj.red_channel_max_slider.Enable = state;
           obj.red_channel_min_slider.Enable = state;
           obj.red_channel_min_edit.Enable = state;
           obj.red_channel_max_edit.Enable = state;
           obj.red_channel_exp.Enable = state;
           obj.red_channel_editable_name.Enable = state;
       end
       
       function enable_blue(obj)
        %ENABLE_BLUE Enable/disable function for blue color channel GUI objects.
        % Function checks if blue channel is enabled, and if so, disables
        % it. If blue channel is disabled, enables the channel.
        if ~isempty(obj.analysis_tool)
            obj.analysis_tool.check_zoom();
        end
           % Extract the current state of blue GUI objects
           state = obj.blue_channel_max_slider.Enable;
           if strcmp(state,'off')
               state = 'on';
               val = 1;
           else
               state = 'off';
               val = 0;
           end
           
           % Set all blue GUI objects to the opposite of previous state
           obj.blue_check_box.Value = val;
           obj.blue_channel_max_slider.Enable = state;
           obj.blue_channel_min_slider.Enable = state;
           obj.blue_channel_min_edit.Enable = state;
           obj.blue_channel_max_edit.Enable = state;
           obj.blue_channel_exp.Enable = state;
           obj.blue_channel_editable_name.Enable = state;
       end
       
       function enable_green(obj)
        %ENABLE_GREEN Enable/disable function for green color channel GUI objects.
        % Function checks if green channel is enabled, and if so, disables
        % it. If green channel is disabled, enables the channel.
        if ~isempty(obj.analysis_tool)
            obj.analysis_tool.check_zoom();
        end
           % Extract the current state of green GUI objects
           state = obj.green_channel_max_slider.Enable;
           if strcmp(state,'off')
               state = 'on';
               val = 1;
           else
               state = 'off';
               val = 0;
           end
           
           % Set all green GUI objects to the opposite of previous state
           obj.green_check_box.Value = val;
           obj.green_channel_max_slider.Enable = state;
           obj.green_channel_min_slider.Enable = state;
           obj.green_channel_min_edit.Enable = state;
           obj.green_channel_max_edit.Enable = state;
           obj.green_channel_exp.Enable = state;
           obj.green_channel_editable_name.Enable = state;
       end
       
       function enable_all(obj,evnt)
       %ENABLE_ALL Enable function for all color channels' GUI objects.
       % Function checks if each channel has been enabled and enables the
       % channels that are disabled.
        
          % Check that color channel GUI objects are disabled and enable
          % them all
          if strcmp(obj.green_channel_max_slider.Enable,'off')
              obj.enable_green();
              obj.green_check_box.Enable = 'on';
              obj.green_channel_name.Enable = 'on';
              obj.green_channel_exp.Enable = 'on';
          end
          if strcmp(obj.blue_channel_max_slider.Enable,'off')
              obj.enable_blue();
              obj.blue_check_box.Enable = 'on';
              obj.blue_channel_name.Enable = 'on';
              obj.blue_channel_exp.Enable = 'on';
          end
          if strcmp(obj.red_channel_max_slider.Enable,'off')
              obj.enable_red();
              obj.red_check_box.Enable = 'on';
              obj.red_channel_name.Enable = 'on';
              obj.red_channel_exp.Enable = 'on';
          end
          
          % Extract current image from analysis tool
          obj.analysis_tool = evnt.newValue;
          image_mask = obj.analysis_tool.image_mask;
          if iscell(obj.analysis_tool.filepath)
              [~,name] = fileparts(obj.analysis_tool.filepath{1});
          else
              [~,name] = fileparts(obj.analysis_tool.filepath);
          end
          obj.image_name.String = name;
          % Create image history plots based on image
          obj.red_bar_plot = bar(imhist(image_mask(:,:,1)),0.5,'r','Parent',obj.red_channel_plot);
          obj.green_bar_plot = bar(imhist(image_mask(:,:,2)),0.5,'g','Parent',obj.green_channel_plot);
          obj.blue_bar_plot = bar(imhist(image_mask(:,:,3)),0.5,'b','Parent',obj.blue_channel_plot);
          
          % Set 'channel_tool' channel names and exposure times
          names = obj.analysis_tool.channel_names;
          names_orig = obj.analysis_tool.channel_names_orig;
          exp_time = obj.analysis_tool.channel_exp;
          
          if ~isempty(names)
              
              red_idx = find(strcmp(names{1},names_orig)==1);
              green_idx = find(strcmp(names{2},names_orig)==1);
              blue_idx = find(strcmp(names{3},names_orig)==1);
              
              obj.red_channel_name.String = names_orig;
              obj.green_channel_name.String = names_orig;
              obj.blue_channel_name.String = names_orig;
              
              obj.red_channel_name.Value = red_idx;
              obj.green_channel_name.Value = green_idx;
              obj.blue_channel_name.Value = blue_idx;
              
              obj.red_channel_editable_name.String = names{1};
              obj.green_channel_editable_name.String = names{2};
              obj.blue_channel_editable_name.String = names{3};
              
              obj.default_channel_names = obj.analysis_tool.channel_names_orig;
          end
          
          if ~isempty(exp_time)
              obj.red_channel_exp.String = exp_time{1};
              obj.green_channel_exp.String = exp_time{2};
              obj.blue_channel_exp.String = exp_time{3};
              obj.default_exp_times = obj.analysis_tool.channel_exp_orig;
          end
          
       end
       
       %%%%%%%%%%%%%%%%%%%%%%%%%%%
       % CHANNEL STATE FUNCTIONS %
       %%%%%%%%%%%%%%%%%%%%%%%%%%%
       
       
       function set_red_channel_state(obj)
       %SET_RED_CHANNEL_STATE Callback function for red channel state, 
       %activated by red channel state indication textbox.
       % Function changes the state of all red GUI objects to their
       % opposite and indicates to the user whether the red channel was
       % enabled or disabled by this action.
       obj.analysis_tool.check_zoom();
           % Change red GUI objects states
           obj.enable_red();
           if obj.red_check_box.Value == 1
               text = 'Red Channel Enabled';
           else
               text = 'Red Channel Disabled';
           end
           obj.UserData = 'Default';
           % Notify analyze that channel contrast has been changed
           notify(obj,'Status_Update',Events.ActionData(text));
           notify(obj,'ChannelChanged');
       end
       
       function set_green_channel_state(obj)
       %SET_GREEN_CHANNEL_STATE Callback function for green channel state, 
       %activated by green channel state indication textbox.
       % Function changes the state of all green GUI objects to their
       % opposite and indicates to the user whether the green channel was
       % enabled or disabled by this action.
       obj.analysis_tool.check_zoom();
           % Change green GUI objects states
           obj.enable_green();
           if obj.green_check_box.Value == 1
               text = 'Green Channel Enabled';
           else
               text = 'Green Channel Disabled';
           end
           obj.UserData = 'Default';
           % Notify analyze that channel contrast has been changed
           notify(obj,'Status_Update',Events.ActionData(text));
           notify(obj,'ChannelChanged');
       end
       
       function set_blue_channel_state(obj)
       %SET_BLUE_CHANNEL_STATE Callback function for blue channel state, 
       %activated by blue channel state indication textbox.
       % Function changes the state of all blue GUI objects to their
       % opposite and indicates to the user whether the blue channel was
       % enabled or disabled by this action.
       obj.analysis_tool.check_zoom();
           % Change blue GUI objects states
           obj.enable_blue();
           if obj.blue_check_box.Value == 1
               text = 'Blue Channel Enabled';
           else
               text = 'Blue Channel Disabled';
           end
           obj.UserData = 'Default';
           % Notify analyze that channel contrast has been changed
           notify(obj,'Status_Update',Events.ActionData(text));
           notify(obj,'ChannelChanged');
       end
       
       function obj = reset_contrasts(obj)
       %RESET_CONTRASTS Resets channel display properties to default
       %values. All channels return to full 0-255 display range and sliders
       %and plot lines are updated accordingly.
           
           % Reset Red Channel Values
           obj.red_channel_min_slider.Value = 0; 
           obj.red_channel_min_edit.String = '0';   
           obj.red_channel_max_slider.Value = 255; 
           obj.red_channel_max_edit.String = '255';   
           obj.red_min_line.Value = 0;           
           obj.red_max_line.Value = 255;     
           
           % Reset Green Channel Values
           obj.green_channel_min_slider.Value = 0; 
           obj.green_channel_min_edit.String = '0';   
           obj.green_channel_max_slider.Value = 255; 
           obj.green_channel_max_edit.String = '255';   
           obj.green_min_line.Value = 0;           
           obj.green_max_line.Value = 255;     
           
           % Reset Blue Channel Values
           obj.blue_channel_min_slider.Value = 0; 
           obj.blue_channel_min_edit.String = '0';   
           obj.blue_channel_max_slider.Value = 255; 
           obj.blue_channel_max_edit.String = '255';   
           obj.blue_min_line.Value = 0;           
           obj.blue_max_line.Value = 255;
           notify(obj,'ChannelChanged')
       end
       
       %%%%%%%%%%%%%%%%%%%%%%%
       % RESET TOOL FUNCTION %
       %%%%%%%%%%%%%%%%%%%%%%%
       
       function reset_data(obj)
       %RESET_DATA When new image is loaded during the same session, this
       %function clears properties and resets channel data in preparation
       %for a new image.
       
           cla(obj.image_prop_image);
           obj.image_name.String = '';
           obj.analysis_tool = [];
           imshow(imread([obj.image_prop_image_dir 'PlaceHolderImage_72.png']),'Parent',obj.image_prop_image);
           %%%%%%%%%%%%%%%%%%%%% RESET BLUE STATE %%%%%%%%%%%%%%%%%%%%%%%%%
           % Blue Max Slider
           set(obj.blue_channel_max_slider,{'Enable','Value'},{'off',255});
           
           % Blue Max Edit Box
           set(obj.blue_channel_max_edit,{'Enable','String'},{'off','255'});
           
           % Blue Min Slider
           set(obj.blue_channel_min_slider,{'Enable','Value'},{'off',0});
           
           % Blue Min Edit Box
           set(obj.blue_channel_min_edit,{'Enable','String'},{'off','0'});
           
           % Blue Plot
           cla(obj.blue_channel_plot);
           obj.blue_max_line = xline(255,'Parent',obj.blue_channel_plot);
           obj.blue_min_line = xline(1,'Parent',obj.blue_channel_plot);
                      
           % Blue Channel Exposure Time
           set(obj.blue_channel_exp,{'Enable','String'},{'off',''});
                     
           % Blue Channel Dropdown Selection
           set(obj.blue_channel_name,{'Enable','Value','String'},{'off',1,' '});
           
           % Blue Channel Name
           set(obj.blue_channel_editable_name,{'Enable','String'},{'off',''});
           
           % Blue channel state checkbox
           obj.blue_check_box.Enable = 'off';
           %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
           
           
           %%%%%%%%%%%%%%%%%%%%% RESET GREEN STATE %%%%%%%%%%%%%%%%%%%%%%%%%
           % Green Max Slider
           set(obj.green_channel_max_slider,{'Enable','Value'},{'off',255});
           
           % Green Max Edit Box
           set(obj.green_channel_max_edit,{'Enable','String'},{'off','255'});
           
           % Green Min Slider
           set(obj.green_channel_min_slider,{'Enable','Value'},{'off',0});
           
           % Green Min Edit Box
           set(obj.green_channel_min_edit,{'Enable','String'},{'off','0'});
           
           % Green Plot
           cla(obj.green_channel_plot);
           obj.green_max_line = xline(255,'Parent',obj.green_channel_plot);
           obj.green_min_line = xline(1,'Parent',obj.green_channel_plot);
           
           % Green Channel Exposure Time
           set(obj.green_channel_exp,{'Enable','String'},{'off',''});
                     
           % Green Channel Dropdown Selection
           set(obj.green_channel_name,{'Enable','Value','String'},{'off',1,' '});
           
           % Green Channel Name
           set(obj.green_channel_editable_name,{'Enable','String'},{'off',''});
           
           % Green channel state checkbox
           obj.green_check_box.Enable = 'off';
           %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
           
           %%%%%%%%%%%%%%%%%%%%% RESET RED STATE %%%%%%%%%%%%%%%%%%%%%%%%%
           % Red Max Slider
           set(obj.red_channel_max_slider,{'Enable','Value'},{'off',255});
           
           % Red Max Edit Box
           set(obj.red_channel_max_edit,{'Enable','String'},{'off','255'});
           
           % Red Min Slider
           set(obj.red_channel_min_slider,{'Enable','Value'},{'off',0});
           
           % Red Min Edit Box
           set(obj.red_channel_min_edit,{'Enable','String'},{'off','0'});
           
           % Red Plot
           cla(obj.red_channel_plot);
           obj.red_max_line = xline(255,'Parent',obj.red_channel_plot);
           obj.red_min_line = xline(1,'Parent',obj.red_channel_plot);
           
           % Red Channel Exposure Time
           set(obj.red_channel_exp,{'Enable','String'},{'off',''});
                     
           % Red Channel Dropdown Selection
           set(obj.red_channel_name,{'Enable','Value','String'},{'off',1,' '});
           
           % Red Channel Name
           set(obj.red_channel_editable_name,{'Enable','String'},{'off',''});
           
           % Red channel state checkbox
           obj.red_check_box.Enable = 'off';
           %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       end
   end
    
    
    
    
    
end
