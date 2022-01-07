function [thisR, materialNames] = piMaterialsInsert(thisR,varargin)
% Insert default materials (V4) into a recipe
%
% Synopsis
%  [thisR, materialNames] = piMaterialsInsert(thisR,varargin)
%
% Brief description
%   Makes it easy to add a collection of materials to use for the scene
%   objects. 
%
% Input
%   thisR - Recipe
%
% Output
%   thisR - Recipe now has additional materials attached
%   materialNames - cell array, but use thisR.get('print  materials')
%
% Description
%   We add materials with textures, colors, some plastics.  It gives a list
%   of materials that we are likely to want.
%
% See also

%% Need variable checking

materialNames = {};

%% Interesting materials

thisMaterialName = 'glass';
thisMaterial = piMaterialCreate(thisMaterialName, 'type', 'dielectric','eta','glass-BK7');
thisR.set('material', 'add', thisMaterial);
materialNames{end+1} = thisMaterialName;

thisMaterialName = 'mirror';
thisMaterial = piMaterialCreate(thisMaterialName, 'type', 'conductor',...
    'roughness',0,'eta','metal-Ag-eta','k','metal-Ag-k');
thisR.set('material', 'add', thisMaterial);

%% Diffuse colors
thisMaterialName = 'Red'; 
thisMaterial = piMaterialCreate(thisMaterialName, 'type', 'diffuse');
thisMaterial = piMaterialSet(thisMaterial,'reflectance',[1 0.3 0.3]);
thisR.set('material', 'add', thisMaterial);
materialNames{end+1} = thisMaterialName;

thisMaterialName = 'White'; 
thisMaterial = piMaterialCreate(thisMaterialName, 'type', 'diffuse');
thisMaterial = piMaterialSet(thisMaterial,'kd',[1 1 1]);
thisR.set('material', 'add', thisMaterial);
materialNames{end+1} = thisMaterialName;

% Make a new material like White, but color it gray
thisMaterialName = 'Gray'; 
thisMaterial = piMaterialCreate(thisMaterialName, 'type', 'diffuse');
thisMaterial = piMaterialSet(thisMaterial,'kd',[0.2 0.2 0.2]);
thisR.set('material', 'add', thisMaterial);
materialNames{end+1} = thisMaterialName;

%% Goal:  shiny colors
thisMaterialName = 'Red_plastic'; 
thisMaterial = piMaterialCreate(thisMaterialName, 'type', 'coateddiffuse');
thisMaterial = piMaterialSet(thisMaterial,'kd',[1 0.3 0.3]);
thisR.set('material', 'add', thisMaterial);
materialNames{end+1} = thisMaterialName;

thisMaterialName = 'White_plastic'; 
thisMaterial = piMaterialCreate(thisMaterialName, 'type', 'coateddiffuse');
thisMaterial = piMaterialSet(thisMaterial,'kd',[1 1 1]);
thisR.set('material', 'add', thisMaterial);
materialNames{end+1} = thisMaterialName;

thisMaterialName = 'Gray_plastic'; 
thisMaterial = piMaterialCreate(thisMaterialName, 'type', 'coateddiffuse');
thisMaterial = piMaterialSet(thisMaterial,'kd',[0.2 0.2 0.2]);
thisR.set('material', 'add', thisMaterial);
materialNames{end+1} = thisMaterialName;

%% Materials based on textures

% Maybe we should insert the textures first, and then create the
% materials.

% Like insert textures, and then

% Create materials.  Not sure this is done properly for V4.

% {
% Wood grain (light, large grain)
thisMaterialName = 'wood001';
thisTexture = piTextureCreate(thisMaterialName,...
    'format', 'spectrum',...
    'type', 'imagemap',...
    'filename', 'woodgrain001.png');
thisR.set('texture', 'add', thisTexture);
thisMaterial = piMaterialCreate(thisMaterialName,'type','diffuse','kd val',thisMaterialName);
thisR.set('material', 'add', thisMaterial);
materialNames{end+1} = thisMaterialName;

% Wood grain (light, large grain)
thisMaterialName = 'wood002';
thisTexture = piTextureCreate(thisMaterialName,...
    'format', 'spectrum',...
    'type', 'imagemap',...
    'filename', 'woodgrain002.exr');
thisR.set('texture', 'add', thisTexture);
thisMaterial = piMaterialCreate(thisMaterialName,'type','diffuse','kd val',thisMaterialName);
thisR.set('material', 'add', thisMaterial);
materialNames{end+1} = thisMaterialName;

% Mahogany 
thisMaterialName = 'mahogany';
thisTexture = piTextureCreate(thisMaterialName,...
    'format', 'spectrum',...
    'type', 'imagemap',...
    'filename', 'mahoganyDark.exr');
thisR.set('texture', 'add', thisTexture);
thisMaterial = piMaterialCreate(thisMaterialName,'type','diffuse','kd val',thisMaterialName);
thisR.set('material', 'add', thisMaterial);
materialNames{end+1} = thisMaterialName;

% Brick wall
thisMaterialName = 'brickwall';
thisTexture = piTextureCreate(thisMaterialName,...
    'format', 'spectrum',...
    'type', 'imagemap',...
    'filename', 'brickwall001.png');
thisR.set('texture', 'add', thisTexture);
thisMaterial = piMaterialCreate(thisMaterialName,'type','diffuse','kd val',thisMaterialName);
thisR.set('material', 'add', thisMaterial);
materialNames{end+1} = thisMaterialName;

% Marble
thisMaterialName = 'marbleBeige';
thisTexture = piTextureCreate(thisMaterialName,...
    'format', 'spectrum',...
    'type', 'imagemap',...
    'filename', 'marbleBeige.exr');
thisR.set('texture', 'add', thisTexture);
thisMaterial = piMaterialCreate(thisMaterialName,'type','coateddiffuse','kd val',thisMaterialName);
thisR.set('material', 'add', thisMaterial);
materialNames{end+1} = thisMaterialName;

%% This will become a parameter some day.

if true
    thisR.get('print materials');
end

end