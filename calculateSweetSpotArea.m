function sweetSpotArea = calculateSweetSpotArea(xRange,yRange,resolution,sweetSpot)
% This function calculates the sweet-spot area, given a sweet-spot map and
% the specifications of the listening area, as in [1].
%
% Inputs:
%   xRange          - the extent of the listening area in x dimension
%   yRange          - the extent of the listening area in y dimension
%   resolution      - the resolution of the listening area
%   sweetSpot       - the sweet-spot map
%
% Outputs:
%   sweetSpotArea   - the resulting sweetSpotArea in sq. cm
%
% Reference:
% [1] Kamaris, G., Karlos, S., Fazakis, N., Terpinas, S., & Mourjopoulos, J.
%     “Binaural Auditory Feature Classification for Stereo Image Evaluation
%     in Listening Rooms.”, 140th Audio Engineering Society Convention, 
%     Paris, June 2016
%
% Author:   Terpinas Stergios
% Created:  03/03/2017
% Las edit: 03/03/2017
%
% See also: calculateSweetSpot.m
%

if nargin<4
    error('%s: Not enough input arguments.',uppper(mfilename));
end

% Calculate the smallest possible area for this grid
elementArea = (xRange(2)-xRange(1))*(yRange(2)-yRange(1))/((resolution-1)^2);

% Calculate the sweet-spot area
binaryArray = im2bw(sweetSpot);
sweetSpotArea = elementArea*sum(sum(binaryArray));
