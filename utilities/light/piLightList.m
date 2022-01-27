function nLights = piLightList(thisR)
% Print list of lights in the recipe
%
% Synopsis
%   nLights = piLightList(thisR)
%
% See also
%   piMaterialPrint

nLights = thisR.get('n lights');
if nLights == 0
    disp('---------------------')
    disp('No lights listed in this recipe');
    disp('---------------------')
else
    disp('---------------------')
    disp('*****Light Type******')
    lightNames = thisR.get('light', 'names');
    for ii = 1:numel(lightNames)
        fprintf('%d: name: %s     type: %s\n', ii,...
            lightNames{ii}, thisR.get('light', lightNames{ii}, 'type'));
    end
    disp('*********************')
    disp('---------------------')
end

end
