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
    fprintf('\n ---------Lights--------- \n\n')
    for ii = 1:numel(thisR.lights)
        fprintf('%d: name: %s     type: %s\n', ii,...
            thisR.lights{ii}.name,thisR.lights{ii}.type);
    end    
    fprintf('\n ------------------------ \n\n')
end

end
