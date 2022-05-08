%% ISET3d material presets       
ieInit;
piDockerConfig;
%%
sceneName = 'materialball';
thisR = piRecipeDefault('scene name',sceneName);
thisR.set('filmresolution',[1200,900]/1.5);
thisR.set('pixelsamples',512);

%% add an environment map
fileName = 'room.exr';
exampleEnvLight = piLightCreate('skylight', ...
    'type', 'infinite',...
    'mapname', fileName);
thisR.set('light', exampleEnvLight, 'add');

%% Add checkerboard texture to inner ball
checkerboard = piTextureCreate('checkerboard_texture',...
    'type', 'checkerboard',...
    'uscale', 16,...
    'vscale', 16,...
    'tex1', [.01 .01 .01],...
    'tex2', [.99 .99 .99]);
thisR.set('texture','add',checkerboard);
thisR.set('material','InnerBall','reflectance type','texture');
thisR.set('material','InnerBall','reflectance val', checkerboard.name);

%%
piMaterialPresets('listmaterial');
mat_type = 'metal-spotty-discoloration'; 
% replace this material
% material_name = 'OuterBall';
material_name = 'OuterBall'; 

[new_material, ~] = piMaterialPresets(mat_type,material_name);

thisR.set('material','replace', material_name, new_material.material);

if isfield(new_material, 'texture') && ~isempty(new_material.texture)
    for ii = 1:numel(new_material.texture)
        thisR.set('texture','add',new_material.texture{ii});
    end
end

thisR = piTextureFileFormat(thisR);

scene = piWRS(thisR,'gamma',0.85,'name',mat_type);

%{
scene_rgb = sceneGet(scene,'rgb');
outfileName = fullfile(piRootPath,'data/materials/previews',[mat_type,'.jpg']);
imwrite(scene_rgb,outfileName);
%}
%% render cloth material
sceneName = 'materialball_cloth';
mat_type = 'fabric-leather-var2'; 
material_name = 'cloth'; 

thisR = piRecipeDefault('scene name',sceneName);
thisR.set('filmresolution',[1200,900]/1.5);
thisR.set('pixelsamples',512);

% add an environment map
fileName = 'room.exr';
exampleEnvLight = piLightCreate('skylight', ...
    'type', 'infinite',...
    'mapname', fileName);
thisR.set('light', exampleEnvLight, 'add');

% Add checkerboard texture to inner ball
checkerboard = piTextureCreate('checkerboard_texture',...
    'type', 'checkerboard',...
    'uscale', 16,...
    'vscale', 16,...
    'tex1', [.01 .01 .01],...
    'tex2', [.99 .99 .99]);
thisR.set('texture','add',checkerboard);
thisR.set('material','InnerBall','reflectance type','texture');
thisR.set('material','InnerBall','reflectance val', checkerboard.name);

[new_material, ~] = piMaterialPresets(mat_type,material_name);
thisR.set('material','replace', material_name, new_material.material);
if isfield(new_material, 'texture') && ~isempty(new_material.texture)
    for ii = 1:numel(new_material.texture)
        thisR.set('texture','add',new_material.texture{ii});
    end
end

thisR = piTextureFileFormat(thisR);

scene = piWRS(thisR,'gamma',0.85,'name',mat_type);






