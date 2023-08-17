%% t_piLightType
%
%   Initial Experiments with Projected Lights
%   (with the hope that it can become a tutorial when it works:))
%
%   D. Cardinal, Stanford University, August, 2020
%
% See also
%

%% Initialize ISET and Docker

% We start up ISET and check that the user is configured for docker
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the file

thisR = piRecipeDefault('scene name','checkerboard');

% Put the camera 3 meters away
thisR.set('from',[0 0 3]);


% Remove all the lights
thisR.set('light', 'all', 'delete');

%% Add one projection light

% The cone angle describes how far the spotlight spreads
% The cone delta angle describes how rapidly the light falls off at the
% edges
projectionLight = piLightCreate('ProjectedLight',...
    'type','projection',...
    'fov',20,...
    'filename', 'rainbow.jpg'); % seems to want a path?

thisR.set('light', projectionLight, 'add');

% Check the light list
thisR.show('lights');

%% Render depth and radiance

thisR.set('render type',{'radiance','depth'});
thisR.set('name','ProjectionLight');

piWRS(thisR);

