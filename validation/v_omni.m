%% Verify omni camera model in PBRT
%
% This is the most general camera model we have that also includes
% microlens modeling at the ray level (not wave).
%
% D. Cardinal, Feb, 2022
%
% See also
%   piIntro_lens

%% Initialize

ieInit;
if ~piDockerExists, piDockerConfig; end

%%  Scene and light
thisR = piRecipeDefault('scene name','cornell box');

lightName = 'from camera';
ourLight = piLightCreate(lightName,...
                        'type','distant',...
                        'cameracoordinate', true, ...
                        'specscale',50);
thisR.set('lights', ourLight,'add');
thisR.set('skymap','room.exr');

%% No lens or omnni camera. Just a pinhole to render a scene radiance

thisR.set('object distance',1);
thisR.camera = piCameraCreate('pinhole'); 
scene = piWRS(thisR);

%% Omni with a standard lens

thisR.set('object distance',1);
thisR.camera = piCameraCreate('omni','lens file','dgauss.22deg.12.5mm.json');

thisR.set('film diagonal',5); % mm
thisR.get('film distance','mm');
piWRS(thisR);

%% Omni with a fisheye lens

% Create a list of lens files in ISETCam data/lens
lList = lensList('quiet',true);

% Examples
% ll = 8;   % dgauss.22deg.3.0mm.json
% ll = 16;  % fisheye.87deg.12.5mm.json
% ll = 19;  % fisheye.87deg.6.0mm.json

ll = 18;    % fisheye.87deg.50.0mm.json

% Move the camera back a bit to capture more of the scene
thisR.set('object distance',8);
thisR.camera = piCameraCreate('omni', 'lens file',lList(ll).name);
thisR.set('skymap','sky-cathedral_interior.exr');
oi = piWRS(thisR);oi = piAIdenoise(oi); 
ieReplaceObject(oi); oiWindow;

%% END



