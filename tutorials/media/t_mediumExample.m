% This tutorial shows how to create a simple scene,
% a medium, and how to render the scene submerged in that medium. 
%
% Henryk Blasinski, 2023
close all;
clear all;
clc;
piDockerConfig();

% Create a scene with a Macbeth Chart.
macbeth = piCreateMacbethChart();
macbeth.set('pixel samples', 128);

% Define rendering parameters 
dw = dockerWrapper('dockerContainerName','digitalprodev/pbrt-v4-gpu',...
    'localRender',false,...
    'gpuRendering',false,...
    'remoteMachine','mux.stanford.edu',...
    'remoteUser','henryk',...
    'remoteRoot','/home/henryk',...
    'remoteImage','digitalprodev/pbrt-v4-cpu');

macbethScene = piWRS(macbeth, 'ourDocker', dw, 'show', false, 'meanluminance', -1);
rgb = sceneGet(macbethScene,'srgb');
figure; 
imshow(rgb);

%%

% Create a seawater medium.
[water, waterProp] = piWaterMediumCreate('seawater');

% Submerge the scene in the medium.                                                 
underwaterMacbeth = piSceneSubmerge(macbeth, water, 'sizeX', 50, 'sizeY', 50, 'sizeZ', 50);
underwaterMacbeth.set('outputfile',fullfile(piRootPath,'local','UnderwaterMacbeth','UnderwaterMacbeth.pbrt'));

uwMacbethScene = piWRS(underwaterMacbeth,'ourDocker', dw, 'show', false, 'meanluminance', -1);
rgb = sceneGet(uwMacbethScene,'srgb');
figure; imshow(rgb);

