function piTexturePrint(thisR)
% List texture names in recipe.
% This is just a temporary version.
% In the future we want to parse texture as material data.
%
% Inputs:
%   thisR   - recipe
%
% Outputs:
%   None
%
%
%
%%

textureNames = thisR.get('texture', 'names');
fprintf('\n--- Texture names ---\n');
if isempty(textureNames)
    disp('No textures')
    return;
else
    nTextures = numel(textureNames);
    rows = cell(nTextures,1);
    names = rows; format = rows; types = rows;
    for ii =1:numel(textureNames)
        rows{ii, :}  = num2str(ii);
        names{ii,:}  = textureNames{ii};
        format{ii,:} = thisR.textures.list(textureNames{ii}).format;
        types{ii,:}  = thisR.textures.list(textureNames{ii}).type;
    end
    T = table(categorical(names), categorical(format),categorical(types),'VariableNames',{'names','format', 'types'}, 'RowNames',rows);
    disp(T);
end
fprintf('---------------------\n');

end
