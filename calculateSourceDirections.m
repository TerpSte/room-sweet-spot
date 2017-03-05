function [localizationError,perceivedDirection,desiredDirection,x,y] =...
    calculateSourceDirections(xRange,yRange,listenerOrientation,imgSource,brir,conf)
% This function calculates the perceived and the ideal directions of the
% sound that reaches the different listening positions of a listening area. 
%
% Inputs:
%   xRange              - listening area extent in x dimension, e.g. [-2 2]
%   yRange              - listening area extent in y dimension, e.g. [-2 2]
%   listenerOrientation - the orientation of the listener (in rad)
%   imgSource           - the position of the image source, e.g. [0 0]
%   brir                - the BRIR struct created with brirStructCreator
%   conf                - the SFS configuration file
%
% Outputs:
%   localizationError   - the differences between the perceived and ideal
%                         source directions
%   perceivedDirection  - the perceived source directions as calculated fro
%                         the binaural model
%   desiredDirection    - the ideal source directions, basically the line
%                         connecting the image source and the listener 
%
% Modified by:  Terpinas Stergios
% Created:      27/02/2017
% Last edit:    05/03/2017
%
% Author:       Hagen Wierstorf
% Based on:     wierstorf2013.m of
%               amtoolbox [https://github.com/hagenw/amtoolbox]
%
% See also: brirStructCreator.m
%

% Load lookup table
lookup = load(fullfile(amtbasepath, 'hrtf','wierstorf2013','wierstorf2013itd2anglelookup.mat'));

% The grid that contains the listening positions
[~,~,~,x,y] = xyz_grid(xRange,yRange,0,conf);

% Obtain parameters
fs = conf.fs;
reso = conf.resolution;

% 700 ms white noise burst as excitation signal
sig_noise = whitenoiseburst(fs);
sig_left = sig_noise;
sig_right = sig_noise;

% Initialize waitbar
wBar = waitbar(0,'Please wait while processing...');

for ii=1:length(x)
    for jj=1:length(y)
        % Update waitbar
        waitbarPosition = (ii-1)*reso + jj;
        waitbar((waitbarPosition/(reso^2)), wBar);
        drawnow();
    
        % Position vector
        X = [x(ii) y(jj)];
        
        % Calculate current desired direction
        desiredDirection(ii,jj) = sourceDirection(X,listenerOrientation,imgSource);
        
        % Calculate current position in brir array
        position = ii + (reso-jj)*reso;
        
        % First loudspeaker
        ir1(:,1) = brir{1}.left(:,position);
        ir1(:,2) = brir{1}.right(:,position);
        sig1 = auralize_ir(ir1,sig_left,1,conf);
        
        % Second loudspeaker
        ir2(:,1) = brir{2}.left(:,position);
        ir2(:,2) = brir{2}.right(:,position);
        sig2 = auralize_ir(ir2,sig_right,1,conf);
        
        % Add the two signals and normalize
        sig = (sig1+sig2)./2;
        
        % Estimate perceived direction using Dietz 2011 binaural model
        perceivedDirection(ii,jj) = wierstorf2013estimateazimuth(sig,lookup, ...
            'dietz2011','no_spectral_weighting','remove_outlier');
        
        % The localization error is the difference between the perceived
        % and the ideal direction of the audio source
        localizationError(ii,jj) = perceivedDirection(ii,jj)-desiredDirection(ii,jj);

    end
end

close(wBar);

end

%% ----- Subfunctions ----------------------------------------------------
function direction = sourceDirection(X,phi,xs)
    x = xs-X;
    [direction,~] = cart2pol(x(1),x(2));
    direction = (direction-phi)/pi*180;
end

