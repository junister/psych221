%% Introducing iset3d calculations
%
% TODO:
%   With a point source there is a color at the edge of the sphere.
%   What is happening? (See the end)
%
% Brief description:
%  This script renders the sphere scene in the data directory of the ISET3d
%  repository.
% 
% Dependencies:
%    ISET3d, (ISETCam or ISETBio), JSONio
%
%  Check that you have the updated docker image by running
%
%    docker pull vistalab/pbrt-v3-spectral
%
% Description
%  The scripts introduces how to read one of the ISET3d default scenes to
%  create recipe.  
%
%  The script 
%
%    * initializes the recipe
%    * adds a light
%    * sets film resolution parameters
%    * calls the renderer that invokes the PBRT docker
%    * loads the radiance and depth map into an ISET scene structure.
%
% Authors
%  TL, BW, ZL, ZLy SCIEN 2017
%
% See also
%   t_piIntro_*, piRecipeDefault, recipe
%

%% Initialize ISET and Docker

% Start up ISET and check that docker is configured 
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the recipe

thisR = piRecipeDefault('scene name','sphere');
%  piWRS(thisR);  % Black

% Different ambient light sources
fileName = 'skylight-day.exr';       % Pretty good
% fileName = 'sunlight.exr';         % Pretty good; yellow sun, gray clouds
% fileName = 'exrExample.exr';       % Weird scene
% fileName = 'noon_009.exr';         % Weird scene
% fileName = 'environment_Reflection.exr';         % Weird scene

exampleEnvLight = piLightCreate('ambient', ...
    'type', 'infinite',...
    'mapname', fileName);
exampleEnvLight = piLightSet(exampleEnvLight, 'rotation val', {[0 0 1 0], [-90 1 0 0]});
thisR.set('lights', 'add', exampleEnvLight);                       

%%
thisR.show('objects');

%% Set up the render quality
%
% There are many different parameters that can be set.  This is the just an
% introductory script, so we do a minimal number of parameters.  Much of
% what is described in other scripts expands on this section.
thisR.set('film resolution',[200 200]);
thisR.set('rays per pixel',128);
thisR.set('n bounces',1); % Number of bounces

%% set rendering type
thisR.set('film render type',{'radiance','depth'})

%% Save the recipe and render
piWrite(thisR);

% There is no lens, just a pinhole.  In that case, we are rendering a
% scene. If we had a lens, we would be rendering an optical image.
[scene, result] = piRender(thisR);
sceneWindow(scene);

%% By default, we also compute the depth map

scenePlot(scene,'depth map');

%% Here is the point source problem.  We should try other lights, too.

thisR.set('lights','delete','all');

% Add a light a point light.
thisName = 'point';
pointLight = piLightCreate(thisName,...
    'type','point',...
    'cameracoordinate', true);
thisR.set('light','add',pointLight);

piWRS(thisR);

%% END
