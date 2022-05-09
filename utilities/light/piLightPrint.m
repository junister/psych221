function nLights = piLightPrint(thisR)
% Print list of lights in the recipe
%
% Synopsis
%   nLights = piLightPrint(thisR)
%
% See also
%   piMaterialPrint

nLights = thisR.get('n lights');

if nLights == 0
    disp('---------------------')
    disp('No lights in this recipe');
    disp('---------------------')
    return;
end

%% Initialize
lightNames = thisR.get('light', 'names');
rows = cell(nLights,1);
names = rows;
types = rows;
spdT = rows;

positionT = rows;
position = zeros(nLights,3);

%% Get data
fprintf('\nLights\n');
fprintf('-------------------------------\n');
for ii =1:numel(lightNames)
    thisLight = thisR.get('light', lightNames{ii}, 'lght');
    rows{ii, :} = num2str(ii);
    names{ii,:} = lightNames{ii};
    types{ii,:} = thisLight.type;
    if isequal(thisLight.type,'distant') || ...
            isequal(thisLight.type,'infinite') || ...
            isequal(thisLight.type,'area')
        position(ii,:) = Inf;
    else
        position(ii,:) = thisR.get('light',ii,'position');
    end

    % not sure we even have mapnames anymore, but in case...
    if ~isfield(thisLight,'mapname') || isempty(thisLight.mapname)
        spdT{ii} = num2str(thisLight.spd.value);
    else
        spdT{ii} = thisLight.mapname.value;
    end
end

%% Display the table

for ii=1:numel(names), positionT{ii} = num2str(position(ii,:)); end

T = table(categorical(names), categorical(types),positionT,spdT,'VariableNames',{'name','type','position','spd'}, 'RowNames',rows);

disp(T);
fprintf('-------------------------------\n');

end
