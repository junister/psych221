function thisR = piMaterialsInsert(thisR,varargin)
% Insert default materials (V4) into a recipe
%
% Synopsis
%  thisR = piMaterialsInsert(thisR,varargin)
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
%      To see the current list of materials in a recipe use
%
%           thisR.get('print  materials')
%
% Description
%   We add materials to a recipe.  It gives a list of materials that
%   we are likely to want.  You can select a group of materials using
%   a cell array as the first argument.
%
%     thisR = piMaterialsInsert(thisR,{'glass','mirror'});
%
% See also
%    piMaterialPresets, t_piIntro_materialInsert

% TODO
%  Do not over-write when the material exists already.

% Examples:
%{
 thisR = piRecipeDefault('scene name','chessset');
 piMaterialsInsert(thisR,'names',{'wood-medium-knots'}); 
 thisR.get('print materials');
%}
%{
 thisR = piRecipeDefault('scene name','chessset');
 piMaterialsInsert(thisR,'group',{'testpatterns'}); 
 thisR.get('print materials');
%}

%% Parse
varargin = ieParamFormat(varargin);

p = inputParser;
p.addRequired('thisR',@(x)(isa(x,'recipe')));
p.addParameter('group','',@(x)(iscell(x) || ischar(x)));
p.addParameter('names','',@(x)(iscell(x) || ischar(x)));
p.addParameter('verbose',false,@islogical);

p.parse(thisR,varargin{:});

% Decides which class of materials to insert
mType = p.Results.group;
mNames = p.Results.names;

% Make a char into a single entry cell
if ischar(mType), mType = {mType}; end
if ischar(mNames), mNames = {mNames}; end

%% We should have either material type (mType) or material names (mNames)

% Individually named materials
if ~isempty(mNames{1})
    for ii=1:numel(mNames)
        newMat = piMaterialPresets(mNames{ii},mNames{ii});
        thisR.set('material','add',newMat);
    end
end

% Material types, not individual materials.
if ~isempty(mType{1})
    for ii=1:numel(mType)

        if ismember(mType{ii},{'all','glass'})
            glass = {'glass','red-glass','glass-bk7','glass-baf10','glass-fk51a','glass-fk51a','glass-lasf9','glass-f5','glass-f10','glass-f11'}';
            for gg = 1:numel(glass)
                newMat = piMaterialPresets(glass{gg},glass{gg});
                thisR.set('material', 'add', newMat);
            end
        end

        if ismember(mType{ii},{'all','mirror'})
            mirror = {'mirror','metal-ag'};
            for mm = 1:numel(mirror)
                newMat = piMaterialPresets(mirror{mm},mirror{mm});
                thisR.set('material', 'add', newMat);
            end
        end

        if ismember(mType{ii},{'all','diffuse'})
            diffuse = {'diffuse-gray','diffuse-red','diffuse-white'};
            for dd = 1:numel(diffuse)
                newMat = piMaterialPresets(diffuse{dd},diffuse{dd});
                thisR.set('material', 'add', newMat);
            end
        end

        if ismember(mType{ii},{'all','glossy'})
            glossy = {'glossy-black','glossy-gray','glossy-red','glossy-white'};
            for gl = 1:numel(glossy)
                newMat = piMaterialPresets(diffuse{gl},diffuse{gl});
                thisR.set('material', 'add', newMat);
            end
        end

        if ismember(mType{ii},{'all','wood'})
            woods = {'wood-floor-merbau','wood-medium-knots','wood-light-large-grain','wood-mahogany'};
            for ww = 1:numel(woods)
                newMat = piMaterialPresets(woods{ww},woods{ww});
                thisR.set('material', 'add', newMat);
            end
        end

        if ismember(mType{ii},{'all','brick'})
            bricks = {'brick001','brickwall002','brickwall003'};
            for bb = 1:numel(bricks)
                newMat = piMaterialPresets(bricks{bb},bricks{bb});
                thisR.set('material', 'add', newMat);
            end
        end

        if ismember(mType{ii},{'all','marble'})
            marble = {'marble-beige','tiles-marble-sagegreen-brick'};
            for mm = 1:numel(marble)
                newMat = piMaterialPresets(marble{mm},marble{mm});
                thisR.set('material', 'add', newMat);
            end
        end

        if ismember(mType{ii},'testpattern')
            testpattern = {'checkerboard','ringsrays','macbethchart','slantededge','dots'};
            for tp = 1:numel(testpattern)
                newMat = piMaterialPresets(testpattern{tp},testpattern{tp});
                thisR.set('material', 'add', newMat);
            end
        end

    end
end

% Show a summary of the materials in this recipe, when set.
if p.Results.verbose
    thisR.get('print materials');
end

end