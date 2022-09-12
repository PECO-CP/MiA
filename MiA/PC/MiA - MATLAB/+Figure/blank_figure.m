classdef blank_figure
%BLANK_FIGURE Supplementary GUI subclass; creates completely blank
%figure to allow for complete user customization.
%
%      BLANK_FIGURE creates a new BLANK_FIGURE class object 
%      instance.
%
%      H = BLANK_FIGURE returns the handle to a new BLANK_FIGURE tool, 
%      displaying GUI interfaces and handling input values relevant to 
%      defining a figure. The figure holds a uipanel that acts as the
%      figure container, and is also capable of holding a Figure.status_bar
%      object.
% 
%      This class requires 0-1 input arguments:
%
%       No input : With no input argument, the class creates a blank figure
%                  with an embedded uipanel.
%       [status] : With one input arguments, the class creates a blank
%                  figure with an embedded uipanel and status_bar object.
%                  'status' can be any value.
%                       
%      Object properties fig_handle and panel_handle can be extracted from
%      this class and modified just as a MATLAB figure or uipanel could be.
%      The object property 'status_bar', if activated, holds the status_bar
%      object which can be sent status updates as usual.

% Last Modified by JONATHAN HOOD v3.0 Sep-2022
    

% MiA Figure package providing program-wide graphical support.
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
        % Class graphic constants
        CONSTANTS = Constants.Graphics(); % set of graphics constants
        
        % Class GUI objects
        fig_handle = [];                  % handle to figure
        panel_handle = [];                % handle to panel that holds all figure graphics
        status_bar = [];                  % handle to inset Figure.status_bar object
        
        % blank_figure class properties
        Visible = 'on';                   % value which indicates whether blank_figure is Visible or not; default is 'on'
        Tag = 'Blank Figure';             % class object identification tag
    end
    
    methods
        function obj = blank_figure(status) %#ok<INUSD> any input value indicates activation of status bar, so value of 'status' is unused
        %BLANK_FIGURE Construct a blank normalized figure.
        % Build function for class blank_figure. Creates a MATLAB
        % figure with nothing in it except for a uipanel. If given an
        % input argument, also creates a status bar below the panel.
            
            % Check if user wants a status bar or not
            if nargin == 0
                % Create blank figure
                obj.fig_handle = figure('MenuBar','none','DockControls',...
                    'off','Units','normalized','Position',obj.CONSTANTS.FIG_POS_HALF,...
                    'NumberTitle','off');
                Y = 0;
            else
                % Create blank figure
                
                obj.fig_handle = figure('MenuBar','none','DockControls',...
                    'off','Units','normalized','Position',obj.CONSTANTS.FIG_POS_HALF,...
                    'NumberTitle','off');
                
                % Create status bar
                obj.status_bar = Figure.status_bar(obj.fig_handle);
                Y = obj.status_bar.bar_handle.Position(2) + ...
                obj.status_bar.bar_handle.Position(4);
            end
            
            % Create uipanel within figure
            obj.panel_handle = uipanel(obj.fig_handle,'Units','normalized',...
                'Position',[0 Y 1 1-Y],'BorderType','none');
        end
        
        function obj = set.Visible(obj,vis)
        %SET.VISIBLE Set function for blank_figure visibility.
        % Set object visibility to either 'on' or 'off'.
        
            % Check that input is 'on' or 'off'.
            if strcmp(vis,'on') || strcmp(vis,'On')
                obj.Visible = 'On';
                obj.fig_handle.Visible = 'on'; %#ok<*MCSUP> graphics class; properties are constant
            elseif strcmp(vis,'off') || strcmp(vis,'Off')
                obj.Visible = 'Off';
                obj.fig_handle.Visible = 'off';
            else
                error('Input must be either ''on'' or ''off''.');
            end
        end
    end
end

