%% t_piLightSpectrum
%
% Render the checkerboard scene with two light spectra
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
thisR.get('light print');
%% Add one equal energy light

% The cone angle describes how far the spotlight spreads
% The cone delta angle describes how rapidly the light falls off at the
% edges
spotLgt = piLightCreate('new spot',...
                        'type', 'spot',...
                        'spd', 'equalEnergy',...
                        'specscale float', 1,...
                        'coneangle', 20,...
                        'cameracoordinate', true);
thisR.set('light', 'add', spotLgt);
thisR.get('light print');

%% Render
piWrite(thisR);

%% Used for scene
scene = piRender(thisR, 'render type', 'radiance');
scene = sceneSet(scene,'name','Equal energy (spot)');
sceneWindow(scene);

%%  Narrow the cone angle of the spot light a lot
thisR.set('lights', 'new spot', 'spd', 'tungsten');
piWrite(thisR);

%% Used for scene
scene = piRender(thisR, 'render type', 'radiance');
scene = sceneSet(scene,'name','Tungsten');
sceneWindow(scene);

%%
