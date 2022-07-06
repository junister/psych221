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

% The no number is the blue one
% The 002 light is the green one.
% The 001 is the red one
% the 003 must be the yellow one.

%%
% TODO: This sets the name of the light asset.  It must always have a _L if
% it is a light. There is also a name in the 'lght{1}' slot. That should
% probably be set to align with this name.
thisR.set('asset','AreaLightRectangle_L','name','Area_Blue_L');
thisR.set('asset','AreaLightRectangle.001_L','name','Area_Red_L');
thisR.set('asset','AreaLightRectangle.002_L','name','Area_Green_L');
thisR.set('asset','AreaLightRectangle.003_L','name','Area_Yellow_L');

thisR.show('lights');

%% Plot the luminance across a line
roiLocs = [1 74];
sz = sceneGet(scene,'size');
scenePlot(scene,'luminance hline',roiLocs);
ieROIDraw(scene,'shape','line','shape data',[1 sz(2) roiLocs(2) roiLocs(2)]);

%% The green light is bright.  Let's reduce its intensity.

thisR.set('light','Area_Green_L','specscale',40);
scene = piWRS(thisR,'render flag','hdr');
roiLocs = [1 74];
sz = sceneGet(scene,'size');
scenePlot(scene,'luminance hline',roiLocs);
ieROIDraw(scene,'shape','line','shape data',[1 sz(2) roiLocs(2) roiLocs(2)]);

%% Set the light adjust the light properties

lNames = thisR.get('light','names');

% The spread of car headlights is about 
for ii=1:numel(lNames)
    thisR.set('light',lNames{ii},'spread val',ii*10);
end

scene = piWRS(thisR,'render flag','hdr');

%% Plot the luminance
roiLocs = [1 74];
sz = sceneGet(scene,'size');
scenePlot(scene,'luminance hline',roiLocs);
ieROIDraw(scene,'shape','line','shape data',[1 sz(2) roiLocs(2) roiLocs(2)]);

%%
thisR.set('asset', 'Area_Yellow_L', 'rotate', [-30, 0, 0]); % -5 degree around y axis
piWRS(thisR,'render flag','hdr');

%%
thisR.set('asset', 'Area_Red_L', 'rotate', [0, 0, 30]); % -5 degree around y axis
piWRS(thisR,'render flag','hdr');

%%
thisR.set('asset', 'Area_Blue_L', 'rotate', [0, 0, -30]); % -5 degree around y axis
piWRS(thisR,'render flag','hdr');

%% Set the SPD of one of the lights
wave = (400:10:700)';

% halogen = ieReadSpectra('halogen_2913',wave);
% halogen = ieReadSpectra('LED_3845',wave);
% 
thisR.set('light','Area_Yellow_L','spd','halogen_2913');

piWRS(thisR,'render flag','hdr');

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

