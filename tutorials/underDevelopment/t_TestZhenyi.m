fileName = fullfile(piRootPath, 'data/V4/low-poly-taxi/low-poly-taxi.pbrt');

thisR = piRead(fileName);

% add a skymap
thisR.set('skymap',fullfile(piRootPath,'data/skymaps','sky-rainbow.exr'));
% thisR.set('asset','night_B','rotation', [0 0 -35]); 

scene = piWRS(thisR);

ip = piRadiance2RGB(scene,'etime',1/30);

ipWindow(ip);


%% move camera far away
carName = 'taxi';

rotationMatrix = piRotationMatrix('z', -15);
position       = [-5 -12 0];

thisR   = piObjectInstanceCreate(thisR, [carName,'_B'], ...
    'rotation',rotationMatrix, 'position',position);

ip = piRadiance2RGB(scene,'etime',1/30);

ipWindow(ip);