%% Introducing iset3d calculations with the Chess Set
%
% Brief description:
%  This script renders the chess set scene.  
% 
%  This script:
%
%    * Initializes the recipe
%    * Sets the film (sensor) resolution parameters
%    * Calls the renderer that invokes PBRT via docker
%    * Loads the returned radiance and depth map into an ISET Scene structure.
%    * Adds a point light
%
% Dependencies:
%    ISET3d and either ISETCam or ISETBio
%
%  Check that you have the latest docker image by running
%
%    docker pull vistalab/pbrt-v3-spectral
%
% See also
%   t_piIntro_*, piRecipeDefault, @recipe
%

%% Initialize ISET and Docker

% Start up ISET and check that docker is configured 
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the recipe

thisR = piRecipeDefault('scene name','chessset');

%% Set the render quality

% There are many rendering parameters.  This is the just an introductory
% script, so we set a minimal number of parameters.  Much of what is
% described in other scripts expands on this section.
thisR.set('film resolution',[256 256]);
thisR.set('rays per pixel',64);
thisR.set('n bounces',4); % Number of bounces traced for each ray

thisR.set('render type',{'radiance','depth'});
piWRS(thisR);

%% By default, we have also computed the depth map, so we can render it
scene = ieGetObject('scene');

scenePlot(scene,'depth map');

%% Add a bright point light near the front where the camera is

thisR.get('light print');
thisR.set('light','all','delete');

% First create the light
pointLight = piLightCreate('point',...
    'type','point',...
    'cameracoordinate', true);

% Then add it to our scene
thisR.set('light',pointLight,'add');

% For now only radiance. Because we can.
thisR.set('render type',{'radiance'});

piWRS(thisR,'name','Point light');

%% Add a skymap

[~, skyMap] = thisR.set('skymap','room.exr');

thisR.get('light print');

piWRS(thisR, 'name', 'Point light and skymap');

%% Rotate the skymap

thisR.set('light',skyMap.name,'rotate',[30 0 0]);

piWRS(thisR, 'name','Rotate skymap');


%% END
