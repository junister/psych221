%% t_piLightProjection
%
%   Initial Experiments with Projected Lights
%   (with the hope that it can become a tutorial when it works:))
%
%   D. Cardinal, Stanford University, August, 2020
%
% See also
%  t_piIntro_lights

%% Initialize ISET and Docker

% We start up ISET and check that the user is configured for docker
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the file
thisR = piRecipeDefault('scene name','checkerboard');

% By default camera is [0 0 10], looking at [0 0 0].

%% Add one projection light

% Remove all the lights
thisR.set('light', 'all', 'delete');

% The cone angle describes how far the spotlight spreads
% The cone delta angle describes how rapidly the light falls off at the
% edges

% scale appears to be how much to scale the image intensity. We haven't
% seen a difference yet between scale and power fov seems to be working
% well, changing how widely the projection spread.
%
% Remember when you render a collection of scenes, set the mean luminance
% parameter to a negative number so that we don't scale everything back to
% mean luminance of 100 cd/m2.
%
projectionLight = piLightCreate('ProjectedLight', ...
    'type','projection',...
    'scale', 2 ,...
    'fov', 100, ...
    'power', 50, ...
    'cameracoordinate', 1, ...
    'filename string', 'skymaps/headlamp_cropped_flattened_ruler.exr');

%{
img = exrread('headlamp_cropped_flattened_ruler.exr');
ieNewGraphWin; imagesc(img); axis image
%}

%piLightTranslate(projectionLight, 'zshift', -5);
thisR.set('light', projectionLight, 'add');
thisR.show('lights');

% Does translate happen before or after add?
%
% piLightTranslate(projectionLight, 'zshift', -5);

%% Render depth and radiance

thisR.set('name','ProjectionLight');

pLight = piAssetSearch(thisR,'lightname', 'projectedLight');

for ii = 1 % 0:3 in case we want to try options
    % Not sure if this is working
    %thisR.set('asset', pLight, 'rotation', [ii * 30, ii * 60, ii * 90]);
    %piAssetRotate(thisR, pLight, [0 0 90]);

    % try to move the light to a nominal headlamp
    % but our tranform matrix doesn't seem to get written out
    piAssetTranslate(thisR, pLight, [2 -0.5 2]);
    piWRS(thisR,'mean luminance',-1);
end


