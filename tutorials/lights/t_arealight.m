%% Adjust the spread angle of area lights

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% 
fileName = fullfile(piRootPath, 'data/V4','arealight','arealight.pbrt');
thisR    = piRead(fileName);

%%
piWRS(thisR,'gamma',0.5);

%%
thisR.show('lights');
thisR.set('light','AreaLightRectangle_L','spread val',20);
thisR.set('light','AreaLightRectangle.001_L','spread val',20);
thisR.set('light','AreaLightRectangle.002_L','spread val',20);
thisR.set('light','AreaLightRectangle.003_L','spread val',20);

piWRS(thisR,'gamma',0.5);

