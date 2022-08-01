%% Illustrate use of material presents
%
% We have some materials with easy to understand names that we can use
% to install in a scene.  This script illustrates how to find one of
% them and insert it into a recipe.
%
%

%% 
ieInit;
if ~piDockerExists, piDockerConfig; end

%%  Set up a scene
sceneName = 'materialball'; 
material_name = 'OuterBall'; 
thisR = piRecipeDefault('scene name',sceneName);
thisR.set('filmresolution',[1200,900]/3);
thisR.set('pixelsamples',128);

%% add a skymap

fileName = 'room.exr';
thisR.set('skymap',fileName);

%% Add checkerboard texture to the InnerBall materials

checkerboard = piTextureCreate('checkerboard_texture',...
    'type', 'checkerboard',...
    'uscale', 16,...
    'vscale', 16,...
    'tex1', [.01 .01 .01],...
    'tex2', [.99 .99 .99]);
thisR.set('texture','add',checkerboard);
thisR.set('material','InnerBall','reflectance type','texture');
thisR.set('material','InnerBall','reflectance val', checkerboard.name);

piWRS(thisR,'gamma',0.85,'name','checker board');

%% Show all the preset materials
piMaterialPresets('list material');

%%  Create a new material from the presents

mat_type = 'metal-spotty-discoloration'; 
new_material = piMaterialPresets(mat_type,material_name);

% The returned new material is a struct that has a slot for material.
% It may also have a slot for a texture.
thisR.set('material','replace', material_name, new_material.material);

if isfield(new_material, 'texture') && ~isempty(new_material.texture)
    for ii = 1:numel(new_material.texture)
        thisR.set('texture','add',new_material.texture{ii});
    end
end

% Convert textures in a recipe to PNG format
% We put this in piWrite.
% thisR = piTextureFileFormat(thisR);

piWRS(thisR,'gamma',0.85,'name',mat_type);

%% Add a red glass material

mat_type = 'red-glass';
new_material = piMaterialPresets(mat_type,material_name);

%%  This chunk of code should become simpler
%
%   It might be something like piMaterialsInsert(thisR,new_material);
%  
if isfield(new_material, 'texture') && ~isempty(new_material.texture)
    for ii = 1:numel(new_material.texture)
        thisR.set('texture','add',new_material.texture{ii});
    end
end

if isfield(new_material, 'mixMat') && ~isempty(new_material.mixMat)
    for ii = 1:numel(new_material.mixMat)
        thisR.set('material','add',new_material.mixMat{ii});
    end
end

thisR.set('material','replace', material_name, new_material.material);

%%
scene = piWRS(thisR,'gamma',0.85,'name',mat_type);

%{
% Sometimes we write out the materials so people can see the expected
% appearance.
 scene_rgb = sceneGet(scene,'rgb');
 outfileName = fullfile(piRootPath,'data/materials/previews',[mat_type,'.jpg']);
 imwrite(scene_rgb,outfileName);
%}

%% render cloth material

sceneName = 'materialball_cloth';
thisR = piRecipeDefault('scene name',sceneName);

thisR.set('filmresolution',[1200,900]/1.5);
thisR.set('pixelsamples',512);

% add an environment map
fileName = 'room.exr';
thisR.set('skymap',fileName);

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

%%  Add a texture.
mat_type = 'fabric-leather-var2'; 
material_name = 'cloth'; 

new_material = piMaterialPresets(mat_type,material_name);

%%
thisR.set('material','replace', material_name, new_material.material);
if isfield(new_material, 'texture') && ~isempty(new_material.texture)
    for ii = 1:numel(new_material.texture)
        thisR.set('texture','add',new_material.texture{ii});
    end
end

%%

piWRS(thisR,'gamma',0.85,'name',mat_type);

%%