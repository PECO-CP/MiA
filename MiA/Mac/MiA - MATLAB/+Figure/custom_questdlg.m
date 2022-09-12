classdef custom_questdlg < handle
%CUSTOM_QUESTDLG Supplementary GUI subclass; creates customized MATLAB
%question dialog box, with/without the option and checkbox 'Do not ask me
%again'.
%
%      CUSTOM_QUESTDLG creates a new CUSTOM_QUESTDLG class object 
%      instance.
%
%      H = CUSTOM_QUESTDLG returns the handle to a new CUSTOM_QUESTDLG tool, 
%      displaying GUI interfaces and handling input values relevant to 
%      a question dialog interface. It also supports and holds the
%      properties of parent Figure object 'dialog'.
% 
%      This class requires 2-3 input arguments:
%
%       [question,options]              : With two input arguments, the 
%                                       class creates a question dialog box
%                                       with displayed question input
%                                       string 'question' and displayed
%                                       options input cell array of
%                                       strings 'options'. Includes a 'Do
%                                       not ask me again' checkbox.
% 
%       [question,options,ask_again]    : With three input arguments, the 
%                                       class creates a question dialog box
%                                       with displayed question input
%                                       string 'question' and displayed
%                                       options input cell array of
%                                       strings 'options'. If ask_again is
%                                       'yes', includes a 'Do not ask me
%                                       again' checkbox. If ask_again is
%                                       'no', does not include the
%                                       checkbox.
% 
%      Object properties question and panel_handle can be extracted from
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
        % Graphics
        fig = [];
        ask_again_checkbox = [];
        
        % Input
        question = [];
        options = [];
        name = '';
        ask_again = 1;
        
        % Output
        default_button = [];
        dont_ask_again_val = 0;
        selection = '';
    end
    
    methods
        function obj = custom_questdlg(question,options,name,ask_again)
            %CUSTOM_QUESTDLG Construct an instance of this class
            %   Detailed explanation goes here
            obj.options = options;
            obj.question = question;
            obj.name = name;
            if nargin == 3
               obj.name = name; 
            elseif nargin == 4
               if strcmpi(ask_again,'no'); obj.ask_again = 0; end
            end
            obj.buildFunc();
        end
        
        function obj = buildFunc(obj)
            %buildFunc Summary of this method goes here
            %   Detailed explanation goes here
            obj.fig = dialog('units','normalized','Position',[0.4 0.4 0.2 0.15],...
                'Name',obj.name);
            
            % Create button options
            num_options = length(obj.options);
            quest_height = 0.3;
            quest_Y = 0.75-quest_height/2;
            fontsize = 0.4;
            quest_fontsize = 0.4;
            btn_width = 0.2;
            btn_space = (1-num_options*(btn_width))/(num_options+1);
            while btn_space < 0
               btn_width = btn_width - 0.001; 
               btn_space = (1-num_options*(btn_width))/(num_options+1);
            end
            
            btn_height = 0.2;
            X_pos = btn_space;
            btn_Y = (quest_Y-btn_height)/2;
            
            % Set default button
            obj.default_button = uicontrol(obj.fig,'units','normalized','Position',...
                    [X_pos btn_Y btn_width btn_height],'String',...
                    obj.options{1},'Callback',@(~,~)obj.exit_Function(),...
                    'FontUnits','normalized','FontSize',fontsize);
            X_pos = X_pos + btn_width + btn_space;
            
            obj.fig.setDefaultButton(obj.default_button);
            
            for i = 2:num_options
                uicontrol(obj.fig,'units','normalized','Position',...
                    [X_pos btn_Y btn_width btn_height],'String',...
                    obj.options{i},'Callback',@(~,~)obj.exit_Function(),...
                    'FontUnits','normalized','FontSize',fontsize);
                X_pos = X_pos + btn_width + btn_space;
            end
            
            % Create question
            uicontrol(obj.fig,'Style','text','units','normalized',...
                'Position',[0 quest_Y 1 quest_height],'String',obj.question,...
                'FontUnits','normalized','FontSize',quest_fontsize);
            
            if obj.ask_again
                ask_again_Y = (btn_Y-btn_height)/2;
                ask_again_text_width = 0.28;
                ask_again_text_height = 0.14;
                check_width = 0.1;
                ask_again_X = 0.5-(check_width+ask_again_text_width)/2;
                check_width = 0.1;
                
                uicontrol(obj.fig,'Style','text','Units','normalized',...
                   'Position',[ask_again_X ask_again_Y ask_again_text_width ask_again_text_height],...
                   'String','Don''t ask me again');  
               
                newX = ask_again_X + ask_again_text_width;
                
                obj.ask_again_checkbox = uicontrol(obj.fig,'Style','checkbox',...
                   'Units','normalized','Position',[newX ask_again_Y check_width btn_height]);   
            end
            uiwait(obj.fig);
        end
        
        function obj = exit_Function(obj)
        %EXIT_FUNCTION Exit function for the various button options of
        %'Yes', 'No', and 'Cancel'.
        
           % Grab current selection string
           obj.selection = get(get(obj.fig,'CurrentObject'),'String');
           
           % If there is no selection, which should not be possible, set
           % the selection to given default value
           if isempty(obj.selection); obj.selection = obj.default_button.String; end
           
           % Set the 'ask again' property if true, since default is false
           if obj.ask_again; obj.dont_ask_again_val = obj.ask_again_checkbox.Value; end
           delete(gcf); 
        end
    end
end

