%% s_sanmiguel
%
% This one is really big, and it must be read as Copy, not PARSE, for
% now.
%
% 299 materials, 511 textures.  Many variants.  Really big.  It is
% taking several minutes to load.  Not sure it will complete.
% When it does, maybe we should save the recipe.
%

%{

Reads to a thisR, but then fails on the render with this error

See the file LICENSE.txt for the conditions of the license.

[1m[31mWarning[0m: Couldn't find supported color space that matches chromaticities: r (0.7347, 0.2653) g (0, 1) b (0.0001, -0.077), w (0.32168, 0.33767). Using sRGB.

[1m[31mError[0m: sanmiguel-balcony-plants_materials.pbrt:500:65: Couldn't find float texture named "Map #483" for parameter "tex"

%}

ieInit;
if ~piDockerExists, piDockerConfig; end

%%  
thisR = piRead(fullfile(piDirGet('scene'),'web','sanmiguel','sanmiguel-balcony-plants.pbrt'));