function nLights = piLightPrint(thisR)
% Print list of lights in the recipe
%
% Synopsis
%   nLights = piLightPrint(thisR)
%
% See also
%   piMaterialPrint

%%
nLights = thisR.get('n lights');

if nLights == 0
    disp('---------------------')
    disp('No lights in this recipe');
    disp('---------------------')
    return;
end

%% There are lights.  Say something useful

lightNames = thisR.get('light', 'names');
rows = cell(nLights,1);
names = rows; types = rows; pos   = rows; mapname = rows;

fprintf('\nLights\n');
fprintf('____________________\n\n');
for ii =1:numel(lightNames)
    rows{ii, :} = num2str(ii);
    names{ii,:} = lightNames{ii};
    types{ii,:} = thisR.lights{ii}.type;
    
    % Light positions
    if thisR.get('lights',ii,'cameracoordinate')
        thisPos = 'camera';
    else
        thisPos = piLightGet(thisR.lights{ii},'from');
    end
    if isempty(thisPos), pos{ii,:} = 'distant';
    else, pos{ii,:} = thisPos;
    end
    
    % Image map
    thisMap = piLightGet(thisR.lights{ii},'mapname');
    if isempty(thisMap), mapname{ii,:} = 'None';
    else, mapname{ii,:} = thisMap;
    end

end
T = table(categorical(names), categorical(types),categorical(pos),categorical(mapname), 'VariableNames',{'name','type','position','imagemap'}, 'RowNames',rows);
disp(T);

end
