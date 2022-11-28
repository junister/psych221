function nLights = piLightPrint(thisR)
% Print a table of lights in the recipe
%
% Synopsis
%   nLights = piLightPrint(thisR)
%
% To get information about light names or their IDs use
%
%   thisR.get('lights')
%   thisR.get('lights','names')
%   thisR.get('lights','names id')
%   thisR.get('light simple names')
%   val = thisR.get('light positions')
%
% For a single light, use
%
%   thisR.get('light',id,'name')
%   thisR.get('light',id,'name simple')
%   

% See also
%

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
            isequal(thisLight.type,'infinite') %
        position(ii,:) = Inf;
    else
        % point, spot and area have a position
        position(ii,:) = thisR.get('light',thisLight.name,'world position');
    end

    % We have mapnames in some cases (e.g., default chess set light)
    if ~isfield(thisLight,'mapname') || isempty(thisLight.mapname.value)
        spdT{ii} = num2str(thisLight.spd.value);
    else
        spdT{ii} = thisLight.mapname.value;
    end
end

%% Display the table

for ii=1:numel(names), positionT{ii} = num2str(position(ii,:)); end

T = table(categorical(names), categorical(types),positionT,spdT,'VariableNames',{'name','type','position','spd/rgb'}, 'RowNames',rows);

disp(T);
fprintf('-------------------------------\n');

end
