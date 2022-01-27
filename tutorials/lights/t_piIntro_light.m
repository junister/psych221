%% Illustrate how to control properties of scene lights
%
%  The light structure has a large number of parameters that control its
%  properties.  We will be controlling the properties with commands of sthis
%  type:
%
%    thisR.set('light ' .....)
% 
% Here we illustrate examples for creating and setting properties of
%
%     * Spot lights (cone angle, cone delta angle, position)
%     * SPD: RGB and Spectrum
%     * Environment lights
%
% See also
%   The PBRT book definitions for lights are:
%      https://www.pbrt.org/fileformat-v3.html#lights
%

%% Initialize ISET and Docker and read a file

% Start up ISET/ISETBio and check that the user is configured for docker
clear; close all; ieInit;
if ~piDockerExists, piDockerConfig; end

thisR = piRecipeDefault('scene name','checkerboard');

%% Check the light list that came with the scene

% To summarize the lights use this
thisR.get('light print');

% We can get a specific light by its name
thisR.get('light', 'distant_light_L')

% Or we can get the light from its index (number) in this list.
thisR.get('light', 1)

%% Remove all the lights

thisR.set('light', 'all', 'delete');
thisR.get('light print');

%% Types of lights

% There are a few different types of lights.  The different types we
% control in ISET3d are defined in piLightCreate;  To see the list of
% possible light types use
%
piLightCreate('list available types')

%% Add a spot light
%
% The spot light is defined by
%
%  * the cone angle parameter, which describes how far the spotlight
%  spreads (in degrees of visual angle), and
%  * the cone delta angle parameter describes how rapidly the light falls
%  off at the edges (also in degrees).
%

% NOTE: 
% Unlike most of ISET3d, you do not have the freedom to put spaces into the
% key/val parameters for this function.  Thus, coneangle cannot be 'cone
% angle'.
%
% Until the v4 textbook is published, only informal sources are available
% for light parameters.
% 
% Many are the same as v3, documented here
% https://www.pbrt.org/fileformat-v3.html#lights
%
% But there are a lot of changes for v4. Here is a web resource we use:
% https://github.com/shadeops/pbrt_v3-to-v4_migration
%
% We are also starting to add v4 information to the iset3D wiki:
% https://github.com/ISET/iset3d/wiki
% That will eventually show up in a wiki for iset3d-v4
%
lightName = 'new_spot_light_L';
newLight = piLightCreate(lightName,...
                        'type','spot',...
                        'spd','equalEnergy',...
                        'specscale', 1, ...
                        'coneangle', 15,...
                        'conedeltaangle', 10, ...
                        'cameracoordinate', true);
thisR.set('light', newLight, 'add');
thisR.get('light print');

%% Set up the render parameters

% This moves the camera closer to the color checker,
% which illustrates the effects of interest here better.
% 
% Shift is in meters.  You have to know something about the
% scale of the scene to use this sensibly.
piCameraTranslate(thisR,'z shift',1); 

thisR.set('render type',{'radiance'});

piWRS(thisR,'name','Equal energy (spot)');

%%  Narrow the cone angle of the spot light a lot

% We just have one light, and can set its properites with
% piLightSet, indexing into the first light.
coneAngle = 10;

thisR.set('light', lightName, 'coneangle', coneAngle);

piWRS(thisR,'name',sprintf('EE spot %d',coneAngle));

%% Shift the light to the right

% The general syntax for the set is to indicate
%
%   'light' - action - lightName or index - parameter value
%
% We shift the light here by 0.1 meters in the x-direction.
thisR.set('light', 'new_spot_light_L', 'translate',[1, 0, 0]);

piWRS(thisR,'name',sprintf('EE spot %d',coneAngle));

%% Rotate the light

% thisR.set('light', 'rotate', lghtName, [XROT, YROT, ZROT], ORDER)
thisR.set('light', 'new_spot_light_L', 'rotate', [0, -15, 0]); % -5 degree around y axis
piWRS(thisR,'name',sprintf('Rotate EE spot'));

%%  Change the light to a point light source 

thisR.set('light', 'all', 'delete');

% Create a point light at the camera position
% The spd spectrum points to a file that is saved in
% ISETCam/data/lights
yellowPoint = piLightCreate('yellow_point_L',...
    'type', 'point', ...
    'spd spectrum', 'Tungsten',...
    'specscale float', 1,...
    'cameracoordinate', true);

thisR.set('light', yellowPoint, 'add');

% Move the point closer to the object
thisR.set('light','yellow_point_L','translate',[0 0 -7])
thisR.get('light print');
piWRS(thisR,'name','Tungsten (point)');

%% Add a second point just to the right
%
% Note:  The blueLEDFlood is too narrow band, we think!
% We should check that (Zly/BW).
%

thisR.set('light', 'all', 'delete');
% Create a point light at the camera position
whitePoint = piLightCreate('white_point_L',...
    'type', 'point', ...
    'spd spectrum', 'D50',...
    'specscale float', 0.5,...
    'cameracoordinate', true);

thisR.set('light', whitePoint, 'add');

% Move the point closer to the object
thisR.set('light','white_point_L','translate',[1 0 -7]);
thisR.get('light print');

% Put the yellow light in again, separated in x
thisR.set('light',yellowPoint,'add');
thisR.set('light','yellow_point_L','translate',[-1 0 -7]);

piWRS(thisR,'name','Yellow and Blue points');

%% When spd is three numbers, we recognize it is rgb values

distLight = piLightCreate('new_dist_L',...
    'type', 'distant', ...
    'spd', [0.3 0.5 1],...
    'specscale float', 1,...
    'cameracoordinate', true);

thisR.set('light', 'all', 'delete');
thisR.set('light',distLight,'add');

thisR.get('lights print');

piWRS(thisR,'name','Blue (distant)');

%% Add an environment light

thisR.set('light', 'all', 'delete');

fileName = 'room.exr';
exampleEnvLight = piLightCreate('room_light_L', ...
    'type', 'infinite',...
    'mapname', fileName);

thisR.set('lights', exampleEnvLight, 'add');

% Put the window behind the checkerboard.
thisR.set('light', 'room_light_L', 'rotation', [-90 0 0]);
thisR.set('light', 'room_light_L', 'rotation', [0 0 90]);

piWRS(thisR);

%%  Now rotate the skymap around the z dimension.  

% As is often the case, the X Y Z dimensions are annoying to interpret.  We
% need better tools
for ii=1:3
    thisR.set('light', 'room_light_L', 'rotation', [0 0 10]);
    piWRS(thisR,'name','Environment light');
end

%% END