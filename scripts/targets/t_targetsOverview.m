%% Make some targets
%
% Two ways
%    1.  Textures on the flat surface
%    2.  Place an image as a texture on the flat surface
%

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%%

thisR = piRecipeCreate('flat surface');
thisR.show('objects');
idx = piAssetSearch(thisR,'object name','Cube');
