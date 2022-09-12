classdef ActionData < event.EventData
%ACTIONDATA Minimalistic EventData subclass
%      ACTIONDATA creates a new ACTIONDATA class object instance 
%      within the parent class.
%
%      H = ACTIONDATA returns the handle to a new ACTIONDATA object, a
%      wrapper class for passing EventData of any type from one class to
%      another via 'notify' and 'addlistener' functions.

% Last Modified by JONATHAN HOOD v3.0 Sep-2022

% MiA Events package providing program-wide EventData wrapper class for
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
      newValue % Value to be passed as EventData to the listener
   end
    
   methods
       function obj = ActionData(newVal)
        %ACTIONDATA Constructs an ActionData object instance
        % This object acts as an minimalistic wrapper class for passing any
        % data value as EventData.
        
          % Wrap input value as an EventData property
          obj.newValue = newVal; 
       end
   end
    
    
end