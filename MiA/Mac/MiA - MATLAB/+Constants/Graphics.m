classdef Graphics
%GRAPHICS Constant class of Graphic properties.
%      GRAPHICS creates a new GRAPHICS class object instance within the parent 
%      class.
%
%      H = GRAPHICS returns the handle to a new GRAPHICS tool, holding data 
%      values relevant to GUI creation.
% 
%      This class was constructed to maintain consistent graphical format
%      across any program additions. Please use the values below for
%      spacing, font size, and figure positioning. Missing graphical values
%      may be edited at the user's discretion; however, to avoid graphical
%      errors, the constants already in this class should never be changed.
%      Given the use of normalized units, they'll likely require adjustment
%      depending on the addition.

% Last Modified by JONATHAN HOOD v3.0 Sep-2022

% MiA Constants package providing program-wide constants for
% graphical/mathematical support.
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
        % Constant graphics properties: DO NOT EDIT
        Y = 0.04;                            % Normalized constant spacing in the y-dir
        X = 0.03;                            % Normalized constant spacing in the x-dir
        OBJ_WIDTH = 0.92;                    % Normalized constant width of a full-width object (assumes an x-space on each side)
        OBJ_HEIGHT = 0.05;                   % Normalized constant height of a partial-height object
        FIG_POS_INITIAL = [0 0.85 0.5 0.10]; % Normalized constant initial position of a pop-up figure object
        FIG_POS_HALF = [0 0.5 0.5 0.45];     % Normalized constant initial position of a 1/4 screen-fill figure object
        FIG_POS_FULL = [0.05 0.1 0.8 0.7];   % Normalized constant initial position of a mostly screen-filled figure object
        FIG_FILL = [0 0 1 1];                % Normalized constant initial position of a screen-filled figure object
        FONT_SIZE_LARGE = 0.6;               % Normalized constant large font size
        FONT_SIZE_MEDIUM = 0.4;              % Normalized constant medium font size
        FONT_SIZE_SMALL = 0.2;               % Normalized constant small font size
    end
    
    methods
        function obj = Graphics()
            %GRAPHICS Construct an instance of the graphics object
            %   Creates Graphics object for the sole purpose of having
            %   accessible Constant properties.
        end
    end
end

