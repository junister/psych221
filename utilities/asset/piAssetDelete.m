function thisR = piAssetDelete(thisR, assetInfo, varargin)
% Delete a single node of the asset tree
%
% Synopsis:
%   thisR = piAssetDelete(thisR, assetInfo)
%
% Brief description:
%   assetInfo:  The node name or the id
%
% Inputs:
%   thisR     - recipe.
%   assetInfo - asset node name or id.
%
% Optional key/val
%   TODO:  Remove all the nodes in the tree below this node.
%
% Returns:
%   thisR     - modified recipe.

% Examples:
%{
thisR = piRecipeDefault('scene name', 'Simple scene');
disp(thisR.assets.tostring)
thisR = thisR.set('asset', '004ID_Sky1', 'delete');
disp(thisR.assets.tostring)
%}
%% Parse
p = inputParser;
p.addRequired('thisR', @(x)isequal(class(x),'recipe'));
p.addRequired('assetInfo', @(x)(ischar(x) || isscalar(x)));
p.parse(thisR, assetInfo, varargin{:});

thisR        = p.Results.thisR;
assetInfo    = p.Results.assetInfo;
%%
% If assetInfo is a node name, find the id
if ischar(assetInfo)
    assetName = assetInfo;
    assetInfo = piAssetFind(thisR.assets, 'name', assetInfo);
    if isempty(assetInfo)
        warning('Could not find an asset with name %s:', assetName);
        thisR.show('objects');
        return;
    end
end
%% Remove node
if ~isempty(thisR.assets.get(assetInfo))
    while true
        % First get the parrent of current node
        parentID = thisR.assets.Parent(assetInfo);
        
        thisR.assets = thisR.assets.removenode(assetInfo);
        
        if isempty(thisR.assets.getchildren(parentID))
            assetInfo = parentID;
        else
            break;
        end
    end
else
    warning('Node: %d is not in the tree, returning.', assetInfo);
end

end
