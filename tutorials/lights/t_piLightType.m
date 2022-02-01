%% t_piLightType
%
%   PBRT V4 - illustrate adding and modifying light types
%
%   Includes multiple spot lights, inf light (which is a skymap) and inf
%   light which is just a large uniform global illumination.
%
% ZLy, BW
%
% See also
%

%% Initialize ISET and Docker

% We start up ISET and check that the user is configured for docker
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the file

% thisR = piRecipeDefault('scene name','checkerboard');

% Scale the sphere to 1 meter size.  This should be the default sphere, 1
% meter size at location 0,0,0 (BW)
% {
thisR = piRecipeDefault('scene name','sphere');
thisR.set('asset','001_Sphere_O','scale',2/380);
% Put the camera 3 meters away
thisR.set('from',[0 0 3]);
%}

% Remove all the lights
thisR.set('light', 'all', 'delete');

%% Add one equal energy light

% The cone angle describes how far the spotlight spreads
% The cone delta angle describes how rapidly the light falls off at the
% edges
spotWhite = piLightCreate('spotWhite',...
    'type','spot',...
    'spd','equalEnergy',...
    'specscale float', 1,...
    'coneangle',20,...
    'cameracoordinate', true);

thisR.set('light', spotWhite, 'add');

% Check the light list
thisR.show('lights');

%% Render depth and radiance

thisR.set('render type',{'radiance','depth'});

piWRS(thisR,'name','EE spot');

%%  Narrow the cone angle of the spot light a lot
thisR.set('light', 'spotWhite', 'coneangle', 10);

piWRS(thisR,'name','EE spot angle 10');

%%  Change the light and render again

thisR.set('light', 'spotWhite', 'coneangle', 25);

piWRS(thisR,'name','EE spot angle 25')

%%  Change the light and render again

% A very bright blue spotlight
spotBlue = piLightCreate('spotBlue',...
    'type','spot',...
    'spd',[0 0 1],...
    'specscale float', 20,...
    'coneangle',20,...
    'cameracoordinate', true);

thisR.set('light', 'spotWhite', 'replace', spotBlue);

% Infinite means the light is on the whole sphere with a particular SPD.
roomLight = piLightCreate('inf light',...
    'type','infinite',...
    'spd','D50');

thisR.set('light', roomLight, 'add');

thisR.show('lights');

piWRS(thisR,'name',sprintf('EE infinite'));

%% One more example
thisR.set('light', 'all', 'delete');

spotYellow = piLightCreate('spotYellow',...
    'type','spot',...
    'spd',[1 1 0],...
    'specscale float', 20,...
    'coneangle',45,...
    'cameracoordinate', true);


% Infinite means the light is on the whole sphere with a particular SPD.
roomLight = piLightCreate('room',...
    'type','infinite',...
    'mapname', 'room.exr');

thisR.set('light', spotBlue, 'add');
thisR.set('light','spotBlue','from',thisR.get('from') + [3 0 0]);
thisR.set('light','spotBlue','to',[0 0 0]);

thisR.set('light', spotYellow, 'add');
thisR.set('light','spotYellow','from',thisR.get('from') + [-3 0 0]);
thisR.set('light','spotYellow','to',[0 0 0]);

thisR.set('light', roomLight, 'add');

thisR.show('lights');

piWRS(thisR,'name',sprintf('EE infinite'))

%% Rotate the skymap

% We should make a set
%
%   thisR.set('light','room','rotate',{[xxx],[xxx]});
%
% And we should explain what the heck the xxx values are.
thisR.set('light', roomLight.name, 'rotation', [0 0 1]);
thisR.set('light', roomLight.name, 'rotation', [-90 45 0]);
% roomLight = piLightSet(roomLight, 'rotation val', {[0 0 1 0], [-90 45 0 0]});
thisR.set('light', 'room', 'replace', roomLight);

piWRS(thisR,'name','Rotated skymap');

%% END

