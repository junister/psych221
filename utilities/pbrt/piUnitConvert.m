function thisR = piUnitConvert(thisR, factor)
% scale scene unit by an input factor
%
%%
% scale camera position
thisR.lookAt.from = thisR.lookAt.from/factor;
thisR.lookAt.to = thisR.lookAt.to/factor;

% scale objects
for ii = 2:numel(thisR.assets.Node)
    thisNode = thisR.assets.Node{ii};
    if strcmp(thisNode.type, 'branch')
        % fix scale and translation
        thisNode.scale = thisNode.scale/factor;
        thisNode.translation = thisNode.translation/factor;
        
        thisR.assets   = thisR.assets.set(ii, thisNode);
    end
end
end