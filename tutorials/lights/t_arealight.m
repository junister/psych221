%% Explore light creation with new area light parameters
%
% The area lights were implemented by Zhenyi to help us accurately simulate
% the headlights in night time driving scenes.
%
% The definitions of the shape of the area light are in the
% arealight_geometry.pbrt file.  Looking at the text there should give
% us some ideas about how to create more area lights with different
% properties.
%
% This script should explore setting the SPD of the lights and perhaps
% making different shapes and intensities.
%
% See also
%   ISETAuto 

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% 
fileName = fullfile(piRootPath, 'data','scenes','arealight','arealight.pbrt');
thisR    = piRead(fileName);

%% Default properties
scene = piWRS(thisR,'render flag','hdr');

%% Plot the luminance across a line
roiLocs = [1 74];
sz = sceneGet(scene,'size');
scenePlot(scene,'luminance hline',roiLocs);
ieROIDraw(scene,'shape','line','shape data',[1 sz(2) roiLocs(2) roiLocs(2)]);

%% Show the lights in the file
thisR.show('lights');

%% Set the light adjust the light properties
thisR.set('light','AreaLightRectangle_L','spread val',20);
thisR.set('light','AreaLightRectangle.001_L','spread val',20);
thisR.set('light','AreaLightRectangle.002_L','spread val',20);
thisR.set('light','AreaLightRectangle.003_L','spread val',50);

scene = piWRS(thisR,'render flag','hdr');

%% Plot the luminance
roiLocs = [1 74];
sz = sceneGet(scene,'size');
scenePlot(scene,'luminance hline',roiLocs);
ieROIDraw(scene,'shape','line','shape data',[1 sz(2) roiLocs(2) roiLocs(2)]);

%%

