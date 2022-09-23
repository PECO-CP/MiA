# MiA - Microbial Image Analysis
MiA is a MATLAB-based, open-source program for analyzing epifluorescence microscopy images of microorganisms. The program can be run through MATLAB (on a Mac or PC) or can be downloaded as an executable and run through the freely available MATLAB runtime environment.

## Overview of Program and Case Studies
The MiA program aims to provide flexibility for the selection, identification, and quantification of cells that vary in size and fluorescence intensity (natural or probe-conferred) within natural microbial communities or cultures. Additionally, MiA has a cell-ID feature that enables the user to define and classify regions of interest (ROIs) real-time during image analysis. The program enables the user to export data in easy-to-use formats, facilitating downstream analysis.

The materials from the case studies featured in the manuscript including microscopy images and suggested analyses are included in the 'Case Studies' folder within this repository. 

**The case studies include images from**
1) a natural mixed phytoplankton community from a coastal environment
2) a mixed culture of the dinoflagellate grazer *Oxyrrhis marina* and phytoplankton *Dunaliella tertiolecta* 

## How to install and run programs
Detailed instructions for installing, running, and using MiA can be found in the manual located in the 'Manuals' folder within this repository. The manual also comes prepackaged with the program download.

**Quick Install Guide**

*MATLAB Version*
1. Download the MiA program files appropriate for your system (Mac or Windows).
2. Open MATLAB and navigate to the proper working directory (e.g., the folder you saved the script files in).
3. The scripts to run the program are organized into a series of MATLAB packages. They can be distinguished by the ’+’ present in every folder’s name. **The primary file to run is located in the ’+Interfaces’ package and is labelled ’image_analysis.m’ (for MiA)**
4. To run the program, you can either open up the ’image_analysis’ file in the command window and click ’Run’ or run it from MATLAB’s command window by calling the script directly.

*Executable Version*
1. Download the MiA executable program appropriate to your system (Mac or Windows). 
2. Navigate to the location of the executable installer on your computer and open it. A pop-up may appear verifying the download with publisher ’Unknown’. Follow the instructions of the program, including selecting an installation location. Once you do so and accept the Mathworks licensing agreement, the download will begin. (NOTE: The program will not download the runtime environment if it detects it has already been downloaded). If needed, you can download the runtime environment [HERE]. *Please see the manaul for details about permissions that may be required for Mac users*
3. To run the program, the executable will be located within the ’application’ sub-folder of the folder you selected for installation. The program will either be an .exe or .app file depending if you installed it onto a PC or Mac, respectively. Double-click the .exe (or .app) file and the program will start up. 

