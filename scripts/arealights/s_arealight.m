%% Explore light creation with new area light parameters
%
%
% See also
%   t_arealight.m

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Let's make a recipe with just an area light
% We can load this area light and position it in the scene different
% ways.

% We start with this full recipe of area lights
fileName = fullfile(piRootPath, 'data','scenes','arealight','arealight.pbrt');
thisR    = piRead(fileName);

idx1 = piAssetSearch(thisR,'branch name','AreaLightRectangle.001');
idx2 = piAssetSearch(thisR,'branch name','AreaLightRectangle.002');
idx3 = piAssetSearch(thisR,'branch name','AreaLightRectangle.003');
idx = cat(2,idx1,idx2,idx3);
idx = sort(idx,'descend');
for ii=1:numel(idx),thisR.set('asset',idx(ii),'delete'); end

idx1 = piAssetSearch(thisR,'light name','AreaLightRectangle.001');
idx2 = piAssetSearch(thisR,'light name','AreaLightRectangle.002');
idx3 = piAssetSearch(thisR,'light name','AreaLightRectangle.003');
idx = cat(2,idx1,idx2,idx3);
idx = sort(idx,'descend');
for ii=1:numel(idx),thisR.set('asset',idx(ii),'delete'); end

idx = 12:-1:7;
for ii=1:numel(idx),thisR.set('asset',idx(ii),'delete'); end

piWRS(thisR);


thisR.set('asset','Plane_m_B','delete');
thisR.set('asset','Plane_B','delete');

thisR.set('node','Camera_B','delete');
thisR.set('node',3,'delete');
thisR.set('node',2,'delete');
thisR.show;

% The no number is the blue one
% The 002 light is the green one.
% The 001 is the red one
% the 003 must be the yellow one.

thisR.show('lights');

scene = piWRS(thisR,'render flag','hdr');

%% Plot the luminance across a line

roiLocs = [1 74];
sz = sceneGet(scene,'size');
scenePlot(scene,'luminance hline',roiLocs);
ieROIDraw(scene,'shape','line','shape data',[1 sz(2) roiLocs(2) roiLocs(2)]);

%% The green light is bright.  Let's reduce its intensity.
gScale = thisR.get('light','Area_Green_L','specscale');

thisR.set('light','Area_Green_L','specscale',gScale/4);
scene = piWRS(thisR,'render flag','hdr');

%%
roiLocs = [1 74];
sz = sceneGet(scene,'size');
scenePlot(scene,'luminance hline',roiLocs);
ieROIDraw(scene,'shape','line','shape data',[1 sz(2) roiLocs(2) roiLocs(2)]);

%% Set the light adjust the light properties

lNames = thisR.get('light','names');

% The spread of car headlights is about 
for ii=1:numel(lNames)
    thisR.set('light',lNames{ii},'spread val',ii*10);
end

scene = piWRS(thisR,'render flag','hdr');

%% Plot the luminance
roiLocs = [1 74];
sz = sceneGet(scene,'size');
scenePlot(scene,'luminance hline',roiLocs);
ieROIDraw(scene,'shape','line','shape data',[1 sz(2) roiLocs(2) roiLocs(2)]);

roiRect = [416 124 34 42];
scenePlot(scene,'radiance energy roi',roiRect);
ieROIDraw(scene,'shape','rectangle','shape data',roiRect);%%

% The yellow must be in the plane
thisR.set('asset', 'Area_Yellow_L', 'rotate', [-30, 0, 0]); % -5 degree around y axis

% The red and blue are in the plane
thisR.set('asset', 'Area_Red_L', 'rotate', [0, 0, 30]); % -5 degree around y axis
thisR.set('asset', 'Area_Blue_L', 'rotate', [0, 0, -30]); % -5 degree around y axis

piWRS(thisR,'render flag','hdr');

%% Change the SPD of the lights to halogen

lList = {'LED_3845','LED_4613','halogen_2913','CFL_5780'};

% Setting the name is enough.  At some point we read the light file
% and write out the values in piWRS().
thisR.set('light','Area_Yellow_L','spd',lList{1});
thisR.set('light','Area_Red_L','spd',lList{2});
thisR.set('light','Area_Green_L','spd',lList{3});
thisR.set('light','Area_Blue_L','spd',lList{4});

piWRS(thisR,'render flag','hdr');

%%  Spectrum of an LED light that might be found in a car headlight

ieNewGraphWin; hold on;
for ii=1:numel(lList)
    [ledSPD,wave] = ieReadSpectra(lList{ii});
    if ii==1, plotRadiance(wave,ledSPD);
    else, hold on; plot(wave,ledSPD);
    end
end

for ii=1:numel(lList)
    [ledSPD,wave] = ieReadSpectra(lList{ii});
    XYZ = ieXYZFromEnergy(ledSPD',wave);
    xy  = chromaticity(XYZ);
    if ii == 1
        chromaticityPlot; 
        hold on; plot(xy(1),xy(2),'o');
    else, hold on; plot(xy(1),xy(2),'o');
    end
end

%% END

