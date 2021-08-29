function lght = piLightCreate(lightName, varargin)
%% Create a light source struct for a recipe
%
% 
% Synopsis:
%   lght = piLightCreate(lightName,varargin)
%
% Inputs:
%   lightName   - name of the light.  There are various special cases,
%        however, that are intended to help the programmer.  These are
%
%       'list types'  - Print out a list of the valid light types
%       'help'        - As above
%       'valid'       - Return a cell array of valid types, no print
%       'list env file' - Print out exr files in the data/lights directory
%
% Optional key/val pairs
%   type   - light type. Default is point light.  The light specific
%            properties depend on the light type. See below.
%   
% Special lightName inputs:
%
%      piLightCreate('list types');
%      validLights = piLightCreate('valid');
%      envLights = piLightCreate('list env lights');
%
% Description:
%   In addition to creating a light struct, various light properties can be
%   specified in key/val pairs.
%
%   Settable properties for each light type are summarized here.  
%
%        piLightProperties(lightTypes{3})
%
%   We are still figuring out all the possible properties, so keep checking
%   back here over time!
%
% Returns
%   lght   - light struct, or a cell array with the valid light types.
%
% See also
%   piLightSet, piLightGet, piLightProperties
%
%   PBRT:  https://www.pbrt.org/fileformat-v3#lights

% Examples
%{
  piLightCreate('list available types')
%}
%{
 lgt = piLightCreate('point light 1')
%}
%{
 lgt = piLightCreate('spot light 1', 'type','spot','rgb spd',[1 1 1])
%}
%{
fileName = 'pngExample.png';
lgt = piLightCreate('room light', ...
    'type', 'infinite',...
    'mapname', fileName);
%}

%% Check if the person just wants the light types

validLights = {'distant','goniometric','infinite','point','area','projection','spot'};

% Return on help or 'list available type'
if isequal(ieParamFormat(lightName),'listavailabletypes') ...
        || isequal(ieParamFormat(lightName),'listtypes') ...
        || isequal(ieParamFormat(lightName),'help')
    lght = validLights;
    fprintf('\nLight Types\n----------\n');
    for ii=1:length(validLights)
        fprintf('%d:  %s\n',ii,validLights{ii});
    end
    return;
end

if isequal(ieParamFormat(lightName),'valid')
    % Do not print.
    lght = validLights;
    return;
end

% List the names of the environmental lights
if isequal(ieParamFormat(lightName),'listenvlights')
    lght = dir(fullfile(piRootPath,'data','lights','*.exr'));
    fprintf('\nListing EXR env light files\n----------\n');
    for ii=1:length(lght)
        fprintf('%d:\t%s\n',ii,lght(ii).name);
    end
    return;
end


%% Parse inputs

% We replace spaces in the varargin parameter with an underscore. For
% example, 'rgb I' becomes 'rgb_I'. For an explanation, see the code at the
% end of this function.
for ii=1:2:numel(varargin)
    varargin{ii} = strrep(varargin{ii}, ' ', '_');
end

p = inputParser;
p.addRequired('lightName', @ischar);

p.addParameter('type','point',@(x)(ismember(x,validLights)));
p.KeepUnmatched = true;
p.parse(lightName, varargin{:});

%% Construct light struct
lght.type = p.Results.type;
lght.name = p.Results.lightName;

% PBRT allows wavelength by wavelength adjustment - would enable that
% someday.
lght.specscale.type = 'float';
lght.specscale.value = 1;

