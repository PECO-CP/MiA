classdef roi_stats < handle
%ROI_STATS Secondary MATLAB tool; child of image_analysis 
% parent class
%      ROI_STATS creates a new ROI_STATS class object instance within the 
%      parent class or creates a nonfunctional GUI representation.
%
%      H = ROI_STATS returns the handle to a new ROI_STATS tool, 
%      displaying GUI interfaces and holding data values relevant to 
%      currently defined ROIs.
% 
%      This class was constructed to operate solely with the properties and 
%      objects of parent class image_analysis and sub class analyze 
%      in package Interfaces.
% 
%      This class can be run on its own; in that case, it is a nonfunctional 
%      representation of the graphic objects inherent in this class. This 
%      is primarily used for troubleshooting and preview purposes.

% Last Modified by Alexis Pasulka v3.01 Oct-2023
 

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
       parent_class = [];       % handle to parent image_analysis class
       
       % Pixel and Micrometer Statistic Panels
       stat_panel = [];         % handle to pixel statistics panel
       stat_um_panel = [];      % handle to micrometer statistics panel
       
       % GUI contents of Pixel Panel
       min_pixel = [];          % minimum ROI area in pixels
       min_pixel_edit = [];     % minimum ROI area text edit box; can be edited by user
       max_pixel = [];          % maximum ROI area in pixels
       max_pixel_edit = [];     % maximum ROI area text edit box; can be edited by user
       mean_pixel = [];         % mean ROI area in pixels
       median_pixel = [];       % median ROI area in pixels
       cell = [];               % number of ROI cells
       
       % GUI contents of Micrometer Panel
       min_pixel_um = [];       % minimum ROI area in micrometers
       max_pixel_um = [];       % maximum ROI area in micrometers
       mean_pixel_um = [];      % mean ROI area in micrometers
       median_pixel_um = [];    % median ROI area in micrometers
       
       % User data
       conversion_factor = [];  % indicates the user input value of microns/pixel conversion factor
       table_data = [];         % holds the current ROI statisitcs values in table format
   end
   
   events
      Status_Update     % Status_Update event, indicating an event has occurred significant enough to display to the user
      ROIDefined        % ROIDefined event, indicating an ROI has been defined by any of the ROI-related functions
      AreaFilter        % AreaFilter event, indicating the user has changed the min/max ROI area
   end
   
   methods
       function obj = roi_stats(parent)
        %ROI_STATS Build function for class roi_stats.
        % If given no parent panel/figure, creates a nonfunctional Figure
        % representation of the class. If given another parent, builds
        % roi_stats GUI objects into that parent.
        %
        % This class was intended to operate with parent class
        % image_analysis. Functional use with other classes is not
        % currently supported; however, graphical use is.
        
           % Check number of input arguments
           if nargin == 0
              parent = Figure.blank_figure().fig_handle; 
           elseif strcmp(parent.Tag,'Image Analysis')
              obj.parent_class = parent;
              parent = parent.roi_panel;
           end
           
           statpanel_title_fontsize = 0.038;
           stat_umpanel_title_fontsize = 0.065;
           % Build GUI panels into parent
           obj.stat_panel = uipanel(parent,'Units','normalized',...
               'Position',[0 0.5 1 0.45],'Title','Pixel Statistics',...
               'FontUnits','normalized','FontSize',statpanel_title_fontsize);
           obj.stat_um_panel = uipanel(parent,'Units','normalized',...
               'Position',[0 0.05 1 0.25],'Title','Micrometer Statistics',...
               'FontUnits','normalized','FontSize',stat_umpanel_title_fontsize);
           
           % Set graphical constants
           X = 0.01;
           Y = 0.04;
           text_width = 0.5;
           edit_width = 0.45;
           height = 0.1;
           height_edit = 0.1;
           fontsize = 0.4;
           conv_fontsize = 0.2;
           conv_factor_fontsize = fontsize;
           %%%%%%%%%%%%%%%%%%%%
           % PIXEL STATISTICS %
           %%%%%%%%%%%%%%%%%%%%
           
           % Max pixel edit and text
           uicontrol(obj.stat_panel,'Style','text','String','Max Area','Units',...
               'normalized','Position',[X Y text_width height],'FontUnits','normalized','FontSize',...
               fontsize);
           
           obj.max_pixel_edit = uicontrol(obj.stat_panel,'Style','edit',...
               'Units','normalized','Position',[text_width+2*X Y+0.02 edit_width height_edit],...
               'Enable','off','Callback',@(~,~)obj.min_max_changed(),'FontUnits','normalized',...
               'FontSize',fontsize);
           newY = Y + height + Y;
           
           % Min pixel edit and text
           uicontrol(obj.stat_panel,'Style','text','String','Min Area','Units',...
               'normalized','Position',[X newY text_width height],'FontUnits','normalized','FontSize',...
               fontsize);
           
           obj.min_pixel_edit = uicontrol(obj.stat_panel,'Style','edit',...
               'Units','normalized','Position',[text_width+2*X newY+0.01 edit_width height_edit],...
               'Enable','off','Callback',@(~,~)obj.min_max_changed(),'FontUnits','normalized',...
               'FontSize',fontsize);
           newY = newY + height + Y;
           
           % Cell texts
           uicontrol(obj.stat_panel,'Style','text','String','Total Cells','Units',...
               'normalized','Position',[X newY text_width height],'FontUnits','normalized','FontSize',...
               fontsize,'FontUnits','normalized');
           
           obj.cell = uicontrol(obj.stat_panel,'Style','text',...
               'Units','normalized','Position',[text_width+2*X newY edit_width height],'FontUnits','normalized','FontSize',...
               fontsize);
           newY = newY + height + Y;
           
           % Median pixel texts
           uicontrol(obj.stat_panel,'Style','text','String','Median Area','Units',...
               'normalized','Position',[X newY+0.01 text_width height],'FontUnits','normalized','FontSize',...
               fontsize);
           
           obj.median_pixel = uicontrol(obj.stat_panel,'Style','text',...
               'Units','normalized','Position',[text_width+2*X newY edit_width height],'FontUnits','normalized','FontSize',...
               fontsize);
           newY = newY + height + Y;
           
           % Mean pixel texts
           uicontrol(obj.stat_panel,'Style','text','String','Mean Area','Units',...
               'normalized','Position',[X newY text_width height],'FontUnits','normalized','FontSize',...
               fontsize);
           
           obj.mean_pixel = uicontrol(obj.stat_panel,'Style','text',...
               'Units','normalized','Position',[text_width+2*X newY edit_width height],'FontUnits','normalized','FontSize',...
               fontsize);
           newY = newY + height + Y;
           
           % Max Pixel display
           uicontrol(obj.stat_panel,'Style','text','String','Max Area','Units',...
               'normalized','Position',[X newY text_width height],'FontUnits','normalized','FontSize',...
               fontsize);
           
           obj.max_pixel = uicontrol(obj.stat_panel,'Style','text',...
               'Units','normalized','Position',[text_width+2*X newY edit_width height],'FontUnits','normalized','FontSize',...
               fontsize);
           newY = newY + height + Y;
           
           % Min Pixel display
           uicontrol(obj.stat_panel,'Style','text','String','Min Area','Units',...
               'normalized','Position',[X newY text_width height],'FontUnits','normalized','FontSize',...
               fontsize);
           
           obj.min_pixel = uicontrol(obj.stat_panel,'Style','text',...
               'Units','normalized','Position',[text_width+2*X newY edit_width height],'FontUnits','normalized','FontSize',...
               fontsize);
           
           %%%%%%%%%%%%%%%%%%%%%%%%%%
           % CONVERSION FACTOR EDIT %
           %%%%%%%%%%%%%%%%%%%%%%%%%%
           
           % Conversion factor display
           conv_height = height - 0.02;
           conv_Y = (obj.stat_um_panel.Position(4)+obj.stat_panel.Position(2))/2-conv_height/2;
           
           uicontrol(parent,'Style','text','String','Conversion Factor (microns/pixel)','Units',...
               'normalized','Position',[X conv_Y text_width conv_height],'FontUnits','normalized','FontSize',...
               conv_fontsize);
           
           obj.conversion_factor = uicontrol(parent,'Style','edit',...
               'Units','normalized','Position',[text_width+2*X conv_Y+conv_height/2 edit_width conv_height/2],'FontUnits','normalized','FontSize',...
               conv_factor_fontsize,'Enable','off','Callback',@(~,~)obj.conversion_changed());
           
           %%%%%%%%%%%%%%%%%
           % UM STATISTICS %
           %%%%%%%%%%%%%%%%%
           
           % Median pixel texts
           newY = Y;
           height = height + 2*Y;
           %{
           uicontrol(obj.stat_um_panel,'Style','text','String','Median Area','Units',...
               'normalized','Position',[X newY text_width height],'FontUnits','normalized','FontSize',...
               fontsize);
           %}
           
           uicontrol(obj.stat_um_panel,'Style','text','String','Median Maj. Axis Length','Units',...
               'normalized','Position',[X newY text_width height],'FontUnits','normalized','FontSize',...
               fontsize);
           
           obj.median_pixel_um = uicontrol(obj.stat_um_panel,'Style','text',...
               'Units','normalized','Position',[text_width+2*X newY edit_width height],'FontUnits','normalized','FontSize',...
               fontsize);
           newY = newY + height + Y;
           
           % Mean pixel texts
           %{
           uicontrol(obj.stat_um_panel,'Style','text','String','Mean Area','Units',...
               'normalized','Position',[X newY text_width height],'FontUnits','normalized','FontSize',...
               fontsize);
           %}
           uicontrol(obj.stat_um_panel,'Style','text','String','Mean Maj. Axis Length','Units',...
               'normalized','Position',[X newY text_width height],'FontUnits','normalized','FontSize',...
               fontsize);
           obj.mean_pixel_um = uicontrol(obj.stat_um_panel,'Style','text',...
               'Units','normalized','Position',[text_width+2*X newY edit_width height],'FontUnits','normalized','FontSize',...
               fontsize);
           newY = newY + height + Y;
         
           % Max pixel edit and text
           %{
           uicontrol(obj.stat_um_panel,'Style','text','String','Max Area','Units',...
               'normalized','Position',[X newY text_width height],'FontUnits','normalized','FontSize',...
               fontsize);
           %}
           uicontrol(obj.stat_um_panel,'Style','text','String','Max Maj. Axis Length','Units',...
               'normalized','Position',[X newY text_width height],'FontUnits','normalized','FontSize',...
               fontsize);
           obj.max_pixel_um = uicontrol(obj.stat_um_panel,'Style','text',...
               'Units','normalized','Position',[text_width+2*X newY edit_width height],'FontUnits','normalized',...
               'FontSize',fontsize);
           newY = newY + height + Y;
           
           % Min pixel edit and text
           %{
           uicontrol(obj.stat_um_panel,'Style','text','String','Min Area','Units',...
               'normalized','Position',[X newY text_width height],'FontUnits','normalized','FontSize',...
               fontsize);
           %}
           uicontrol(obj.stat_um_panel,'Style','text','String','Min Maj. Axis Length','Units',...
               'normalized','Position',[X newY text_width height],'FontUnits','normalized','FontSize',...
               fontsize);
           obj.min_pixel_um = uicontrol(obj.stat_um_panel,'Style','text',...
               'Units','normalized','Position',[text_width+2*X newY edit_width height],'FontUnits','normalized',...
               'FontSize',fontsize);
       end
       
       function conversion_changed(obj)
       %CONVERSION_CHANGED Callback function for conversion factor text
       %edit box.
       % Sets conversion factor in microns/pixel between camera pixel ROI 
       % areas to real ROI area in microns.
       
           % Checks if conversion factor text edit box or pixel statistics
           % are present
           if isempty(obj.min_pixel.String) || isempty(obj.conversion_factor.String)
               obj.min_pixel_um.String = "";
               obj.max_pixel_um.String = "";
               obj.mean_pixel_um.String = "";
               obj.median_pixel_um.String = "";
              return; 
           end
           
           % Update ROI micrometer statistics
           %{
           conv_factor = (str2double(obj.conversion_factor.String))^2;
           
           obj.min_pixel_um.String = num2str(conv_factor*str2double(obj.min_pixel.String));
           obj.max_pixel_um.String = num2str(conv_factor*str2double(obj.max_pixel.String));
           obj.mean_pixel_um.String = num2str(round(conv_factor*str2double(obj.mean_pixel.String),2));
           obj.median_pixel_um.String = num2str(conv_factor*str2double(obj.median_pixel.String));
           %}
           conv_factor = str2double(obj.conversion_factor.String);
           ma_length = obj.table_data.MajorAxisLength;
           obj.min_pixel_um.String = num2str(conv_factor*min(ma_length));
           obj.max_pixel_um.String = num2str(conv_factor*max(ma_length));
           obj.mean_pixel_um.String = num2str(round(conv_factor*mean(ma_length)));
           obj.median_pixel_um.String = num2str(conv_factor*median(ma_length));
           %}
       end
       
       function min_max_changed(obj)
       %MIN_MAX_CHANGED Callback function for min and max pixel text edit
       %boxes.
       % Notifies 'AreaFilter' event listeners to indicate new area
       % parameters have been set.
       
           % Notify 'AreaFilter' event listeners
           notify(obj,'AreaFilter');
       end
       
       function update_stats(obj,mask)
       %UPDATE_STATS Updates displayed ROI statistics values.
       % Given a binary ROI mask, extracts area, centroid, major axis
       % length, minor axis length, and perimeter values for each marked
       % ROI. After ensuring there is at least one ROI, updates displayed
       % statistics.
       
           % Create labeled binary mask
           temp_mask = bwlabel(mask,obj.parent_class.connectivity);
           
           % Extract ROI statistics
           obj.table_data = regionprops('table',temp_mask,'Area', 'Centroid', 'MajorAxisLength', 'MinorAxisLength', 'Perimeter');
           area = obj.table_data.Area;
           % Ensure at least one ROI was identified
           
           if isempty(area)
               % If no ROIs, set all displays to empty
               obj.min_pixel.String = "";
               obj.max_pixel.String = "";
               obj.mean_pixel.String = "";
               obj.median_pixel.String = "";
               obj.cell.String = "";
               obj.min_pixel_edit.String = "";
               obj.max_pixel_edit.String = "";
           else
               % Update displays with new ROI values
               obj.min_pixel.String = num2str(min(area));
               obj.max_pixel.String = num2str(max(area));
               obj.mean_pixel.String = num2str(round(mean(area),2));
               obj.median_pixel.String = num2str(median(area));
               obj.cell.String = length(area);

               obj.min_pixel_edit.String = num2str(min(area));
               obj.max_pixel_edit.String = num2str(max(area));
           end
           %}
           
           % Update micron displays if conversion factor was defined
           obj.conversion_changed();
       end
       
       function enable_edits(obj, val)
       %ENABLE_EDITS Set enabled status for object min, max, and conversion
       %factor text edit boxes.
       % Function expects a 'val' of either 'on' or 'off' to indicate
       % updated status. Sets object text edit boxes to passed 'val'.
       
           % Check validity of 'val' and set properties accordingly
           if strcmp(val,'on') || strcmp(val,'On')
               obj.max_pixel_edit.Enable = val;
               obj.min_pixel_edit.Enable = val;
               obj.conversion_factor.Enable = val;
           elseif strcmp(val,'off') || strcmp(val,'Off')
               obj.max_pixel_edit.Enable = val;
               obj.min_pixel_edit.Enable = val;
               obj.conversion_factor.Enable = val;
           else
               error('Enable property must be set to either ''on'' or ''off''.');
           end
       end
   end
    
end
