function [idmap,objectlist,result] = piLabel(thisR)
% Generate a map that labels (pixel-wise) the scene objects
%
% Synopsis
%    [objectslist,instanceIdMap,result] = roadgen.label;
%
% Brief
%   Render an image showing which object at each pixel (instanceId map).
%   For now this only runs on a CPU.  
%
% Inputs
%   obj - roadgen object
% 
% Key-val/Outputs
%   N/A
%
% Outputs
%   idmap - Image with integers at each pixel indicating which
%                   object.
%   objectslist   - List of the objects
%   result - Output from the renderer
%
% Description
%  For object detection, we often want pixel maps indicating which object
%  is at each pixel. The correspondence between the pixel values and the
%  objects in the returned objectslist. This routine performs that
%  calculation, but it is tuned for isetauto.

% Examples:
%{
thisR = piRecipeDefault('scene name','chessset');
[idMap, oList, result] = piLabel(thisR);
%}

%% Set up the rendering parameters appropriate for a label render

thisR.set('rays per pixel',8);
thisR.set('nbounces',1);
thisR.set('film render type',{'instance'});
thisR.set('integrator','path');

% Add this line: Shape "sphere" "float radius" 500 
% So we do not label the world lighting, I think.
thisR.world(numel(thisR.world)+1) = {'Shape "sphere" "float radius" 5000'};

outputFile = thisR.get('outputfile');
[dir, fname, ext] = fileparts(outputFile);
thisR.set('outputFile',fullfile(dir, [fname, '_instanceID', ext]));

piWrite(thisR);

%% Use CPU for label generation, 
% 
% We will fix this and render along with radiance.  We is Zhenyi.

% This is set up for Stanford.
% For the moment it is hard-coded torender on the CPU on muxreconrt.
%
% It would probably be better to run locally and not to have to reset
% the remote container.
%
% Also, can we just reset the running docker wrapper ?

%{
    % This worked for remote
    dockerWrapper.reset;
    x86Image = 'digitalprodev/pbrt-v4-cpu:latest';
    thisD = dockerWrapper('gpuRendering', false, ...
                          'remoteImage',x86Image);
%}

% thisD = dockerWrapper('gpuRendering', false);

% This seems to work for local.  Not sure why we need the reset.
dockerWrapper.reset;
thisD = dockerWrapper('gpuRendering', false, ...
    'localRender',true);

% This is the scene or oi with the metadata attached.
[isetStruct, result] = piRender(thisR,'our docker',thisD);

% Why is this here?
thisR.world = {'WorldBegin'};

idmap = isetStruct.metadata.instanceID;
% ieNewGraphWin; imagesc(idmap);

%% Get object lists from the geometry file.

%% Read the contents of the PBRT geometry file to find the Objects.

outputFile = thisR.get('outputfile');
fname = strrep(outputFile,'.pbrt','_geometry.pbrt');
fileID = fopen(fname);
tmp = textscan(fileID,'%s','Delimiter','\n');
txtLines = tmp{1};
fclose(fileID);

% Find all the lines that contain an ObjectInstance
objectlist = txtLines(piContains(txtLines,'ObjectInstance'));

end