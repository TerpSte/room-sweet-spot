function outputStruct = calculateSweetSpot(setup,xRange,yRange,resolution,varargin)
% This function calculates the sweet-spot of a set of speakers in a certain
% room, given the binaural room impulse responses (BRIRs) at any position
% of the listening area and the some other specifications. It is based on
% [1].
%
% The input arguments xRange, yRange and resolution are required. Any other
% is optional and can be used in a name-value pair manner.
%
% Inputs:
%   setup       - the setup type; 'stereo' or 'surround'
%   xRange      - extent of the listening area in x dimension (in m)
%   yRange      - extent of the listening area in y dimension (in m)
%   resolution  - resolution of the listening area grid
%   brir        - full path to a BRIRs struct or directory
%   sig         - input excitation signals for each speaker
%   phi         - listeners orientation
%   img         - position of the image source
%   L           - distance of the speakers
%   crit        - critical angle of the sweet-spot mask
%   doSave      - save flag
%   doPlot      - plot flag
%
% Reference:
% [1] Kamaris, G., Karlos, S., Fazakis, N., Terpinas, S., & Mourjopoulos, J.
%     “Binaural Auditory Feature Classification for Stereo Image Evaluation
%     in Listening Rooms.”, 140th Audio Engineering Society Convention, 
%     Paris, June 2016
%
% Author:    Terpinas Stergios
% Created:   28/02/2017
% Last edit: 08/03/2017
%
% See also: brirStructCreator.m calculateSourceDirections.m
%

% Set parser
p = inputParser;
addRequired(p,'setup',@(x) any(validatestring(x,{'stereo','surround'})));
addRequired(p,'xRange',(@(x) (length(x)==2)&&isnumeric(x)));
addRequired(p,'yRange',(@(x) (length(x)==2)&&isnumeric(x)));
addRequired(p,'resolution',(@(x) (x-round(x))==0));
addParameter(p,'brir','brirStruct.mat',(@ischar));
addParameter(p,'sig',0,@isnumeric);
addParameter(p,'phi',pi/2,(@(x) (x>-pi)&&(x<=pi)));
addParameter(p,'img',[0 0],(@(x) (length(x)==2)&&isnumeric(x)));
addParameter(p,'L',2,@isnumeric);
addParameter(p,'crit',5,@isnumeric);
addParameter(p,'doSave',1,(@(x)(x==0)||(x==1)));
addParameter(p,'doPlot',1,(@(x)(x==0)||(x==1)));
parse(p,setup,xRange,yRange,resolution,varargin{:});

% Parse input
brirPath = p.Results.brir;
excitationSignal = p.sig;
listenerOrientation = p.Results.phi;
imgPosition = p.Results.img;
speakerDistance = p.Results.L;
critAngle = p.Results.crit;
doSave = p.Results.doSave;
doPlot = p.Results.doPlot;

% Obtain number of speakers
if strcmp(setup, 'stereo')
    numSpeakers = 2;
else % 'surround'
    numSpeakers = 5;
end

% Check signal
if excitationSignal==0          % The default value from input parser
    excitationSignal = repmat(whitenoiseburst(44100),1,numSpeakers);
elseif size(excitationSignal,2)~=numSpeakers
    error('Incompatible input signal with input setup.');
end    

% Load and set SFS config file
try
    conf = SFS_config;
catch ME
    try
        conf = SFS_config_example;
    catch
        error(['You need to install the Sound-Field-Synthesis Toolbox.\n', ...
                'You can download it at https://github.com/sfstoolbox/sfs.\n']);
    end
end
conf.resolution = resolution;

% Create brir if necessary
if exist(brirPath,'dir')
    brirStruct = brirStructCreator(brirPath,numSpeakers,resolution^2,doSave);
elseif exist(brirPath,'file')
    load(brirPath);
else
    error('The BRIR file/or directory does not exist');
end

% Calculate image source position for surround setup
if strcmp(setup,'surround')
    imgPosition = pol2cartImgSource(imgPosition);
end

% Calculate all directions
[localizationError,perceivedDirection,desiredDirection,x,y] =...
    calculateSourceDirections(xRange,yRange,listenerOrientation,imgPosition,brirStruct,excitationSignal,conf);
    
% Apply mask
sweetSpot = applyMask(localizationError,critAngle);

% Calculate sweet-spot area
sweetSpotArea = calculateSweetSpotArea(xRange,yRange,resolution,sweetSpot);

if doPlot
    % Calculate speakers position
    conf.secondary_sources.geometry = 'linear';
    conf.secondary_sources.center = [0 0 0];
    conf.secondary_sources.x0 = [];
    conf.secondary_sources.number = 2;
    conf.secondary_sources.size = speakerDistance;
    conf.plot.realloudspeakers = true;
    conf.plot.lssize = 0.16;
    x0 = secondary_source_positions(conf);
    
    % Plot DOA
    figure;
    title('Directions of Arrivals');
    [u,v,~] = pol2cart(rad(perceivedDirection+90),ones(size(perceivedDirection)),...
        zeros(size(perceivedDirection)));
    quiver(x,y,u',v',0.5);
    axis([xRange yRange]);
    draw_loudspeakers(x0,[1 1 0],conf);
    xlabel('x/m');
    ylabel('y/m');
    
    % Plot sweet-spot
    figure;
    title('Sweet-Spot');
    surf([0 0;0 0],[0 0;0 0],[1 1;1 1]);
    hold on;
    surf(x,y,sweetSpot','EdgeColor', 'none', 'facecolor', 'interp');
    view([0,90]);
    draw_loudspeakers(x0,[1 1 1],conf);
end

if doSave
    save sweetSpotResults.mat localizationError perceivedDirection...
        desiredDirection x y sweetSpot sweetSpotArea 
end

% Build the output struct
outputStruct.localizationError = localizationError;
outputStruct.perceivedDirection = perceivedDirection;
outputStruct.desiredDirection = desiredDirection;
outputStruct.x = x;
outputStruct.y = y;
outputStruct.sweetSpot = sweetSpot;
outputStruct.sweetSpotArea = sweetSpotArea;

end % calculateSweetSpot

function cartImgSource = pol2cartImgSource(polarImgSource)
    tempCoordinates = pol2cart(deg2rad(90 - polarImgSource(2)),polarImgSource(1));
    stereoSurroundDistance = [0,polarImgSource(2)/(2*tand(30))];
    cartImgSource = tempCoordinates - stereoSurroundDistance;
end



