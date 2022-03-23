%% Obtain the relative illumination for a an arbitrary camea

% Created by Thomas Goossens, Stanford University, 2022
% Adapted for iset3d-v4, D.Cardinal

%% Define receipe with white surface
thisR = piRecipeDefault('scene','flatSurface');

% Set illuminant: make sure it is infinite
% Set Light that is all around the world, so do not depend on the size of the target
% This is especially important for wide angle lenses
%thisR.set('light','#1_Light_type:point','type','infinite');
lightName = 'from camera';
ourLight = piLightCreate(lightName,...
                        'type','infinite');
recipeSet(thisR,'lights', ourLight,'add');


%% Define Camera (Change this to whatever camera setup you use
camera = piCameraCreate('omni','lensfile','dgauss.22deg.50.0mm.json');
thisR.set('camera',camera);
thisR.set('focal distance',3); % DO this or adjust film distance


% You don't need much resolution because relative illumination is relatively slow in variation
filmresolution = [300 1];
sensordiagonal_mm = [65]; % Adjust to your liking
pixelsamples = 600;  % Adjust to your liking to reduce noise

thisR.set('pixel samples',pixelsamples);
thisR.set('film diagonal',sensordiagonal_mm,'mm');
thisR.set('film resolution',filmresolution);

%% Render scene
piWrite(thisR);
[oiTemp,result] = piRender(thisR,'render type','radiance');

%% Make Relative illumination plot
fig=figure(1);clf; hold on;

% Read horizontal line and normalize by maximum value
maxnorm = @(x)x/max(x);
relativeIllumPBRT = maxnorm(oiTemp.data.photons(1,:,1));

% Construct x axis [-filmwidth/2 .. filmwidth/2] for given film resolution
resolution=thisR.get('film resolution');resolution=resolution(1);
xaxis = 0.5*thisR.get('filmwidth') *linspace(-1,1,resolution);

% Plot the relativ illumination
hpbrt = plot(xaxis,relativeIllumPBRT,'color',[0.83 0 0 ],'linewidth',2);

xlim([0 inf]); % Only show positive x values because of symmetry
xlabel('Image height  on film (mm)');
