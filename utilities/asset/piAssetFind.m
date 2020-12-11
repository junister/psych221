function id = piAssetFind(thisR, param, val)
%%

% See also:
%   piAssetGet, piAssetSet;

% Example
%{
t = tree('root');
[t, nID] = t.addnode(1, node);
[t, oID] = t.addnode(nID, object);
[t, lID] = t.addnode(nID, light);
disp(t.tostring)

thisID = piAssetFind(t, 'name', 'object');
nodeObject = t.get(thisID);
%}
%%
thisTree = thisR.assets;
%%
nodeList = [0]; % 0 is always the index for root node

curIdx = 1; %
 
while curIdx <= numel(nodeList)
    IDs = thisTree.getchildren(nodeList(curIdx));
    for ii = 1:numel(IDs)
        if isequal(val, piAssetGet(thisR, uint16(IDs(ii)), param))
            id = IDs(ii);
            return;
        end
        nodeList = [nodeList IDs(ii)];
    end
    
    curIdx = curIdx + 1;
end

id = [];

end