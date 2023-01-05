%% Make some targets
%
% Two ways
%    1.  Textures on the flat surface
%    2.  Place an image as a texture on the flat surface
%

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% We attach textures on the Cube face

thisR = piRecipeCreate('flat surface');
thisR.show('objects');
idx = piAssetSearch(thisR,'object name','Cube');

%% This is how to make a texture

% We can ad arbitrary PNG files into the materials/textures directory
materialName = 'ringsRays';
textureMap = fullfile(piDirGet('textures'),'ringsrays.png');

matRingsRays.texture = piTextureCreate(materialName,...
            'format', 'spectrum',...
            'type', 'imagemap',...
            'filename', textureMap);
matRingsRays.material = piMaterialCreate(materialName,'type','diffuse','reflectance val',materialName);

% Finally, add the material into the recipe
thisR.set('material', 'add', matRingsRays);

%%  Attach the material to the cube

thisR.set('asset',idx,'material name',materialName);
thisR.show('objects');
piWRS(thisR);

%% Now change some of the parameters of the texture

% properties = piTextureProperties(matRingsRays.texture.type);

thisR.set('texture',materialName,'uscale',1);
thisR.set('texture',materialName,'vscale',1);
thisR.set('texture',materialName,'scale',1.5);

thisR.get('texture',materialName,'uscale')
piWRS(thisR);

%%