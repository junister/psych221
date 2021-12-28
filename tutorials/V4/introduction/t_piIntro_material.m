%% Illustrates setting scene materials
%
% This example scene includes glass and mirror materials.  The script
% sets up the glass material and number of bounces to make the glass
% appear reasonable.
%
%
% Dependencies:
%    ISET3d-v4, (ISETCam or ISETBio), JSONio
%
% ZL, BW SCIEN 2018
%
% See also
%   t_piIntro_*

%% Initialize ISET and Docker
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read pbrt file 

sceneName = 'sphere';
thisR = piRecipeDefault('scene name',sceneName);

% convert scene unit from centimeter to meter
%thisR = piUnitConvert(thisR);
% Create an environmental light source (distant light) that is a 9K
% blackbody radiator.
distLight = piLightCreate('new dist light',...
    'type', 'distant',...
    'spd', 9000,... % blackbody
    'cameracoordinate', true);
thisR.set('light', 'add', distLight);

thisR.set('film resolution',[200 150]*2);
thisR.set('rays per pixel',64);
thisR.set('fov',45);
thisR.set('nbounces',5);
thisR.set('film render type',{'radiance','depth'});

% Render
piWRS(thisR,'name',sprintf('Uber %s',sceneName));

%% The material library

% Print out the named materials in this scene.
thisR.get('materials print');

% We have additional materials in an ISET3d library.  In the future, we
% will be creating the material library in a directory within ISET3d, and
% expanding on them.
piMaterialPrint;

%% Add a red matte surface

% Create a red matte material
redMatte = piMaterialCreate('redMatte', 'type', 'diffuse');

% Add the material to the materials list
thisR.set('material', 'add', redMatte);
thisR.get('materials print');

%% Set the spectral reflectance of the matte material to be very red.

wave = 400:10:700;
reflectance = ones(size(wave));
reflectance(1:17) = 1e-3;

% Put it in the PBRT spd format.
spdRef = piMaterialCreateSPD(wave, reflectance);

% Store the reflectance as the diffuse reflectance of the redMatte
% material
thisR.set('material', redMatte, 'reflectance value', spdRef);

%% Set the material
assetName = '001_Sphere_O';
thisR.set('asset',assetName,'material name',redMatte.name);

% Show that we set it
thisR.get('object material')

% Let's have a look

scene = piWRS(thisR,'name',sprintf('Red %s',sceneName));

if piCamBio, sceneSet(scene,'render flag','hdr');
else,        sceneSet(scene,'gamma',0.6);
end
%%  Now Put the sphere in an environment

%rmLight = piLightCreate('room light', ...
%    'type', 'infinite',...
%    'mapname', 'room.exr');

% Make the sphere a little smaller
assetName = '001_Sphere_O';
thisR.set('asset',assetName,'scale',[0.5 0.5 0.5]);

%thisR.set('light', 'add', rmLight);

% Check that the room.exr file is in the directory.
% In time, we will be using piRenderValidate()
%
% For standard environment lights, we want something like
%
% Add an environmental light
thisR.set('light', 'delete', 'all');
[~, rmLight] = thisR.set('skymap','room.exr');
% doing this now in set, as I think it has to happen
% before the light is added???
%rmLight = piLightSet(rmLight, 'rotation val', {[0 0 1 0], [-90 1 0 0]});

%
%if ~exist(fullfile(thisR.get('output dir'),'room.exr'),'file')
%    exrFile = which('room.exr');
%    copyfile(exrFile,thisR.get('output dir'))
%end

scene = piWRS(thisR,'name',sprintf('Red in environment %s',sceneName));

if piCamBio, sceneSet(scene,'render flag','hdr');
else,        sceneSet(scene,'gamma',0.6);
end
%% Make the sphere glass

glassName = 'glass';
glass = piMaterialCreate(glassName, 'type', 'dielectric','eta','glass-BK7');
thisR.set('material', 'add', glass);
thisR.get('print materials');
thisR.set('asset', assetName, 'material name', glassName);
thisR.get('object material')

scene = piWRS(thisR, 'name', 'Change sphere to glass');

if piCamBio, sceneSet(scene,'render flag','hdr');
else,        sceneSet(scene,'gamma',0.6);
end
%% Change the camera position

% Where is the sphere ...
origFrom = thisR.get('from');
origTo = thisR.get('to');
assetPosition = thisR.get('asset',assetName,'world position');
thisR.set('to',assetPosition);
% piAssetGeometry(thisR);

thisR.set('from',origFrom + [10 20 0]);

% Set the camera from position a little higher and closer

scene = piWRS(thisR, 'name', 'Change camera position');

if piCamBio, sceneSet(scene,'render flag','hdr');
else,        sceneSet(scene,'gamma',0.6);
end

%% Change the sphere to a mirror

mirrorName = 'mirror2';
mirror = piMaterialCreate(mirrorName, 'type', 'conductor',...
    'roughness',0,'eta','metal-Ag-eta','k','metal-Ag-k');
thisR.set('material', 'add', mirror);
thisR.get('print materials');
thisR.set('asset', assetName, 'material name', mirrorName);
thisR.get('object material')

scene = piWRS(thisR, 'name', 'Change glass to mirror');

if piCamBio, sceneSet(scene,'render flag','hdr');
else,        sceneSet(scene,'gamma',0.6);
end

%% END
