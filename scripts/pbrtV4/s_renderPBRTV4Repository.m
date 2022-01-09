%% Example of rendering one of the pbrt V4 scenes
%
%

ieInit;
if ~piDockerExists, piDockerConfig; end

% The contemporary bathroom took about 4 minutes to run on the muxreconrt.

% Read the original
thisR = piRead('/Users/wandell/Documents/MATLAB/iset3d-v4/data/V4/web/contemporary_bathroom/contemporary_bathroom.pbrt','exporter','Copy');

% Write it in local
piWrite(thisR);

% Render it on muxreconrt
scene = piRender(thisR);

% Show it.  Looks right with HDR rendering.  OK with gamma 0.6.
sceneWindow(scene);
sceneSet(scene,'gamma',0.6);

%% Maybe we can set the exporter in piWRS call?

% The contemporary bathroom took about 4 minutes to run on the muxreconrt.

% Read the original
thisR = piRead('/Volumes/Wandell/PBRT-V4/pbrt-v4-scenes/head/head.pbrt');

% Make sure the exporter is set to 'Copy' so all the files are copied
thisR.set('exporter','Copy');

% Write it in local
piWrite(thisR);

% Render it on muxreconrt
scene = piRender(thisR);

% Show it.  Looks right with HDR rendering.  OK with gamma 0.6.
sceneWindow(scene);
sceneSet(scene,'gamma',0.6);

%% END

