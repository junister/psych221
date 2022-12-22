% s_arLetters2
%
% Helper for making RL figures
%

%%
ieInit;
if ~piDockerExists, piDockerConfig; end
%%
thisR = piRecipeCreate('macbeth checker');
to = thisR.get('to') - [0.5 0 -0.8];
delta = [0.15 0 0];
str = 'Lorem'; pos = zeros(numel(str),3);
for ii=1:numel(str), pos(ii,:) = to + ii*delta; end
pos(end,:) = pos(end,:) + delta/2;  % Move the 'm' a bit
thisR = charactersRender(thisR, 'Lorem','letterSize',[0.15,0.1,0.15],'letterRotation',[0,15,15],...
    'letterPosition',pos,'letterMaterial','wood-light-large-grain');
thisR.set('skymap','sky-sunlight.exr');
thisR.set('nbounces',4);
piWRS(thisR);

%% Cornell Box

thisR = piRecipeCreate('Cornell_Box');
thisR.set('film resolution',[384 256]*2);
to = thisR.get('to') - [0.32 -0.1 -0.8];
delta = [0.09 0 0];
str = 'marble';
idx = piAssetSearch(thisR,'object name','003_cornell_box');
piMaterialsInsert(thisR,'name','wood-light-large-grain');
thisR.set('asset',idx,'material name','wood-light-large-grain');
for ii=1:numel(str), pos(ii,:) = to + ii*delta; end
thisR = charactersRender(thisR, str,'letterSize',[0.1,0.03,0.1]*0.7,...
    'letterRotation',[0,0,-10],'letterPosition',pos,'letterMaterial','marble-beige');
thisR.set('skymap','sky-sunlight.exr');
thisR.set('nbounces',4);
thisR.set('rays per pixel',512);
d = thisR.get('object distance');
%{
% Stare at the 'r'
thisR.set('to',pos(3,:));
thisR.set('object distance',d);
%}

scene = piWRS(thisR);

%% Contemporary bathroom
%{
resolution = [320 320]*1;

thisR = piRecipeDefault('scene name','contemporary-bathroom');
thisR.set('n bounces',5);
thisR.set('rays per pixel',512);
thisR.set('film resolution',resolution);
thisR.set('render type',{'radiance','depth'});

thisR.set('film resolution',[384 256]);
to = thisR.get('to');
delta = [0.09 0 0];
str = 'forsale';
for ii=1:numel(str), pos(ii,:) = 10*to; end
thisR = charactersRender(thisR, str,'letterSize',[0.1,0.03,0.1]*10,...
    'letterRotation',[0,0,-10],'letterPosition',pos,'letterMaterial','diffuse-white');
thisR.set('skymap','sky-sunlight.exr');
thisR.set('nbounces',4);
thisR.set('rays per pixel',512);

% thisR.show('objects');

%% This renders the scene

scene = piWRS(thisR);
%}

%% Clean uyp the scene
scene = piAIdenoise(scene);
sceneWindow(scene);

%%
scene = sceneSet(scene,'fov',3);

% A long strip along the horizontal axis
cm = cMosaic('positionDegs',[0 0],'sizeDegs',[3 3]);
cm.visualize;

title('');
oi = oiCreate('wvf human');
oi = oiCompute(oi,scene);
oiWindow(oi);

% save('cm5x5','cm');
[allE, noisyE] = cm.compute(oi);
cm.plot('excitations',allE);
title('');

% Remind ourselves of how to set the parameters to visualize absorptions.
params = cm.visualize('params');


%% Rectangular cones

useFOV = 3;
cMosaic = coneMosaic;

% Set size to show part of the scene. Speeds things up.
cMosaic.setSizeToFOV(0.4 * sceneGet(scene, 'fov'));
cMosaic.emGenSequence(50);
oi = oiCreate('wvf human');

% Experiment with different "display" resolutions
HMDFOV = 120; % Full FOV
% Should be 4:1 aspect ratio, but we want a square patch
HMDResolutions = {[2000 2000],[8000 8000]}; % {[2000 2000], [4000 4000], [8000 8000]};
for ii=1:numel(HMDResolutions)
    % scale for portion of FOV we are rendering
    thisName = sprintf('HMD: %d',HMDResolutions{ii}(1));
    thisR.set('filmresolution', HMDResolutions{ii} * useFOV/HMDFOV);
    scene = piWRS(thisR,'name',thisName);

    oi = oiCompute(oi, scene);
    cMosaic.name = thisName;
    cMosaic.compute(oi);
    cMosaic.computeCurrent;

    cMosaic.window;

end