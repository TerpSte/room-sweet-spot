function resultMatrix = applyMask(matrixToMask, criticalValue)
% This function applies a mask on a given matrix. Any value over the 
% threshold is replaced with the threshold. The output matrix has the same
% dimensions as the input one but each value is the difference of the
% threshold value normalized in the [0,1].
%
% Inputs:
%   matrixToMask    - the matrix to be masked
%   criticalValue   - the critical threshold value
%
% Outputs:
%   resultMatrix    - the masked matrix
%
% Author:    Terpinas Stergios
% Created:   27/02/2017
% Last edit: 03/03/2017
%
% See also: calculateSourceDirections.m calculateSweetSpot.m
% 

if nargin<2
    error('Not enough input arguments');
end

% Absolute values
matrixToMask = abs(matrixToMask); 

% Filter NaN values
matrixToMask(isnan(matrixToMask)) = min(min(matrixToMask));

% Apply threshold
matrixToMask(matrixToMask > criticalValue) = criticalValue;

% Calculate masked matrix
resultMatrix = ( criticalValue - matrixToMask ) / criticalValue;



