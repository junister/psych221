%% Make some targets
%
% Two ways
%    1.  Textures on the flat surface
%    2.  Place an image as a texture on the flat surface
%

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Find the Cube face and adjust its size

thisR = piRecipeCreate('flat surface');
idx = piAssetSearch(thisR,'object name','Cube');

% Make the object size understandable so we see the whole shape
thisR.set('asset',idx,'size',[100 1 100]);
thisR.show('objects');

% Equivalent to
% sz = thisR.get('asset',idx,'size');
% thisR.set('asset',idx,'scale',[100 1 100]./sz);

%% This is how to make a texture

% We have example png textures files in the materials/textures directory.
% To make a material with a texture, we create the texture and the
% material.
materialName = 'squarewave_h_04';   % 'squarewave_h_04';

% First the texture
textureMap = fullfile(piDirGet('textures'),[materialName,'.png']);
thisM.texture = piTextureCreate(materialName,...
    'format', 'spectrum',...
    'type', 'imagemap',...
    'filename', textureMap);

% Then the material
thisM.material = piMaterialCreate(materialName,'type','diffuse','reflectance val',materialName);

% Finally, add the material and texture object to the recipe
thisR.set('material', 'add', thisM);

%  Attach the material to the surface and render
thisR.set('asset',idx,'material name',materialName);
% thisR.show('objects');

% I get an error the first time I run this, and then it runs the second
% time.  Must debug. (BW).
piWRS(thisR);
    
%% You can scale the pattern this way

sfactor = 3;
thisR.set('texture',materialName,'vscale',sfactor);
piWRS(thisR,'name',sprintf('hbars %02d',sfactor));

%% To see the properties you can change

validTextures = piTextureCreate('help');

%%