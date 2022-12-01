%% Experiment with microlens offsets
%
% We are introducing piMicrolensWrite() so we control the microlens.
% It works with the omni branch and the GPU code on MUX.  We are
% writing Matlab code to control the offsets.
%
% The logic of the ray trace using the offsets needs some explanation.
%
% PBRT traces rays from each film sample point (pixel.  This code
% places a 2x2 grid below each microlens.  So if we create a microlens
% array with 256 x 256 microlenses, and we set the film resolution to
% 512 x 512, we will have 4 pixels under each microlens.
%
% The tracing starts with a pixel and then traces through the
% microlens at the corresponding position.  Each pixel is always
% (implicitly) assigned one microlens from the list of 256 x 256.  How
% does it choose its microlens?  
%
% Once it has its microlens, it looks up the microlens surface and
% offset properties to trace into the imaging lens and then to the
% scene.
%
%
% See also
%  s_sensorDPAF (ISETCam)

%% Initialize a scene and oi
ieInit;
if ~piDockerExists, piDockerConfig; end

%%  Get the chess set scene

thisR = piRecipeDefault('scene name','chessSet');

% piWRS(thisR);

%% Set up the combined imaging and microlens array

% {
uLensName = 'microlens.json';
iLensName = 'dgauss.22deg.3.0mm.json';
% iLensName = 'dgauss.22deg.50.0mm.json';

uLensHeight = 0.0028;        % 2.8 um - each covers two pixels

% The spec is for x and y cimensions (not row and column)
% When this gets very big, the lenses may overlap one another and
% block some light?
nMicrolens = [64 64]*4;     % Did a lot of work at 40,40 * 8
%}

% We need to redo this piece of code, replacing it with
% piMicrolensWrite
%
% [combinedLensFile, uLens, iLens] = lensCombine(uLensName,iLensName,uLensHeight,nMicrolens);
%
combinedLensFile = 'dgauss.22deg.3.0mm+microlens.json';
% {
cLens = jsonread(combinedLensFile);
% The offset is with respect to the microlens position assuming they
% were all placed in a regular rectangular grid on the film.
cLens.microlens.offsets(:,:) = 0.7e-6;   % Unit is meters for this test.
jsonwrite('test.json',cLens);
combinedLensFile = fullfile(pwd,'test.json');
%}
thisR.camera = piCameraCreate('omni','lensFile',combinedLensFile);

%% Set up the film parameters
%
% We want the OI to be calculated at 4 positions behind each microlens.
% There will be two positions for each of the pixels.  The pair of up/down
% positions will be summed by the sensor into a single pixel response.  The
% pair of left/right positions will be the two pixels behind the microlens.
%

pixelsPerMicrolens = 2;

pixelSize  = uLens.get('lens height')/pixelsPerMicrolens;   % mm
filmwidth  = nMicrolens(2)*uLens.get('diameter','mm');       % mm
filmheight = nMicrolens(1)*uLens.get('diameter','mm');       % mm
filmresolution = [filmheight, filmwidth]/pixelSize;

%{
dRange = thisR.get('depth range');

thisR.set('focus distance',dRange(2));
%}

%{
thisR.set('focus distance',0.6);
%}

% This is the size of the film/sensor in millimeters
thisR.set('film diagonal',sqrt(filmwidth^2 + filmheight^2));

% Film resolution -
thisR.set('film resolution',filmresolution);

% This is the aperture of the imaging lens of the camera in mm
thisR.set('aperture diameter',10);

% Adjust for quality
thisR.set('rays per pixel',32);

thisR.get('depth range') % This calls the docker container to get the depth

% piWRS(thisR);

%% Make a dual pixel sensor that has rectangular pixels
%

% Turn this into a function like sensorCreate('dual pixel');

sensor = sensorCreate;
sz = sensorGet(sensor,'pixel size');

% We make the height
sensor = sensorSet(sensor,'pixel width',sz(2)/2);

% Add more columns
rowcol = sensorGet(sensor,'size');
sensor = sensorSet(sensor,'size',[rowcol(1)*2, rowcol(2)*4]);

% Set the CFA pattern accounting for the dual pixel architecture
sensor = sensorSet(sensor,'pattern',[2 2 1 1; 3 3 2 2]);

%% Render

thisR.set('render type',{'radiance','depth'});
oi = piWRS(thisR);

%
%piWrite(thisR);
%[oi, result] = piRender(thisR,'render type','radiance');
%oiWindow(oi);

%% Compute the sensor data

% Notice that we get the spatial structure of the image right, even though
% the pixels are rectangular.
sensor = sensorCompute(sensor,oi);
sensor = sensorSet(sensor,'name','DPAF');
sensorWindow(sensor);

%%  Extract the left and right images from the dual pixel array

volts = sensorGet(sensor,'volts');
leftVolts = volts(1:end,1:2:end);
rightVolts = volts(1:end,2:2:end);

%% Create sensors for left and right image
leftSensor = sensorCreate;
leftSensor = sensorSet(leftSensor,'size',size(leftVolts));
leftSensor = sensorSet(leftSensor,'volts',leftVolts);
leftSensor = sensorSet(leftSensor,'name','left');

sensorWindow(leftSensor);
%%
rightSensor = sensorCreate;
rightSensor = sensorSet(rightSensor,'size',size(rightVolts));
rightSensor = sensorSet(rightSensor,'volts',rightVolts);
rightSensor = sensorSet(rightSensor,'name','right');
sensorWindow(rightSensor);

%%
rightSensorData = sensorPlot(rightSensor,'electrons hline',[88 88]);
% sensorPlot(rightSensor,'electrons hline',[89 89]);
c = [1 176 89 89];
[shapeHandle,ax] = ieROIDraw('sensor','shape','line','shape data',c);
leftSensorData = sensorPlot(leftSensor,'electrons hline',[88 88]);
% sensorPlot(leftSensor,'electrons hline',[89 89]);

ieNewGraphWin;
plot(leftSensorData.pos{1},leftSensorData.data{1},'b-',...
    rightSensorData.pos{1},rightSensorData.data{1},'r-');

%%
bothVolts = (leftVolts + rightVolts)/2;
sensorBoth = rightSensor;
sensorBoth = sensorSet(sensorBoth,'volts',bothVolts);
sensorWindow(sensorBoth);
ipBoth = ipCreate;
ipBoth = ipCompute(ipBoth,sensorBoth);
ipWindow(ipBoth);



%%
ip = ipCreate;
ip = ipCompute(ip,sensor);
ipWindow(ip);

leftip = ipCreate;
leftip = ipCompute(leftip,leftSensor);
ipWindow(leftip);
leftuData = ipPlot(leftip,'horizontal line',[89 89]);

rightip = ipCreate;
rightip = ipCompute(rightip,rightSensor);
ipWindow(rightip);
rightuData = ipPlot(rightip,'horizontal line',[89 89]);
%% END

