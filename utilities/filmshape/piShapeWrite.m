function piShapeWrite(fname,pointCloud,varargin)
% Write out the JSON file for specifying the film shape
%
% Synopsis
%
% Inputs
%  fname - File name (JSON file)
%  pointCloud - Film surface locations (Nx3) specified in meters
%  
% Key/val
%
%
% Outputs
%
% See also
%

%% Generate Loouptable JSON 

lookuptable = pointsToLookuptable(pointCloud);
jsonwrite(fname,lookuptable);

% jsonwrite(['lookuptable-bump-vectorized-' num2str(rowresolution) 'x' num2str(colresolution) '.json'],lookuptable);

end

% Helper function
function lookuptable = pointsToLookuptable(pointsXYZ_meters)
% Take A set of XYZ points and generate a lookuptable struct that maps
% index to position. Use jsonwrite(lookuptable) to generate the appropriate
% json file
%
% INPUTS
%  pointsXYZ - Nx3 -matrix with N the number of points in meters
%
% OUTPUTS
%   lookuptable - A struct that can be written out to a json file to be
%   read by PBRT as a lookuptable (e.g. for human eye)
%
% Thomas Goossens 2022

lookuptable = struct;
lookuptable.numberofpoints= size(pointsXYZ_meters,1);

% Construct map
for index = 1:size(pointsXYZ_meters,1)
    map = struct;
    map.index= index-1; % Array index (start counting at zero)
    map.point =  pointsXYZ_meters(index,:);  % Target point in mters

     % Add map to lookup table
    lookuptable.table(index) =map; 
end

end