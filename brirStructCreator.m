function brirStruct = brirStructCreator(rootPath,numSpeakers,numPositions,saveFile)
% This function creates a struct that contains all the BRIRs needed from
% the calculateSourceDirection function. It requires the root path of the
% BRIR files. The directory should be organized with one subdirectory per
% speaker/source, named only with its index, starting from 1 (1, 2, 3, ...)
%
% Inputs:
%   rootPath     - the root path that contains the BRIR files
%   numSpeakers  - the number of speakers/sources
%   numPositions - the number of positions
%   saveFile     - [optional] file save flag
%
% Outputs:
%   brirStruct   - the output struct; a cell array with one cell per
%                  speaker; each cell has a left and a right field
%
% Author:    Terpinas Stergios
% Created:   27/02/2017
% Last edit: 05/03/2017
%
% See also: calculateSourceDirections.m calculateSweetSpot.m
%

% Check number of input arguments
if nargin < 3
    error('Not enough input arguments.');
end

% If not specified otherwise, the function should save the BRIRs by default
if nargin < 4
    saveFile = 1;
end

% Iterate over every loudspeaker
for iSpeaker = 1:numSpeakers    
    % Full path for current speaker
    speakerDirectory = [rootPath, num2str(iSpeaker)];
    
    % Obtain the filelist of the directory
    brirFiles = dir(speakerDirectory);
    
    % Find the length of the biggest file
    [~,maxIdx] = max([brirFiles.bytes]);
    biggestFile = [speakerDirectory,filesep,brirFiles(maxIdx).name];
    someInfo = audioinfo(biggestFile);
    N = someInfo.TotalSamples;
    
    % Initialize matrices for this speaker
    brirStruct{iSpeaker}.left = zeros(N,numPositions);
    brirStruct{iSpeaker}.right = zeros(N,numPositions);
    
    % Load BRIRs
    iBRIR = 1;
    for iFile=1:length(brirFiles)
        filename = [speakerDirectory,filesep,brirFiles(iFile).name];
        if ~isempty(strfind(filename,'.WAV')) % Check if is wav
            % Load audiofile
            [brir,~] = audioread(filename);
            
            % Load BRIR for left ear
            brirStruct{iSpeaker}.left(:,iBRIR) = fix_length(brir(:,1),N);
            
            % Load BRIR for right ear according to the number of channels
            if(size(brir,2) == 1) 
                brirStruct{iSpeaker}.right(:,iBRIR) = fix_length(brir(:,1),N); 
            end
            if(size(brir,2) == 2) 
                brirStruct{iSpeaker}.right(:,iBRIR) = fix_length(brir(:,2),N); 
            end
            
            % Increase index
            iBRIR=iBRIR+1;
        end
    end
end

if saveFile
    save brirStruct.mat brirStruct
end