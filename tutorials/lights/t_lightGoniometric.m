%% Illustrate creating a goniometric light
%
% TODO:  Create exr files with localized patches so we understand the
% geometry. 
%
% LightSource "goniometric" "spectrum I" "spds/lights/equalenergy.spd"  "string filename" "pngExample.exr" "float scale" [1.00000]

%% init
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the recipe
%
% The MCC image is the default recipe.  We do not write it out yet because
% we are going to change the parameters
thisR = piRecipeCreate('macbethchecker');

%% Change the light
%
% There is a default point light.  We delete that.
thisR = thisR.set('lights','all','delete');

%% Example of a Goniometric light

spectrumScale = 1;
lightSpectrum = 'equalEnergy';
% gonioMap = 'clouds-sky.exr';   % Include the extension
gonioMap = 'sky-blue-sun.exr';   % Include the extension

newGoniometric = piLightCreate('gonio',...
                           'type', 'goniometric',...
                           'specscale float', spectrumScale,...
                           'spd spectrum', lightSpectrum,...
                           'filename', gonioMap);
thisR.set('light', newGoniometric, 'add');

spectrumScale = 0.1;
lightSpectrum = 'equalEnergy';
newDistant = piLightCreate('distant',...
                           'type', 'distant',...
                           'specscale float', spectrumScale,...
                           'spd spectrum', lightSpectrum,...
                           'cameracoordinate', true);
thisR.set('light', newDistant, 'add');

thisR.show('lights');

%% Render and display both lights

piWRS(thisR,'render flag','hdr');

%% Remove the goniometric light

thisR.set('light','gonio_L','delete');
thisR.show('lights');
piWRS(thisR,'render flag','rgb');

%% END