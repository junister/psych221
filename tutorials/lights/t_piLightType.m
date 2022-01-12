%% t_piLightType
%
%

%% Initialize ISET and Docker

% We start up ISET and check that the user is configured for docker
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the file
thisR = piRecipeDefault('scene name','checkerboard');

%% The output will be written here
%{
sceneName = 'checkerboard';
outFile = fullfile(piRootPath,'local',sceneName,'checkerboard.pbrt');
thisR.set('outputFile',outFile);
%}

%% Set up the render parameters
piCameraTranslate(thisR,'z shift',2);

%% Check the light list
thisR.get('light print');

%% Remove all the lights
thisR.set('light', 'delete', 'all');

%% Add one equal energy light

% The cone angle describes how far the spotlight spreads
% The cone delta angle describes how rapidly the light falls off at the
% edges
spotlight = piLightCreate('new spot',...
    'type','spot',...
    'spd','equalEnergy',...
    'specscale float', 1,...
    'coneangle',20,...
    'cameracoordinate', true);

thisR.set('light', 'add', spotlight);
%% Render
piWrite(thisR);

%% Used for scene
scene = piRender(thisR, 'render type', 'radiance');
val = thisR.get('light', 'new spot', 'coneangle');
scene = sceneSet(scene,'name',sprintf('EE spot %d',val));
sceneWindow(scene);

%%  Narrow the cone angle of the spot light a lot
thisR.set('light', 'new spot', 'coneangle', 10);
piWrite(thisR);

%% Used for scene
scene = piRender(thisR, 'render type', 'radiance');
val = thisR.get('light', 'new spot', 'coneangle');
scene = sceneSet(scene,'name',sprintf('EE spot %d',val));
sceneWindow(scene);

%%  Change the light and render again
thisR.set('light', 'translate', 'new spot', [2 0 2]);

%{
piLightSet(thisR,idx,'type','spot');
piLightTranslate(thisR,idx,...
    'z shift',2,...
    'x shift',2);
%}
thisR.set('light', 'new spot', 'coneangle', 25);
piWrite(thisR);

%% Used for scene
scene = piRender(thisR, 'render type', 'radiance');
val = thisR.get('light', 'new spot', 'from');
scene = sceneSet(scene,'name',sprintf('EE point [%d,%d,%d]',val));
sceneWindow(scene);

%%  Change the light and render again
infLight = piLightCreate('inf light',...
                        'type','infinite',...
                        'spd','D50');
thisR.set('light', 'replace', 'new spot', infLight);
thisR.get('light print');
piWrite(thisR);

%% Used for scene
scene = piRender(thisR, 'render type', 'radiance');
val = thisR.get('light', infLight.name, 'type');
scene = sceneSet(scene,'name',sprintf('EE type %s',val));
sceneWindow(scene);

