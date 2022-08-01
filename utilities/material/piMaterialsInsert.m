function [thisR, materialNames] = piMaterialsInsert(thisR,varargin)
% Insert default materials (V4) into a recipe
%
% Synopsis
%  [thisR, materialNames] = piMaterialsInsert(thisR,varargin)
%
% Brief description
%   Add a collection of materials to use for the scene objects.
%
% Input
%   thisR - Recipe
%
% Optional key/val
%   mtype - Material types to insert.  
%     General classes of materials are
%        {'all','diffuse','glass','wood','brick','testpattern','marble','single'}
%
%     Precomputed materials are either stored here or in piMaterialPresets.
%
% Output
%   thisR - ISET3d recipe with the additional materials inserted
%      To see the full list of materials in a recipe use
%           thisR.get('print  materials')
%
% Description
%   We add materials to a recipe.  It gives a list
%   of materials that we are likely to want.  You can select a group of
%   materials using a cell array as the first argument.
%
%     thisR = piMaterialsInsert(thisR,{'glass','mirror'});
%
% See also
%    piMaterialPreset, t_piIntro_materialInsert

% TODO
%  Deal with integration with piMaterialPresets, polligon, ...

%% Parse
varargin = ieParamFormat(varargin);

p = inputParser;
p.addRequired('thisR',@(x)(isa(x,'recipe')));
p.addParameter('mtype','all',@(x)(iscell(x) || ischar(x)));
p.addParameter('verbose',true,@islogical);
p.parse(thisR,varargin{:});

% Decides which class of materials to insert
mType = p.Results.mtype;

% Make a char into a single entry cell
if ischar(mType), mType = {mType}; end

% Returned variable
materialNames = {};

%% Interesting materials

