% This tutorial shows how to create a simple scene,
% a medium, and how to render the scene submerged in that medium. 
%
% Henryk Blasinski, 2023
close all;
clear all;
clc;
%%
ieInit
piDockerConfig();

%% Create a scene with a Macbeth Chart.
macbeth = piCreateMacbethChart();
macbeth.set('pixel samples', 128);

% Define rendering parameters 
%{
dw = dockerWrapper('dockerContainerName','digitalprodev/pbrt-v4-gpu',...
    'localRender',false,...
    'gpuRendering',false,...
    'remoteMachine','mux.stanford.edu',...
    'remoteUser','henryk',...
    'remoteRoot','/home/henryk',...
    'remoteImage','digitalprodev/pbrt-v4-cpu');
%}

macbethScene = piWRS(macbeth, 'ourDocker', dockerWrapper, 'show', false, 'meanluminance', -1);
rgb = sceneGet(macbethScene,'srgb');
figure; 
imshow(rgb);

%%
% HB created a full representation model of scattering that has a number of
% different
%
% Create a seawater medium.
% water is a description of a PBRT object that desribes a homogeneous
% medium.  The waterProp are the parameters that define the seawater
% properties, including absorption, scattering, and so forth.
%
% vsf is volume scattering function. Outer product of the scattering
% function and the phaseFunction.  For pbrt you only specify the scattering
% function and a single scalar that specifies the phaseFunction.
%
% phaseFunction 
%
% PBRT allows specification only of the parameters scattering, scattering 
[water, waterProp] = piWaterMediumCreate('seawater');

%{
   uwMacbeth = sceneSet(uwMacbeth,'medium property',val);
   medium = sceneGet(uwMacbeth,'medium');
   medium = mediumSet(medium,'property',val);
   mediumGet()....
%}
% Submerge the scene in the medium.   
% The size defines the volume of water.  It is centered at 0,0 and extends
% plus or minus 50/2 away from center in units of meters!  Excellent! 
% It returns a modified recipe that has the 'media' slot built in the
% format that piWrite knows what to do with it.
underwaterMacbeth = piSceneSubmerge(macbeth, water, 'sizeX', 50, 'sizeY', 50, 'sizeZ', 50);
underwaterMacbeth.set('outputfile',fullfile(piRootPath,'local','UnderwaterMacbeth','UnderwaterMacbeth.pbrt'));

uwMacbethScene = piWRS(underwaterMacbeth,'ourDocker', dockerWrapper, 'show', false, 'meanluminance', -1);

rgb = sceneGet(uwMacbethScene,'srgb');
figure; imshow(rgb);

%% Let's change a medium parameter - On BW's computer this is OK

% The depth of the water we are seeing through
depths = logspace(0,1.5,3);
for zz = 1:numel(depths)
    underwaterMacbeth = piSceneSubmerge(macbeth, water, 'sizeX', 50, 'sizeY', 50, 'sizeZ', depths(zz));

    idx = piAssetSearch(underwaterMacbeth,'object name','Water');
    sz = underwaterMacbeth.get('asset',idx,'size');
    underwaterMacbeth = sceneSet(underwaterMacbeth,'name',sprintf('Depth %.1f',sz(3)));

    uwMacbethScene    = piWRS(underwaterMacbeth, 'meanluminance', -1);

end

%%  