% This tutorial shows how to create a simple scene,
% a medium, and how to render the scene submerged in that medium.
%
% Henryk Blasinski, 2023
      
ieInit();
piDockerConfig();

dockerWrapper = dockerWrapper('dockerContainerName','digitalprodev/pbrt-v4-gpu',...
    'localRender',true,...
    'gpuRendering',false,...
    'remoteMachine','mux.stanford.edu',...
    'remoteUser','henryk',...
    'remoteRoot','/home/henryk',...
    'remoteImage','digitalprodev/pbrt-v4-cpu',...
    'relativeScenePath','/iset3d/',...
    'remoteResources',false);


%% Create a scene with a Macbeth Chart.
macbeth = piCreateMacbethChart();

macbeth.set('pixel samples', 128);
dockerWrapper.reset;

macbethScene = piWRS(macbeth, 'ourDocker', dockerWrapper, 'show', false, 'meanluminance', -1);
sceneShowImage(macbethScene);

%% Create sea water medium

mediumScatter = false;

[seawater, seawaterProp] = piWaterMediumCreate('seawater', 'waterSct', mediumScatter);
seawaterMacbeth = piSceneSubmerge(macbeth, seawater, 'sizeX', 50, 'sizeY', 50, 'sizeZ', 5);
seawaterMacbeth.set('outputfile',fullfile(piRootPath,'local','SeawaterMacbeth','SeawaterMacbeth.pbrt'));

seawaterMacbethScene = piWRS(seawaterMacbeth, 'ourDocker', dockerWrapper, 'show', false, 'meanluminance', -1);
sceneShowImage(seawaterMacbethScene);


[freshwater, freshwaterProp] = piWaterMediumCreate('freshwater', 'cPlankton', 10, 'waterSct', mediumScatter);
freshwaterMacbeth = piSceneSubmerge(macbeth, freshwater, 'sizeX', 50, 'sizeY', 50, 'sizeZ', 5);
freshwaterMacbeth.set('outputfile',fullfile(piRootPath,'local','FreshwaterMacbeth','FreshwaterMacbeth.pbrt'));

freshwaterMacbethScene = piWRS(freshwaterMacbeth, 'ourDocker', dockerWrapper, 'show', false, 'meanluminance', -1);
sceneShowImage(freshwaterMacbethScene);

figure;
hold on; grid on; box on;
plot([seawaterProp.absorption(:), freshwaterProp.absorption(:)]);
legend('seawater','freshwater');


% The depth of the water we are seeing through
depths = logspace(0.1,2,3);
for zz = 1:numel(depths)

    uwMacbeth = piSceneSubmerge(macbeth, seawater, 'sizeX', 50, 'sizeY', 50, 'sizeZ', depths(zz));
    uwMacbeth = sceneSet(uwMacbeth,'name',sprintf('Depth %.1f',depths(zz)));

    uwMacbethScene    = piWRS(uwMacbeth, 'ourDocker', dockerWrapper, 'show', false, 'meanluminance', -1);
    sceneShowImage(uwMacbethScene);
    
end


%{
%% Here is the code to set Docker up to run on a local GPU
%  My laptop doesn't have an Nvidia GPU, so I can't completely
%  test it, so let me know if it works!

try
    ourGPU = gpuDevice();
    if str2double(ourGPU.ComputeCapability) >= 5.3 % minimum for PBRT on GPU
        [status,result] = system('docker pull digitalprodev/pbrt-v4-gpu-ampere-mux');    
        dw = dockerWrapper('dockerContainerName','digitalprodev/pbrt-v4-gpu-ampere-mux',...
            'localImage', 'digitalprodev/pbrt-v4-gpu-ampere-mux', ...
            'localRender',true,...
            'gpuRendering',true,...
            'remoteResources',false);
        haveGPU = true;
    else
        fprintf('GPU Compute is: %d\n',ourGPU.computeCapability);
        haveGPU = false;
    end
catch
    haveGPU = false;
end

if ~haveGPU
    [status,result] = system('docker pull digitalprodev/pbrt-v4-cpu');
    dw = dockerWrapper('dockerContainerName','digitalprodev/pbrt-v4-cpu',...
        'localRender',true,...
        'gpuRendering',false,...
        'remoteImage','digitalprodev/pbrt-v4-cpu',...
        'remoteResources',false);
end
%}