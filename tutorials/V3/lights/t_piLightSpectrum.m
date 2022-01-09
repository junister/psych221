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
sceneName = 'checkerboard';
outFile = fullfile(piRootPath,'local',sceneName,'checkerboard.pbrt');
thisR.set('outputFile',outFile);

%% Set up the render parameters
piCameraTranslate(thisR,'z shift',2);

%% Check the light list
piLightList(thisR);

%% Remove all the lights
thisR     = piLightDelete(thisR, 'all');
lightList = piLightList(thisR);

%% Add one equal energy light

% The cone angle describes how far the spotlight spreads
% The cone delta angle describes how rapidly the light falls off at the
% edges
newLight = piLightCreate('new spot light',... 
    'type','spot',...
    'light spectrum','equalEnergy',...
    'specscale', 1,...
    'cone angle',20,...
    'cameracoordinate', true);
thisR.set('light', 'add', newLight);
thisR.get('light print');
%% Render
piWrite(thisR);

%% Used for scene
scene = piRender(thisR);
scene = sceneSet(scene,'name','Equal energy (spot)');
sceneWindow(scene);

% --- Below is not working(ZL) ---
%%  Narrow the cone angle of the spot light a lot
% idx = 1;
% piLightSet(thisR,idx,'spectrum', 'tungsten');
% piWrite(thisR);
% 
% %% Used for scene
% scene = piRender(thisR);
% scene = sceneSet(scene,'name','Tungsten');
% sceneWindow(scene);

%%
