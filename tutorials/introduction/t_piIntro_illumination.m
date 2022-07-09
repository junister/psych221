%% Introducing iset3d calculations with the Chess Set
%
% Brief description:
%  This script renders the chess set scene to illustrate the lighting.  It
%  does so by changing the materials of the chess set to white, diffuse.
% 
%    * Initializes the recipe
%    * Sets the film (sensor) resolution parameters
%    * Calls the renderer that invokes PBRT via docker
%    * Loads the returned radiance and depth map into an ISET Scene structure.
%    * Adds a point light
%    * Adds a skymap
%
% Dependencies:
%    ISET3d and either ISETCam or ISETBio
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
thisR.set('rays per pixel',256);
thisR.set('n bounces',4); % Number of bounces traced for each ray

thisR.set('render type',{'radiance','depth'});
scene = piWRS(thisR,'render flag','hdr');

%%  Edit the material list, adding White.
oNames = thisR.get('object names');

thisR.show('materials');
nMaterials = thisR.get('n materials');
matNames = thisR.get('material','names');
thisR = piMaterialsInsert(thisR,'mtype','diffuse');

%%
% tmp = thisR.show('materials')
for ii=1:numel(oNames)
    % The replace and other material commands need to be changed to match
    % the ordering in more modern methods
    thisR.set('asset',oNames{ii},'material name','White');
end

thisR.show('objects');
%%

sceneW = piWRS(thisR,'render flag','hdr','name','reflectance');

%% Divide the original photons by the diffuse white photons

photons  = sceneGet(scene,'photons');    % Original
photonsW = sceneGet(sceneW,'photons');   % White surfaces

ref = photons ./ photonsW;               % Reflectance of original

% Create the reflectance scene
sceneR = sceneSet(scene,'photons',ref);
nWave  = sceneGet(sceneR,'n wave');
sceneR = sceneSet(sceneR,'illuminant photons',ones(nWave,1));
sceneWindow(sceneR);

% We could try this with a point light next.
%{
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

piWRS(thisR, 'name','Rotated skymap');

%% World orientation
thisR.set('light', skyMap.name, 'world orientation', [30 0 30]);
thisR.get('light', skyMap.name, 'world orientation')

piWRS(thisR, 'name','No rotation skymap');
%}
%% END
