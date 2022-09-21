% Export objects to JSON for use in oi2sensor
% 
% D. Cardinal, Stanford University, 2022
%
%% Set output folder
outputFolder = fullfile(piRootPath,'local','json');
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

%% Export sensor(s)
sensorFiles = {'ar0132atSensorrgb.mat', 'MT9V024SensorRGB.mat'};

for ii = 1:numel(sensorFiles)
    load(sensorFiles{ii}); % assume they are on our path
    % change suffix to json
    [~, fName, fSuffix] = fileparts(sensorFiles{ii});
    jsonwrite(fullfile(outputFolder,[fName '.json']), sensor);
end

%% TBD Export Lenses

%% TBD Export Scenes

%% TBD Export OIs
%% NOTE: 
% They can include complex numbers that are not directly
% usable in JSON, so we need to encode or re-work somehow
