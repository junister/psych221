function thisR = piUnitConvert(thisR)
    % scale camera position
    thisR.lookAt.from = thisR.lookAt.from/100;
    thisR.lookAt.to = thisR.lookAt.to/100;
    
    % scale objects
    for ii = 2:numel(thisR.assets.Node)
        thisNode = thisR.assets.Node{ii};
        if strcmp(thisNode.type, 'branch')
            % fix scale and translation
            thisNode.scale = thisNode.scale/100;
            thisNode.translation = thisNode.translation/100;
            
            thisR.assets   = thisR.assets.set(ii, thisNode);
        end
    end
end