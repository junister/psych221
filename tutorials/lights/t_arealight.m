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

%% Show the lights in the file and rename them for convenience
thisR.show('lights');

lNames = thisR.get('light','names');

% The no number is the blue one
% The 002 light is the green one.
% The 001 is the red one
% the 003 must be the yellow one.

% This sets the name in the 'lght' slot.  THere is also a name in the main
% node.  We need to sort this out.
thisR.set('light','AreaLightRectangle_L','name','Area_Blue');
thisR.set('light','AreaLightRectangle.001_L','name','Area_Red');
thisR.set('light','AreaLightRectangle.002_L','name','Area_Green');
thisR.set('light','AreaLightRectangle.003_L','name','Area_Yellow');

thisR.show('lights');

%% Plot the luminance across a line
roiLocs = [1 74];
sz = sceneGet(scene,'size');
scenePlot(scene,'luminance hline',roiLocs);
ieROIDraw(scene,'shape','line','shape data',[1 sz(2) roiLocs(2) roiLocs(2)]);

%% The green light is bright.  Let's reduce its intensity.

thisR.set('light','AreaLightRectangle.002_L','specscale',40);
scene = piWRS(thisR,'render flag','hdr');
roiLocs = [1 74];
sz = sceneGet(scene,'size');
scenePlot(scene,'luminance hline',roiLocs);
ieROIDraw(scene,'shape','line','shape data',[1 sz(2) roiLocs(2) roiLocs(2)]);

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
[ledSPD,wave] = ieReadSpectra('LED_3845');
[ledSPD,wave] = ieReadSpectra('LED_4613');
[ledSPD,wave] = ieReadSpectra('halogen_2913');
[ledSPD,wave] = ieReadSpectra('CFL_5780');

chromaticityPlot;

ieNewGraphWin; plotRadiance(wave,ledSPD)

XYZ = ieXYZFromEnergy(ledSPD',wave);
xy = chromaticity(XYZ);
hold on; plot(xy(1),xy(2),'o');

% It would be good to calculate the CCT

%%

