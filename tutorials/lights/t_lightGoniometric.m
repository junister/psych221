%% 
%
%
% LightSource "goniometric" "spectrum I" "spds/lights/equalenergy.spd"  "string filename" "pngExample.exr" "float scale" [1.00000]

% History:
%   10/28/20  dhb  Explicitly show how to compute and look at depth map and
%                  illumination map. The header comments said it did the
%                  latter two, and now it does.

%% init
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the recipe
%
% The MCC image is the default recipe.  We do not write it out yet because
% we are going to change the parameters
thisR = piRecipeDefault;

%% Change the light
%
% There is a default point light.  We delete that.
thisR = piLightDelete(thisR, 'all');

% Add an equal energy distant light for uniform lighting
spectrumScale = 1;
lightSpectrum = 'equalEnergy';
newDistant = piLightCreate('new distant',...
                           'type', 'distant',...
                           'specscale float', spectrumScale,...
                           'spd spectrum', lightSpectrum,...
                           'cameracoordinate', true);
thisR.set('light', newDistant, 'add');
%% Set an output file
%
% This is pretty high resolution given the nature of the target.
thisR.set('integrator subtype','path');
thisR.set('rays per pixel', 16);
thisR.set('fov', 30);
thisR.set('filmresolution', [640, 360]*2);

%% Render and display.
%
% By default we get the radiance map and the depth map. The depth map is
% distance from camera to each point along the line of sight.  See
% t_piIntro_macbeth_zmap for how to compute a zmap.
thisR.set('render type', {'radiance', 'depth'});
scene = piWRS(thisR);

%% END