lght.spd.type = 'rgb';
lght.spd.value = [1 1 1];
switch ieParamFormat(lght.type)
    case 'distant'        
        lght.cameracoordinate = true;

        lght.from.type = 'point';
        lght.from.value = [];
        
        lght.to.type = 'to';
        lght.to.value = [];
        
        % Potentially has rotationation, transformation or concatransformaiton
        lght.rotation.type = 'rotation';
        lght.rotation.value = {};
        
        lght.translation.type = 'translation';
        lght.translation.value = {};
        
        lght.ctform.type = 'ctform';
        lght.ctform.value = {};
        
        lght.scale.type = 'scale';
        lght.scale.value = {};        
        
    case 'goniometric'        
        lght.mapname.type = 'string';
        lght.mapname.value = '';
        
    case 'infinite'        
        lght.nsamples.type = 'integer';
        lght.nsamples.value = [];
        
        lght.mapname.type = 'string';
        lght.mapname.value = '';
        
        % Potentially has rotation, transformation or concatransformaiton
        lght.rotation.type = 'rotation';
        lght.rotation.value = {};
        
        lght.translation.type = 'translation';
        lght.translation.value = {};
        
        lght.ctform.type = 'ctform';
        lght.ctform.value = [];
        
        lght.scale.type = 'scale';
        lght.scale.value = {};  
    case 'point'                
        lght.cameracoordinate = true;

        lght.from.type = 'point';
        lght.from.value = [];
        
        % Potentially has rotation, transformation or concatransformaiton
        lght.rotation.type = 'rotation';
        lght.rotation.value = {};
        
        lght.translation.type = 'translation';
        lght.translation.value = {};
        
        lght.ctform.type = 'ctform';
        lght.ctform.value = {};
        
        lght.scale.type = 'scale';
        lght.scale.value = {};        
        
    case 'projection'        
        lght.fov.type = 'float';
        lght.fov.value = [];
        
        lght.mapname.type = 'string';
        lght.mapname.value = '';
        
    case {'spot', 'spotlight'}        
        lght.cameracoordinate = true;

        lght.from.type = 'point';
        lght.from.value = [];
        
        lght.to.type = 'to';
        lght.to.value = [];
        
        lght.coneangle.type = 'float';
        lght.coneangle.value = [];
        
        lght.conedeltaangle.type = 'float';
        lght.conedeltaangle.value = [];
        
        % Potentially has rotation, transformation or concatransformaiton
        lght.rotation.type = 'rotation';
        lght.rotation.value = {};
        
        lght.translation.type = 'translation';
        lght.translation.value = {};
        
        lght.ctform.type = 'ctform';
        lght.ctform.value = {};
        
        lght.scale.type = 'scale';
        lght.scale.value = {};
        
    case {'area', 'arealight'}        
        lght.twosided.type = 'bool';
        lght.twosided.value = [];
                
        lght.shape.type = 'shape';
        lght.shape.value = [];
        
        % Potentially has rotationation, transformation or concatransformaiton
        lght.rotation.type = 'rotation';
        lght.rotation.value = {};
        
        lght.translation.type = 'translation';
        lght.translation.value = {};
        
        lght.ctform.type = 'ctform';
        lght.ctform.value = {};
        
        lght.scale.type = 'scale';
        lght.scale.value = {};
        
        lght.ReverseOrientation.type = 'ReverseOrientation';
        lght.ReverseOrientation.value = false;
end


%% Set additional key/val pairs

% We can set some, but not all, of the light properties on creation. We use
% a method that does not require us to individually list and set every
% possible property for every possible light.
%
% This code, however, is not complete.  It works for many cases, but it can
% fail.  Here is why.
%
% PBRT uses strings to represent properties, such as
%
%    'rgb spd', or 'cone angle'
%
% ISET3d initializes the light this way
%
%   piLightCreate(lightName, 'type','spot','rgb spd',[1 1 1])
%   piLightCreate(lightName, 'type','spot','float coneangle',10)
%
% We parse the parameter values, such as 'rgb spd', so that we can
% set the struct entries properly.  We do this by 
% 

for ii=1:2:numel(varargin)
    thisKey = varargin{ii};
    thisVal = varargin{ii + 1};
    
    if isequal(thisKey, 'type')
        % Skip since we've taken care of light type above.
        continue;
    end
    
    % This is the new key value we are stting.  Generally, it is the part
    % before the 'underscore'
    keyTypeName = strsplit(thisKey, '_');
    
    % But if  the first parameter is 'TYPE_NAME', we need the second value.
    % 
    if piLightISParamType(keyTypeName{1})
        keyName = ieParamFormat(keyTypeName{2});
    else
        keyName = ieParamFormat(keyTypeName{1});
    end
    
    % Now we run the lightSet.  We see whether this light structure has a
    % slot that matches the keyName.  
    if isfield(lght, keyName)
        % If the slot exists, we set it and we are good.
        lght = piLightSet(lght, sprintf('%s value', keyName),...
                              thisVal);
    else
        % If the slot does not exist, we tell the user, but do not
        % throw an error.
        warning('Parameter %s does not exist in light %s',...
                    keyName, lght.type)
    end
end

end
