classdef status_bar < handle
%STATUS_BAR Secondary MATLAB graphics object
%      STATUS_BAR creates a new STATUS_BAR class object instance 
%      within the parent class or creates a nonfunctional GUI representation.
%
%      H = STATUS_BAR returns the handle to a new STATUS_BAR tool, 
%      displaying GUI interfaces and handling input values relevant to 
%      the status of the parent application.
% 
%      This class was constructed to display status updates graphically to
%      the user while simultaneously recording it in a log file.
% 
%      This class can be run on its own; in that case, it is a nonfunctional 
%      representation of the graphic objects inherent in this class. This 
%      is primarily used for troubleshooting and preview purposes.

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

    properties(Access = public)
        Tag = 'Status Bar';                 % class object tag, to allow identification with Matlab's findobj command
    end
    
    properties
        % Class graphic constants
        CONSTANTS = Constants.Graphics();   % set of graphic constants
        
        % Class GUI objects
        fig_handle = [];                    % handle to status bar parent figure
        bar_handle = [];                    % handle to status bar inset uipanel
        axes_handle = [];                   % handle to inset progress bar axes
        text_handle = [];                   % handle to inset program status text
        
        % Status bar object properties
        filepath = [];                      % filepath to program log file
        Visible = 'on';                     % indicates whether status bar is visible or not; default is 'on'
        count = 0;                          % double that tracks log file line number
        x_text_Pos = [];                    % x-position of program status text
        x_axes_Pos = [];                    % x-position of progress bar axes
    end
    
    events
        Status_Update   % Status_Update event, indicating an event has occurred significant enough to display to the user
        SelectionMade   % SelectionMade event, indicating a file or directory has been selected. Necessary to function with file_select_display properly
    end
    
    methods
        function obj = status_bar(parent)
            %STATUS_BAR Constructs a status bar manager object
            % If given a parent object, creates status bar on given object.
            % Otherwise, creates standalone blank_figure with status bar.
            
            % Check number of input arguments
            if nargin == 1
                obj.fig_handle = parent;
            else
                obj.fig_handle = Figure.blank_figure().fig_handle;
            end
            
            % Set status bar positioning values
            barPos = [0 0 1 0.03];
            axPos = [0 0.02 0.05 0.96];
            txtPos = [0.06 0.02 0.94 0.96];
            obj.x_text_Pos = 0.06;
            obj.x_axes_Pos = 0;
            
            % Create and start new log file in working directory
            obj.filepath = [pwd '\log.txt'];
            %***IMPORTANT: Comment out the next TWO lines when creating a new
            %executable
            %if isfile(obj.filepath); fclose('all'); delete(obj.filepath); end
            %diary(obj.filepath);
            
            % Create progress bar axes and status text
            obj.bar_handle = uipanel(obj.fig_handle,'Units','normalized',...
                'Position',barPos);
            obj.axes_handle = axes('Parent', obj.bar_handle, ...
            'XLim',[0 100],...
            'YLim',[0 1],...
            'Box','on', ...
            'Units','normalized',...
            'Position',axPos,...
            'XTickMode','manual',...
            'YTickMode','manual',...
            'XTick',[],...
            'YTick',[],...
            'XTickLabelMode','manual',...
            'XTickLabel',[],...
            'YTickLabelMode','manual',...
            'YTickLabel',[],...
            'Visible', 'off');
            
            obj.text_handle = uicontrol(obj.bar_handle,'Style','text','String',...
                '','Units','normalized','Position', txtPos,...
                'HorizontalAlignment','Left','FontUnits','normalized',...
                'FontSize',0.8,'Tag','Status Bar');
            obj.text_handle.Position(1) = obj.x_axes_Pos;
            
        end
        
        function set.Visible(obj,vis)
            %SET.VISIBLE Sets status bar visibility.
            % Sets visibility of status bar GUI objects to the value of
            % 'vis'.
            
            if strcmp(vis,'on') || strcmp(vis,'On')
                obj.Visible = 'On';
                obj.bar_handle.Visible = 'on'; %#ok<MCSUP> accessed to ensure entire bar disappears
            else
                obj.Visible = 'Off';
                obj.bar_handle.Visible = 'off'; %#ok<MCSUP> see line 76
            end
        end
        
        function obj = update_status(obj,evntData)
            %UPDATE_STATUS Sets status bar text to the value passed  in
            %'evntData'.
            % Sets status bar text to the value in 'evntData'. Turns on the
            % logfile diary and records status update in the logfile.
            
            % Get text
            text = evntData.newValue;
            
            % Patched error; if leftover status command is sent after
            % figure deletion, return
            if ~isvalid(obj.text_handle)
                return;
            end
            
            % Display text
            obj.text_handle.String = text;
            
            % Ensure log is recording: 
            %***IMPORTANT: Comment out the next line when creating a new
            %executable
            %diary on
            
            % Print text to command window; diary command records
            % everything written to window
            text = regexprep(text,'\','\\\');
            fprintf(['\n' obj.count text '\n']);
        end
        
        
    end
end

