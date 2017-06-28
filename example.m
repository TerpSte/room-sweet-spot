%% Room Sweet-Spot Calculation - Usage Example
% This script presents a simple example on the usage of the room-sweet-spot
% repo code. It just initializes all the necessary parameters with some
% values and then starts the calculateSweetSpot(), the main function of
% this calculator.
%
% Author:    Terpinas Stergios
% Created:   05/03/2017
% Last edit: 05/03/2017
%
% See also: calculateSweetSpot.m
%

warning('off','all');   % Since MATLAB R2016, this will produce a huge 
warning;                % amount of warnings, for methods that will become
                        % deprecated. It should be OK to turn them off.

setup = 'stereo';       % The setup type
X = [-2 2];             % The x-dimension range
Y = [-5.15 -2.15];      % The y-dimension range
reso = 21;              % The resolution of the grid
brir = 'C:\Repos\room-sweet-spot\brirStruct.mat'; % The BRIRs' struct mat file
phi = pi/2;             % The listener's orientation
img = [0,0];            % The position of the image source
L = 2;                  % The speakers' distance
crit = 5;               % The critical angle 

% Calling the main function
outputStruct = calculateSweetSpot(setup,X,Y,reso,'brir',brir,'phi',phi,'img',img,...
    'L',L,'crit',crit,'doSave',1,'doPlot',1);