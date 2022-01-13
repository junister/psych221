%% t_piLightType
%
%   BRT V4 light types illustrated
%
% ZLy

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

%% Check the light list
thisR.show('lights');

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

%% Render depth and radiance

thisR.set('render type',{'radiance','depth'});

piWRS(thisR,'name',sprintf('EE spot %d %d %d',val));

%%  Narrow the cone angle of the spot light a lot
thisR.set('light', 'new spot', 'coneangle', 10);

piWRS(thisR,'name','EE spot angle 10');

%%  Change the light and render again

thisR.set('light', 'new spot', 'coneangle', 25);

piWRS(thisR,'name','EE spot angle 25')

%%  Change the light and render again

% Infinite means the light is on the whole sphere with a particular SPD.
infLight = piLightCreate('inf light',...
    'type','infinite',...
    'spd','D50');
thisR.set('light', 'replace', 'new spot', infLight);

thisR.show('lights');

piWRS(thisR,'name',sprintf('EE infinite [%d,%d,%d]',val))

%% One more example
thisR.set('light', 'delete', 'all');

thisR.set('light', 'add', spotlight);

% Infinite means the light is on the whole sphere with a particular SPD.
infLight = piLightCreate('room',...
    'type','infinite',...
    'mapname', 'room.exr');

thisR.set('light','new spot','specscale',10);
thisR.set('light','new spot','from',thisR.get('from') + [2 0 0]);
thisR.set('light','new spot','to',[0 0 0]);
thisR.set('light', 'add', infLight);

thisR.show('lights');

piWRS(thisR,'name',sprintf('EE infinite [%d,%d,%d]',val))

%% END

