function [thisR, instanceBranchName] = piObjectInstanceCreate(thisR, assetname, varargin)
%% Create an object instance (copy)
%
% Synopsis:
%   [thisR, instanceBranchName]  = piObjectInstanceCreate(thisR, assetname, varargin)
%
% Brief description:
%   If a complex object is used repeatedly in a scene, object instancing
%   may be desirable; this lets the system store a single instance of the
%   object in memory and just record multiple transformations to place it
%   in the scene. It is essentially a lightweight method of copying.
%
% Inputs:
%   thisR     - scene recipe
%   assetName - The objecct we want to copy
%
% Optional key/val
%   position  - 1x3 position (World position)?
%   rotation  - 3x4 rotation
%   scale     - 1x3 scale
%   motion    - motion struct which contains animated position and rotation
%
%   ** deprecated material  - material name for (object type) asset
%   ** deprecated nodetype  - type of asset node
%
% Outputs:
%   thisR     - scene recipe
%   instanceBranchName
%
% Zhenyi, 2021

% TODO (BW):  Make work with other regular scenes.  It appears to work with
% ISETAuto case, but there are problems with SimpleScene.  To fix with
% Zhenyi or Zheng.

%% Read the parameters
p = inputParser;
p.addRequired('thisR', @(x)isequal(class(x),'recipe'));
p.addParameter('position',[0, 0, 0]);
p.addParameter('rotation',piRotationMatrix);
p.addParameter('scale',[1,1,1]);
p.addParameter('motion',[],@(x)isstruct);

p.parse(thisR, varargin{:});

thisR    = p.Results.thisR;
position = p.Results.position;
rotation = p.Results.rotation;
scale    = p.Results.scale;
motion   = p.Results.motion;

%% Find the asset idx and properties
[idx,asset] = piAssetFind(thisR, 'name', assetname);

% ZL only addressed the first entry of the cell.  So, this seems OK.
if iscell(asset)
    if numel(asset) > 1
        warning('Multiple assets returned. I think there should just be 1.');
    end
    asset = asset{1}; 
end

if ~strcmp(asset.type, 'branch')
    warning('Only branch name is supported.');
    return;
end

%% We seem to have a good index.
OBJsubtree = thisR.get('asset', idx, 'subtree','false');

OBJsubtree_branch = OBJsubtree.get(1);
if ~isfield(OBJsubtree_branch, 'instanceCount')
    OBJsubtree_branch.instanceCount = 1;
    indexCount = 1;
else
    if OBJsubtree_branch.instanceCount(end)==numel(OBJsubtree_branch.instanceCount)
        OBJsubtree_branch.instanceCount = [OBJsubtree_branch.instanceCount,...
            OBJsubtree_branch.instanceCount(end)+1];
        indexCount = numel(OBJsubtree_branch.instanceCount);
    else
        indexCount = 1;
        while ~isempty(find(OBJsubtree_branch.instanceCount==indexCount,1))
            indexCount = indexCount+1;
        end
        OBJsubtree_branch.instanceCount = sort([OBJsubtree_branch.instanceCount,indexCount]);
    end
end

% add instance to parent object
thisR.assets = thisR.assets.set(idx, OBJsubtree_branch);

InstanceSuffix = sprintf('_I_%d',indexCount);
if ~isempty(position)
    OBJsubtree_branch.translation{1} = position(:);
end
if ~isempty(rotation)
    OBJsubtree_branch.rotation{1}    = rotation;
end
if ~isempty(scale)
    OBJsubtree_branch.scale{1}    = scale;
end
if ~isempty(motion)
    OBJsubtree_branch.motion.translation = motion.translation;
    OBJsubtree_branch.motion.rotation = motion.rotation;
    OBJsubtree_branch.motion.scale = motion.scale;
end
OBJsubtreeNew = tree();

% for ii = 1:numel(OBJsubtree.Node)
%     if ~strcmp(OBJsubtree.Node{1}.type,'branch') || ...
%             OBJsubtree.Node{1}.isObjectInstance==0
%         continue;
%     end

% thisNode      = OBJsubtree.Node{1};
% thisNode.name = strcat(OBJsubtree.Node{1}.name, InstanceSuffix);
% %     if strcmp(OBJsubtree.Node{ii}.type,'object')
% %         thisNode.type = 'instance';
% %         thisNode.referenceObject = OBJsubtree.Node{ii}.name;
% %     end
% OBJsubtreeNew = OBJsubtreeNew.set(1, thisNode);
% end

% There is now a problem in how we are setting the name of the reference
% object.  See t_piSceneInstances (BW).
OBJsubtree_branch.referenceObject = OBJsubtree_branch.name(1:end-2); % remove '_B'
OBJsubtree_branch.isObjectInstance = 0;
OBJsubtree_branch.name = strcat(OBJsubtree_branch.name, InstanceSuffix);

% replace branch
OBJsubtreeNew = OBJsubtreeNew.set(1, OBJsubtree_branch);

%% Apply transformation to lights

% Check wheather there are extra nodes attached.
if isfield(OBJsubtree_branch,'extraNode') && ~isempty(OBJsubtree_branch.extraNode)
    extraNode = OBJsubtree_branch.extraNode;

    extraNodeNew = extraNode;
    for nLightsNode = 1:numel(extraNode.Node)
        thisLightNode = extraNode.Node{nLightsNode};
        if strcmp(thisLightNode.type,'light')
            if ~strcmp(thisLightNode.lght{1}.type,'area')
                % only area light need to modify
                continue;
            end
            ParentId = extraNode.Parent(nLightsNode);
            ParentNode = extraNode.Node{ParentId};
            ParentNode.translation{end+1} = OBJsubtree_branch.translation{1};
            ParentNode.transorder(end+1) = 'T';
            ParentNode.rotation{end+1} = OBJsubtree_branch.rotation{1};
            ParentNode.transorder(end+1) = 'R';
            ParentNode.scale{end+1} = OBJsubtree_branch.scale{1};
            ParentNode.transorder(end+1) = 'S';
            extraNodeNew = extraNodeNew.set(ParentId, ParentNode);
        elseif isfield(thisLightNode,'referenceObject')
            thisLightNode = rmfield(thisLightNode,'referenceObject');
            extraNodeNew = extraNodeNew.set(nLightsNode, thisLightNode);
        end
    end

    % graft lightsNode
    OBJsubtreeNew = OBJsubtreeNew.graft(1, extraNodeNew);
end
% graft object tree to scene tree
% thisR.assets = thisR.assets.graft(1, OBJsubtree);
try
    id = thisR.get('node', 'root', 'id');
    %     rootSTID = thisR.assets.nnodes + 1;
    thisR.assets = thisR.assets.graft(id, OBJsubtreeNew);
    %     thisR.set('asset', 1, 'graft', OBJsubtreeNew);
catch
    disp('ERROR');
end
instanceBranchName = OBJsubtree_branch.name;

end