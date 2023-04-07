% This is an example of an isetauto scene
%
% It has object instances
%

fileName = fullfile(piRootPath, 'data/scenes/low-poly-taxi/low-poly-taxi.pbrt');

thisR = piRead(fileName);

% add a skymap
thisR.set('skymap',fullfile(piRootPath,'data/skymaps','sky-rainbow.exr'));

scene = piWRS(thisR);

ip = piRadiance2RGB(scene,'etime',1/30);

ipWindow(ip);


%% Add a different car
carName = 'taxi';

rotationMatrix = piRotationMatrix('z', -15);
position       = [-4 0 0];

thisR   = piObjectInstanceCreate(thisR, [carName,'_m_B'], ...
    'rotation',rotationMatrix, 'position',position);
thisR.assets = thisR.assets.uniqueNames;

scene = piWRS(thisR);

ip = piRadiance2RGB(scene,'etime',1/30);

ipWindow(ip);