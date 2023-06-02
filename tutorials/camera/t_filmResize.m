%% t_filmResize
%
% Illustrate the impact of changing the aspect ratio and sampling
% properties of a scene.  We start with manipulating the pinhole camera
% case.  Then move on to omni and finally to human eye.
%
% See also

%% Initialize

ieInit;
if ~piDockerExists, piDockerConfig; end

%% Illustrate with chess set and pinhole camera

% The starting configuration.
thisR = piRecipeCreate('chess set');
ss = thisR.get('spatial samples');

% The camera parameters.  10 mm film diag, 320 x 320 samples
thisR.summarize('camera');

piWRS(thisR);

fprintf('FOV %.1f\n',thisR.get('fov'));

%% Look around with a bigger film diagonal for a momoent

% For a pinhole camera, we store the FOV.  We do not store film
% distance
thisR.get('film distance','mm')

thisR.set('fov',10);

thisR.summarize('camera');

piWRS(thisR);

%% Changing the number of samples

% Samples are (X,Y) in PBRT
thisR.set('spatial samples',round([ss(1),ss(2)/2]));

% We change the (x,y) and now the y dimension determines the FOV.  Since we
% halved the number of samples, we halve the FOV to keep the image width
% the same.  Notice the pawns at the left and right are still there.
thisR.set('fov',15);

thisR.summarize('camera');

piWRS(thisR);

%% Enlarge the FOV

thisR.set('spatial samples',ss);

% This is what the image looks like
thisR.set('fov',45)
thisR.summarize('camera');
piWRS(thisR);

%%  An extreme case of generating a line sample for the pinhole

% This is a problem.  I do not understand why we are seeing the whole
% chess set.  We should only be seeing a strip through the chess set.
nRows = 16;
thisR.set('spatial samples',round([ss(1), nRows]));
thisR.set('fov',30/(ss(2)/nRows));

% The short dimension is very small FOV
thisR.summarize('camera');

% The big dimension is the same 30 deg.
thisR.get('fov other')

piWRS(thisR);

%% Now with a camera lens

% Read from the start and add the lens
thisR = piRecipeCreate('chess set');
ss = thisR.get('spatial samples');

% Many lens files are named with their FOV and focal length
lensfile  = 'dgauss.22deg.6.0mm.json';    % 

% We replace the pinhole with the lens
thisR.camera = piCameraCreate('omni','lensFile',lensfile);

thisR.set('focal distance',1); % Meters
thisR.set('film diagonal',4);

thisR.summarize('camera');
piWRS(thisR);

%% Vary the film size 

% If we reduce it, we also reduce the fov
thisR.get('fov')
thisR.set('film diagonal',2);
thisR.get('fov')

%% Focus

% We can choose the focal distance. 
% This changes the film distance to keep the focus.
thisR.set('focal distance',100);  % Meters
thisR.get('film distance','mm')

% Close distance
thisR.set('focal distance',0.2); % Meters
thisR.get('film distance','mm')

thisR.set('focal distance',1); % Meters
thisR.get('film distance','mm')

%% The camera model uses the diagonal FOV

thisR.get('fov')

% When we change the number of samples, we need to change the diagonal film
% size.  But we do not.  Yet.  This set should change the FOV.
thisR.set('spatial samples',[ss(1)/2 ss(2)]);
thisR.get('fov')

piWRS(thisR);

% Put it back
thisR.set('spatial samples',ss);
thisR.get('fov')

%% Human eye version
thisR.summarize('camera');
