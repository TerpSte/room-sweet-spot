function outputStruct = calculateSweetSpot(xRange,yRange,resolution,varargin)
% This function calculates the sweet-spot of a set of speakers in a certain
% room, given the binaural room impulse responses (BRIRs) at any position
% of the listening area and the some other specifications. It is based on
% [1].
%
% The input arguments xRange, yRange and resolution are required. Any other
% is optional and can be used in a name-value pair manner.
%
% Inputs:
%   xRange      - extent of the listening area in x dimension (in m)
%   yRange      - extent of the listening area in y dimension (in m)
%   resolution  - resolution of the listening area grid
%   brir        - full path to a BRIRs struct or directory
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
% Last edit: 03/03/2017
%
% See also: brirStructCreator.m calculateSourceDirections.m
%

% Set parser
p = inputParser;
addRequired(p,'xRange',(@(x) (length(x)==2)&&isnumeric(x)));
addRequired(p,'yRange',(@(x) (length(x)==2)&&isnumeric(x)));
addRequired(p,'resolution',(@isinteger));
addParameter(p,'brir','brirStruct.mat',(@isstring));
%addParameter(p,'sig',whitenoiseburst(44100),@isnumeric);
addParameter(p,'phi',pi/2,(@(x) (x>-pi)&&(x<=pi)));
addParameter(p,'img',[0 0],(@(x) (length(x)==2)&&isnumeric(x)));
addParameter(p,'L',2,@isnumeric);
addParameter(p,'crit',5,@isnumeric);
addParameter(p,'doSave',1,(@(x)(x==0)||(x==1)));
addParameter(p,'doPlot',1,(@(x)(x==0)||(x==1)));
parse(p,xRange,yRange,resolution,varargin{:});

% Parse input
brirPath = p.brir;
%excitationSignal = p.sig;
listenerOrientation = p.phi;
imgPosition = p.img;
speakerDistance = p.L;
critAngle = p.crit;
doSave = p.doSave;
doPlot = p.doPlot;

% Load SFS config file
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

% Create brir if necessary
if exist(brirPath,'directory')
    brirStruct = brirStructCreator(brirPath,2,resolution^2,doSave);
elseif exist(brirPath,'file')
    load brirPath;
else
    error('The BRIR file/or directory does not exist');
end

% Calculate all directions
[localizationError,perceivedDirection,desiredDirection,x,y] =...
    calculateSourceDirections(xRange,yRange,listenerOrientation,imgPosition,brirStruct,conf);
    
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
    [u,v,~] = pol2cart(rad(aud_event+90),ones(size(aud_event)),zeros(size(aud_event)));
    quiver(xaxis,yaxis,u',v',0.5);
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
        desiredDirection x y sweetSpotArea 
end