for ii=1:numel(mType)
    
    if ismember(mType{ii},{'all','glass'})
        
        thisMaterialName = 'glass_frosted';   % barcelona-pavilion
        thisMaterial = piMaterialCreate(thisMaterialName, 'type', 'dielectric');
        thisMaterial = piMaterialSet(thisMaterial,'roughness',0.0001);  % 0
        thisR.set('material', 'add', thisMaterial);
        materialNames{end+1} = thisMaterialName;
        
        thisMaterialName = 'glass_dark';
        thisMaterial = piMaterialCreate(thisMaterialName, 'type', 'dielectric','eta','glass-BK7');
        thisMaterial = piMaterialSet(thisMaterial,'roughness',0);  
        thisR.set('material', 'add', thisMaterial);
        materialNames{end+1} = thisMaterialName;
 
        thisMaterialName = 'glass_exterior';   % Line 1226 bistro
        thisMaterial = piMaterialCreate(thisMaterialName, 'type', 'coatedconductor');
        thisR.set('material', 'add', thisMaterial);
        materialNames{end+1} = thisMaterialName;
        
        % contemporary-bathroom line 72 et seq
        thisMaterialName = 'glass';   % Line 72
        thisMaterial = piMaterialCreate(thisMaterialName, 'type', 'dielectric');
        thisMaterial = piMaterialSet(thisMaterial,'eta',1.5);  
        thisR.set('material', 'add', thisMaterial);
        materialNames{end+1} = thisMaterialName;
    end
    
    if ismember(mType{ii},{'all','mirror'})
        thisMaterialName = 'mirror';
        thisMaterial = piMaterialCreate(thisMaterialName, 'type', 'conductor',...
            'roughness',0,'eta','metal-Ag-eta','k','metal-Ag-k');
        thisR.set('material', 'add', thisMaterial);
        materialNames{end+1} = thisMaterialName;
    end
    
    %% Diffuse colors
    if ismember(mType{ii},{'all','diffuse'})
        
        % Make a new material like White, but color it gray
        thisMaterialName = 'Gray';
        thisMaterial = piMaterialCreate(thisMaterialName, 'type', 'diffuse');
        thisMaterial = piMaterialSet(thisMaterial,'reflectance',[0.2 0.2 0.2]);
        thisR.set('material', 'add', thisMaterial);
        materialNames{end+1} = thisMaterialName;
        
        thisMaterialName = 'Red';
        thisMaterial = piMaterialCreate(thisMaterialName, 'type', 'diffuse');
        thisMaterial = piMaterialSet(thisMaterial,'reflectance',[1 0.3 0.3]);
        thisR.set('material', 'add', thisMaterial);
        materialNames{end+1} = thisMaterialName;
        
        thisMaterialName = 'White';
        thisMaterial = piMaterialCreate(thisMaterialName, 'type', 'diffuse');
        thisMaterial = piMaterialSet(thisMaterial,'reflectance',[1 1 1]);
        thisR.set('material', 'add', thisMaterial);
        materialNames{end+1} = thisMaterialName;
        
    end
    
    if ismember(mType{ii},{'all','glossy'})
        
        %% Goal:  glossy colors
        thisMaterialName = 'Black_glossy';    % barcelona-pavilion scene
        thisMaterial = piMaterialCreate(thisMaterialName, 'type', 'coateddiffuse');
        thisMaterial = piMaterialSet(thisMaterial,'reflectance',[0.02 0.02 0.02]);
        thisMaterial = piMaterialSet(thisMaterial,'roughness',0.0104);
        thisR.set('material', 'add', thisMaterial);
        materialNames{end+1} = thisMaterialName;
        
        thisMaterialName = 'Gray_glossy';
        thisMaterial = piMaterialCreate(thisMaterialName, 'type', 'coateddiffuse');
        thisMaterial = piMaterialSet(thisMaterial,'reflectance',[0.2 0.2 0.2]);
        thisR.set('material', 'add', thisMaterial);
        materialNames{end+1} = thisMaterialName;
        
        thisMaterialName = 'Red_glossy';
        thisMaterial = piMaterialCreate(thisMaterialName, 'type', 'coateddiffuse');
        thisMaterial = piMaterialSet(thisMaterial,'reflectance',[1 0.3 0.3]);
        thisR.set('material', 'add', thisMaterial);
        materialNames{end+1} = thisMaterialName;
        
        thisMaterialName = 'White_glossy';
        thisMaterial = piMaterialCreate(thisMaterialName, 'type', 'coateddiffuse');
        thisMaterial = piMaterialSet(thisMaterial,'reflectance',[1 1 1]);
        thisR.set('material', 'add', thisMaterial);
        materialNames{end+1} = thisMaterialName;
        

        
    end
    
    %% Materials defined by their textures
    
    if ismember(mType{ii},{'all','wood'})
        
        % Wood grain (light, large grain)
        thisMaterialName = 'wood001';
        thisTexture = piTextureCreate(thisMaterialName,...
            'format', 'spectrum',...
            'type', 'imagemap',...
            'filename', 'woodgrain001.png');
        thisR.set('texture', 'add', thisTexture);
        thisMaterial = piMaterialCreate(thisMaterialName,'type','diffuse','reflectance val',thisMaterialName);
        thisR.set('material', 'add', thisMaterial);
        materialNames{end+1} = thisMaterialName;
        
        % New method for inserting.  The materials are made in
        % piMaterialPresets.  We get the newMat returned here.  It has both
        % the textures and material slotted in.  We add the textures and
        % material to the recipe.
        %
        % Wood grain (light, large grain)
        % The newMat can have multiple textures.
        newMat = piMaterialPresets('wood-light-large-grain','wood-light-large-gran');
        if iscell(newMat.texture)
            for tt=1:numel(newMat.texture)
                thisR.set('texture','add',newMat.texture{tt});
            end
        else
            thisR.set('texture', 'add', newMat.texture);
        end
        thisR.set('material', 'add', newMat.material);
        
        %         thisMaterialName = 'wood002';
        %         thisTexture = piTextureCreate(thisMaterialName,...
        %             'format', 'spectrum',...
        %             'type', 'imagemap',...
        %             'filename', 'woodgrain002.exr');
        %         thisR.set('texture', 'add', thisTexture);
        %         thisMaterial = piMaterialCreate(thisMaterialName,'type','diffuse','reflectance val',thisMaterialName);
        %         thisR.set('material', 'add', thisMaterial);
        %         materialNames{end+1} = thisMaterialName;
        
        % Mahogany
        thisMaterialName = 'mahogany_dark';
        thisTexture = piTextureCreate(thisMaterialName,...
            'format', 'spectrum',...
            'type', 'imagemap',...
            'filename', 'mahoganyDark.exr');
        thisR.set('texture', 'add', thisTexture);
        thisMaterial = piMaterialCreate(thisMaterialName,'type','diffuse','reflectance val',thisMaterialName);
        thisR.set('material', 'add', thisMaterial);
        materialNames{end+1} = thisMaterialName; %#ok<*AGROW>
        
    end
    
    if ismember(mType{ii},{'all','brick'})
        
        % Brick wall
        thisMaterialName = 'brickwall001';
        thisTexture = piTextureCreate(thisMaterialName,...
            'format', 'spectrum',...
            'type', 'imagemap',...
            'filename', 'brickwall001.png');
        thisR.set('texture', 'add', thisTexture);
        thisMaterial = piMaterialCreate(thisMaterialName,'type','diffuse','reflectance val',thisMaterialName);
        thisR.set('material', 'add', thisMaterial);
        materialNames{end+1} = thisMaterialName;
        
        % Brick wall
        thisMaterialName = 'brickwall002';
        thisTexture = piTextureCreate(thisMaterialName,...
            'format', 'spectrum',...
            'type', 'imagemap',...
            'filename', 'brickwall002.png');
        thisR.set('texture', 'add', thisTexture);
        thisMaterial = piMaterialCreate(thisMaterialName,'type','diffuse','reflectance val',thisMaterialName);
        thisR.set('material', 'add', thisMaterial);
        materialNames{end+1} = thisMaterialName;
        
        % Brick wall
        thisMaterialName = 'brickwall003';
        thisTexture = piTextureCreate(thisMaterialName,...
            'format', 'spectrum',...
            'type', 'imagemap',...
            'filename', 'brickwall003.png');
        thisR.set('texture', 'add', thisTexture);
        thisMaterial = piMaterialCreate(thisMaterialName,'type','diffuse','reflectance val',thisMaterialName);
        thisR.set('material', 'add', thisMaterial);
        materialNames{end+1} = thisMaterialName;
    end

    if ismember(mType{ii},{'all','marble'})

        % Marble
        thisMaterialName = 'marbleBeige';
        thisTexture = piTextureCreate(thisMaterialName,...
            'format', 'spectrum',...
            'type', 'imagemap',...
            'filename', 'marbleBeige.exr');
        thisR.set('texture', 'add', thisTexture);
        thisMaterial = piMaterialCreate(thisMaterialName,'type','coateddiffuse','reflectance val',thisMaterialName);
        thisR.set('material', 'add', thisMaterial);
        materialNames{end+1} = thisMaterialName;

        % Deal with this polligon case (also mentioned in piMaterialPresets).
        %    case 'tiles-marble-sagegreen-brick'
        %    newMat = polligon_materialCreate(materialName,...
        %    'TilesMarbleSageGreenBrickBondHoned001_COL_2K.jpg','coateddiffuse');
    end

    % Test patterns used for specific metrics
    if ismember(mType{ii},{'all','testpattern'})
        
        % Checkerboard
        thisMaterialName = 'checkerboard';
        thisTexture = piTextureCreate(thisMaterialName,...
            'format', 'spectrum',...
            'type', 'imagemap',...
            'filename', 'checkerboard.exr');
        thisR.set('texture', 'add', thisTexture);
        thisMaterial = piMaterialCreate(thisMaterialName,'type','diffuse','reflectance val',thisMaterialName);
        thisR.set('material', 'add', thisMaterial);
        materialNames{end+1} = thisMaterialName;
        
        % Rings and Rays (Siemens star)
        thisMaterialName = 'ringsrays';
        thisTexture = piTextureCreate(thisMaterialName,...
            'format', 'spectrum',...
            'type', 'imagemap',...
            'filename', 'ringsrays.png');
        thisR.set('texture', 'add', thisTexture);
        thisMaterial = piMaterialCreate(thisMaterialName,'type','diffuse','reflectance val',thisMaterialName);
        thisR.set('material', 'add', thisMaterial);
        materialNames{end+1} = thisMaterialName;
        
        % Macbeth chart
        thisMaterialName = 'macbethchart';
        thisTexture = piTextureCreate(thisMaterialName,...
            'format', 'spectrum',...
            'type', 'imagemap',...
            'filename', 'macbeth.png');
        thisR.set('texture', 'add', thisTexture);
        thisMaterial = piMaterialCreate(thisMaterialName,'type','diffuse','reflectance val',thisMaterialName);
        thisR.set('material', 'add', thisMaterial);
        materialNames{end+1} = thisMaterialName;
        
        % Slanted edge
        thisMaterialName = 'slantededge';
        thisTexture = piTextureCreate(thisMaterialName,...
            'format', 'spectrum',...
            'type', 'imagemap',...
            'filename', 'slantedbar.png');
        thisR.set('texture', 'add', thisTexture);
        thisMaterial = piMaterialCreate(thisMaterialName,'type','diffuse','reflectance val',thisMaterialName);
        thisR.set('material', 'add', thisMaterial);
        materialNames{end+1} = thisMaterialName;

        % Colored dots
        thisMaterialName = 'dots';
        thisTexture = piTextureCreate(thisMaterialName,...
            'format', 'spectrum',...
            'type', 'dots',...
            'uscale', 8,...
            'vscale', 8, ...
            'inside', [.1 .5 .9], ...
            'outside', [.9 .5 .1]);
        thisR.set('texture', 'add', thisTexture);
        thisMaterial = piMaterialCreate(thisMaterialName,'type','diffuse','reflectance val',thisMaterialName);
        thisR.set('material', 'add', thisMaterial);
        materialNames{end+1} = thisMaterialName;
    end
    

end

%% This will become a parameter some day.

if p.Results.verbose
    thisR.get('print materials');
end

end