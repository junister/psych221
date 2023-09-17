% This script demonstrates how to estimate medium absorption from simulated
% measurements. The key idea is to calculate scene radiance with and
% without the medium, and estimate the absorption from the ratio of the
% signals
%
% Henryk Blasinski, 2023

close all;
clear all;
clc;
%%
ieInit
piDockerConfig();

macbeth = piCreateMacbethChart();
macbeth.set('pixel samples', 128);

waterThickness = 10;

% Define rendering parameters 
dw = dockerWrapper('dockerContainerName','digitalprodev/pbrt-v4-gpu',...
    'localRender',false,...
    'gpuRendering',false,...
    'remoteMachine','mux.stanford.edu',...
    'remoteUser','henryk',...
    'remoteRoot','/home/henryk',...
    'remoteImage','digitalprodev/pbrt-v4-cpu',...
    'relativeScenePath','/iset3d/');

macbethScene = piWRS(macbeth, 'ourDocker', dw, 'meanluminance', -1);

% Extract the 'in air' radiance for a particular patch.
patchX = 150:170;
patchY = 320:340;

wave = sceneGet(macbethScene, 'wave');
inAirPhotons = sceneGet(macbethScene,'photons');
inAirPhotons = inAirPhotons(patchY,patchX,:);
inAirPhotons = reshape(inAirPhotons, [size(inAirPhotons,1) * size(inAirPhotons,2), size(inAirPhotons,3)])';

% Create a water medium with absorption properties only. Scattering is
% disabled.
[water, waterProp] = piWaterMediumCreate('seawater', 'waterSct', 0);

underwaterMacbeth = piSceneSubmerge(macbeth, water, 'sizeX', 50, 'sizeY', 50, 'sizeZ', waterThickness);
underwaterMacbeth.set('outputfile',fullfile(piRootPath,'local','UnderwaterMacbeth','UnderwaterMacbeth.pbrt'));
underwaterMacbeth = sceneSet(underwaterMacbeth,'name', 'Underwater');

underwaterScene = piWRS(underwaterMacbeth, 'ourDocker', dw, 'meanluminance', -1);

% Extract the 'in water radiance for a particular patch
inWaterPhotons = sceneGet(underwaterScene,'photons');
inWaterPhotons = inWaterPhotons(patchY,patchX,:);
inWaterPhotons = reshape(inWaterPhotons, [size(inWaterPhotons,1) * size(inWaterPhotons,2), size(inWaterPhotons,3)])';

% Plot the radiance
% Note, the in water radiance is higher than in air radiance for some
% wavelengths. This means there is some scaling somewhere that is not being
% accounted for !
figure;
hold on; grid on; box on;
plot(wave, mean(inAirPhotons, 2));
plot(wave, mean(inWaterPhotons, 2));
xlabel('wavelength, nm');
ylabel('Radiance, photons');
legend('Air','Water');

absorptionTrue = waterProp.absorption;
absorptionTrue = absorptionTrue / max(absorptionTrue);

waterDistance = (waterThickness / 2 - 0.5) * 2;
absorptionEst = log(mean(inWaterPhotons, 2) ./ mean(inAirPhotons, 2)) / -waterDistance;
absorptionEst = absorptionEst / max(absorptionEst);

figure;
hold on; grid on; box on;
plot(wave,  absorptionEst);
plot(waterProp.wave, absorptionTrue);
xlabel('wavelength, nm');
ylabel('Absorption');
legend('Estimated','True');


