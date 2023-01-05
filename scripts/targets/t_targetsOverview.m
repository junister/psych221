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

% Make the object size understandable so we see the whole shape
sz = thisR.get('asset',idx,'size');
thisR.set('asset',idx,'scale',[100 1 100]./sz);

%% This is how to make a texture

% We have example png textures files in the materials/textures directory.
% To make a material with a texture, we create the texture and the
% material.
materialName = {'squarewave_v_01'}; % ,'squarewave_v_04','squarewave_v_12'};
for ii=1:numel(materialName)
    % First the texture
    textureMap = fullfile(piDirGet('textures'),[materialName{ii},'.png']);
    thisM.texture = piTextureCreate(materialName{ii},...
        'format', 'spectrum',...
        'type', 'imagemap',...
        'filename', textureMap);

    % Then the material
    thisM.material = piMaterialCreate(materialName{ii},'type','diffuse','reflectance val',materialName{ii});

    % Finally, add the material and texture object to the recipe
    thisR.set('material', 'add', thisM);

    %  Attach the material to the surface and render
    thisR.set('asset',idx,'material name',materialName{ii});
    % thisR.show('objects');

    % I get an error the first time I run this, and then it runs the second
    % time.  Must debug. (BW).
    piWRS(thisR);

end

%% Not sure about how it all scales.

sfactor = 12;
thisR.set('texture',materialName,'uscale',sfactor);
piWRS(thisR,'name',sprintf('hbars %02d',sfactor));

%% Now add the horizontal bar

materialName = 'squarewave_h_01';
textureMap = fullfile(piDirGet('textures'),'squarewave_h_01.png');

thisM.texture = piTextureCreate(materialName,...
            'format', 'spectrum',...
            'type', 'imagemap',...
            'filename', textureMap);
thisM.material = piMaterialCreate(materialName,'type','diffuse','reflectance val',materialName);

% Finally, add the material into the recipe
thisR.set('material', 'add', thisM);

%  Attach the material to the cube and render
thisR.set('asset',idx,'material name',materialName);
thisR.show('objects');

% I get an error the first time I run this, and then it runs the second
% time.  Must debug. (BW).
piWRS(thisR);

%% I do not understand how this scales.

sfactor = 24;
thisR.set('texture',materialName,'vscale',sfactor);
piWRS(thisR,'name',sprintf('hbars %02d',sfactor));

thisR.show('objects');

%%