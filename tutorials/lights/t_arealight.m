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

lNames = thisR.get('light','names');

%% Set the light adjust the light properties

% The spread of car headlights is about 
for ii=1:numel(lNames)
    thisR.set('light',lNames{ii},'spread val',60);
end

scene = piWRS(thisR,'render flag','hdr');

%% Plot the luminance
roiLocs = [1 74];
sz = sceneGet(scene,'size');
scenePlot(scene,'luminance hline',roiLocs);
ieROIDraw(scene,'shape','line','shape data',[1 sz(2) roiLocs(2) roiLocs(2)]);

%%  Spectrum of an LED light that might be found in a car headlight

% These appear about right to me (BW).
%
% [ledSPD,wave] = ieReadSpectra('LED_3845');
% [ledSPD,wave] = ieReadSpectra('LED_4613');
% [ledSPD,wave] = ieReadSpectra('halogen_2913');

ieNewGraphWin; plotRadiance(wave,ledSPD)

XYZ = ieXYZFromEnergy(ledSPD',wave);
xy = chromaticity(XYZ);
hold on; plot(xy(1),xy(2),'o');

% It would be good to calculate the CCT

%%

