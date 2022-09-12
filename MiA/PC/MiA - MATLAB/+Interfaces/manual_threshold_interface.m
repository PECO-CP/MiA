classdef manual_threshold_interface < handle
%MANUAL_THRESHOLD_INTERFACE Secondary MATLAB tool; child of image_analysis 
% parent class
%      MANUAL_THRESHOLD_INTERFACE creates a new MANUAL_THRESHOLD_INTERFACE 
%      class object instance within the parent class or creates a 
%      nonfunctional GUI representation.
%
%      H = MANUAL_THRESHOLD_INTERFACE returns the handle to a new 
%      MANUAL_THRESHOLD_INTERFACE tool, displaying GUI interfaces and 
%      holding data values relevant to changing ROI threshold values.
% 
%      This class was constructed to operate solely with the properties and 
%      objects of parent class analyze in package Interfaces.
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
       % Threshold Selection GUI objects
       threshold_slider % handle to image threshold selection object within image threshold panel
       threshold_edit   % handle to image threshold text edit box object within image threshold panel
       thresh_panel     % handle to image threshold uipanel object within image threshold figure
       fig_handle       % handle to image threshold figure
       
       % Minimum Pixel Area Filter GUI objects
       pix_panel        % handle to image threshold pixel filter panel
       pix_val_edit     % handle to image threshold pixel filter text edit box
       
       % Confirm Outlines GUI object and Data
       confirm_btn      % handle to image threshold ROI outline confirmation button
       confirmed = 0;   % indicator as to whether the outlines have been confirmed (1) or not confirmed (0)
 
       % Instance-specific data
       Tag              % object manual interface identification value
                            %   'single' : indicates manual threshold one ROI in the selected region
                            %   'all'    : indicates manual threshold all ROIs in the image
                            %   'multi'  : indicates manual threshold multiple ROIs in the selected region
       UserData         % object UserData holds input object's UserData
   end
   
   events
      Status_Update     % Status_Update event, indicating an event has occurred significant enough to display to the user
      ThresholdChanged  % ThresholdChanged event, indicating that the thresholdhing level for a 'Manual Interface Threshold' GUI has been changed
   end
   
   methods
       function obj = manual_threshold_interface(level,src)
       %MANUAL_THRESHOLD_INTERFACE Build function for class manual_threshold_interface.
       % If given no input arguments, creates a nonfunctional Figure
       % representation of the class. Otherwise, requires two input
       % arguments;
       %    
       %        level : Threshold value (double)
       %
       %          src : Object that created this object; expected to be one
       %                of the 'Manual Threshold' uimenu tools from class
       %                image_analysis.
       %
       % This class was intended to operate with parent class
       % image_analysis. Functional use with other classes is not
       % currently supported; however, graphical use is.
       
           % Check number of input arguments
           if nargin == 0
              level = 0.2;
              src.Tag = '';
           elseif nargin ~=2
               error('Manual Threshold Interface requires either no input or two input arguments.')
           end
           
           % Check which uimenu option activated this object
           if strcmp(src.Tag,'single') || strcmp(src.Tag,'all') || strcmp(src.Tag,'multi')
               obj.Tag = src.Tag;
               if strcmp(src.Tag,'single') || strcmp(src.Tag,'multi')
                   obj.UserData = src.UserData;
               end
           else
               obj.Tag = 'all';
           end
           
           % Set figure graphic constants
           slider_width = 0.1;
           edit_height = 0.08;
           edit_width = 0.3;
           btn_height = 0.2;
           X = 0.02;
           Y = 0.02;
           
           % Create new figure and set properties
           obj.fig_handle = Figure.blank_figure().fig_handle;
           obj.fig_handle.Name = 'Threshold Editor';
           obj.fig_handle.Tag = 'manual_threshold_interface';
           obj.fig_handle.CloseRequestFcn = @(~,~)obj.closefig();
           
           %%%%%%%%%%%%%%%%%%%%%%%%%%
           % ADVANCED OPTIONS PANEL %
           %%%%%%%%%%%%%%%%%%%%%%%%%%
           
           % Min pixel area uipanel
           obj.pix_panel = uipanel(obj.fig_handle,'Units','normalized',...
               'Position',[0 0 1 0.3],'Title','Advanced Options');
           
           pix_edit_height = edit_height + 0.2;
           
           % Min pixel text edit box
           obj.pix_val_edit = uicontrol(obj.pix_panel,'Style','Edit','String',...
               '50','Units','normalized','Position',[X 0.5-pix_edit_height/2 edit_width pix_edit_height],...
               'Callback',@(src,~)obj.thresh_val_changed(src),'Tag','PixEdit');
           
           pix_text_x = obj.pix_val_edit.Position(1) + obj.pix_val_edit.Position(3) + X;
           
           % Min pixel string description
           uicontrol(obj.pix_panel,'Style','text','String','Minimum pixel cutoff size',...
               'Units','normalized','Position',[pix_text_x obj.pix_val_edit.Position(2)...
               1-pix_text_x pix_edit_height-.05],'FontSize',9,'HorizontalAlignment',...
               'Left');
           
           %%%%%%%%%%%%%%%%%%%%%%%%%
           % THRESHOLD LEVEL PANEL %
           %%%%%%%%%%%%%%%%%%%%%%%%%
           
           % Create threshold uipanel
           obj.thresh_panel = uipanel(obj.fig_handle,'Units','normalized',...
               'Position',[0 0.3 1 0.7],'Title','Select threshold level');
           
           % Create threshold vertical slider
           obj.threshold_slider = uicontrol(obj.thresh_panel,'Style','Slider','Min',0,'Max',1,...
               'Units','normalized','Position',[1-slider_width-X Y slider_width 1-2*Y],...
               'Tag','Slider','Callback',@(src,~)obj.thresh_val_changed(src),...
               'Value',level);
           
           % Confirm outlines button
           obj.confirm_btn = uicontrol(obj.thresh_panel,'Style','pushbutton',...
               'String','Confirm Outlines','FontSize',9,'Units','normalized',...
               'Position',[X 3*Y edit_width+0.1 btn_height],'Callback',...
               @(src,~)obj.thresh_val_changed(src),'Tag','confirm_outlines');
           
           % Text edit box for threshold value
           obj.threshold_edit = uicontrol(obj.thresh_panel,'Style','Edit','String',...
               num2str(level),'Units','normalized','Position',[obj.threshold_slider.Position(1)-X-edit_width obj.threshold_slider.Position(4)/2-edit_height/2 edit_width edit_height],...
               'Callback',@(src,~)obj.thresh_val_changed(src),'Tag','ThreshEdit');
           
           % Threshold value string description
           uicontrol(obj.thresh_panel,'Style','text','String','Threshold level:',...
               'Units','normalized','Position',[X obj.threshold_edit.Position(2) obj.threshold_edit.Position(1)-X edit_height],...
               'HorizontalAlignment','left','FontSize',9);
           
           % Set Figure width and height to resize children automatically
           obj.fig_handle.Position(3) = 0.15;
           obj.fig_handle.Position(4) = 0.3;
           
       end
       
       function thresh_val_changed(obj,src)
       %THRESH_VAL_CHANGED Callback function for threshold text edit box
       %and threshold slider, as well as 'Confirm Outlines' pushbutton.
       % Input argument 'src' indicates which GUI object activated this
       % callback and adjusts the other to match set threshold value.
       % Notifies 'ThresholdChanged' event listeners that the threshold
       % value has been adjusted.
        
           % Set pointer to 'watch' to indicate system is busy
           obj.fig_handle.Pointer = 'watch';
           
           % Grab min pixel area
           pix_val = str2double(obj.pix_val_edit.String);
           
           % Check GUI 'src' input
           if strcmp(src.Tag,'ThreshEdit')
               % Grab new threshold value and set slider value to match
               newVal = str2double(src.String);
               obj.threshold_slider.Value = newVal;
           elseif strcmp(src.Tag,'Slider')
               % Grab new threshold value and set text edit value to match
               newVal = src.Value;
               obj.threshold_edit.String = num2str(newVal);               
           else
               % Grab new threshold value and set 'confirmed' to true;
               % delete figure
               newVal = obj.threshold_slider.Value; 
               if strcmp(src.Tag,'confirm_outlines')
                  obj.confirmed = 1; 
                  delete(obj.fig_handle);
               end
           end
           
           % Notify 'ThresholdChanged' event listeners and pass new
           % threshold value and min pixel area
           notify(obj,'ThresholdChanged',Events.ActionData([newVal pix_val]));
       end
       
       function closefig(obj)
       %CLOSEFIG Figure close function and 'Cancel' pushbutton callback.
       % Notifies 'ThresholdChanged' event listeners and passed null values
       % to eliminate any outlines previously defined with this interface.
       % Eliminates interface figure.
       
           % Notify 'ThresholdChanged' event listeners and pass null values
           notify(obj,'ThresholdChanged',Events.ActionData([-1 8000]));
           
           % Delete figure interface
           delete(obj.fig_handle);
       end
   end
    
    
    
end