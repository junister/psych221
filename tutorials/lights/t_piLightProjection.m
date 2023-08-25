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

% By default camera is [0 0 10], looking at [0 0 0].

% Remove all the lights
thisR.set('light', 'all', 'delete');


%% Add one projection light

% The cone angle describes how far the spotlight spreads
% The cone delta angle describes how rapidly the light falls off at the
% edges

% scale appears to be how much to scale the image, not the light
projectionLight = piLightCreate('ProjectedLight', ...
    'type','projection',...
    'scale',[2 2 2],...
    'fov',45, ...
    'power', 10000, ...
    'cameracoordinate', 1, ...
    'filename string', 'skymaps/headlamp_plain.exr');

%piLightTranslate(projectionLight, 'zshift', -5);
    thisR.set('light', projectionLight, 'add');


% Does translate happen before or after add?
%piLightTranslate(projectionLight, 'zshift', -5);



%% Render depth and radiance

thisR.set('render type',{'radiance','depth'});
thisR.set('name','ProjectionLight');

pLight = piAssetSearch(thisR,'lightname', 'projectedLight');

for ii = 1 % 0:3 in case we want to try options
    % Not sure if this is working
    %thisR.set('asset', pLight, 'rotation', [ii * 30, ii * 60, ii * 90]);
    %piAssetRotate(thisR, pLight, [0 0 90]);

    % try to move the light to a nominal headlamp
    % but our tranform matrix doesn't seem to get written out
    piAssetTranslate(thisR, pLight, [2 -.5 2]);
    piWRS(thisR);
end


