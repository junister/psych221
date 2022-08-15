function lght = piLightCreate(lightName, varargin)
%% Create a light source struct for a recipe
%
% Synopsis:
%   lght = piLightCreate(lightName,varargin)
%
% Inputs:
%   lightName   - name of the light
%
% Optional key/val pairs
%   type   - light type. Default is point light.  The light specific
%    properties depend on the light type. To see the light types use
%
%      lightTypes = piLightCreate('list available types');
%
%    Properties for each light type can be found
%
%        piLightProperties(lightTypes{3})
%
%    Look here for the PBRT website information about lights.
%
% Description:
%   In addition to creating a light struct, various light properties can be
%   specified in key/val pairs.
%
%   The 'spd spectrum' property reads a file from ISETCam/data/lights
%   that defines a light spectrum.  For example, Tungsten or D50.
%
% Returns
%   lght   - light struct
%
%  lgt = piLightCreate('blueSpot', 'type','spot','spd',[9000]);
%
% See also
%   piLightSet, piLightGet, piLightProperties
%

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

%% Check if the person just wants the light types

validLights = {'distant','goniometric','infinite','point','area','projection','spot'};

if isequal(ieParamFormat(lightName),'listavailabletypes')
    lght = validLights;
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

% PBRT allows wavelength by wavelength adjustment - we will enable that
% someday.
lght.specscale.type = 'float';
lght.specscale.value = 1;

lght.spd.type = 'rgb';
lght.spd.value = [1 1 1];

% I think we always want the name to end with _L.  So if it does not, we
% append it
if ~isequal(lght.name((end-1):end),'_L')
    % warning('Appending _L to light name')
    lght.name = [lght.name,'_L'];
end

switch ieParamFormat(lght.type)
    case 'distant'
        lght.cameracoordinate = true;

        lght.from.type = 'point3';
        lght.from.value = [0 0 0];

        lght.to.type = 'point3';
        lght.to.value = [0 0 1];

        %{
        % Potentially has rotation, transformation or concatransformaiton
        lght.rotation.type = 'rotation';
        lght.rotation.value = {};

        lght.translation.type = 'translation';
        lght.translation.value = {};

        lght.ctform.type = 'ctform';
        lght.ctform.value = {};

        lght.scale.type = 'scale';
        lght.scale.value = {};
        %}

    case 'goniometric'
        lght.mapname.type = 'string';
        lght.mapname.value = '';

    case 'infinite'
        % Is this the same as environmental?
        lght.nsamples.type = 'integer';
        lght.nsamples.value = [];

        % V4 for infinite lights
        lght.mapname.type = 'string';
        lght.mapname.value = '';
        
        %{
        % Potentially has rotation, transformation or concatransformaiton
        lght.rotation.type = 'rotation';
        lght.rotation.value = {};

        lght.translation.type = 'translation';
        lght.translation.value = {};

        lght.ctform.type = 'ctform';
        lght.ctform.value = [];

        lght.scale.type = 'scale';
        lght.scale.value = {};
        %}
    case 'point'
        % Initializes a light at the origin.
        % Point sources emit in all directions, and have no 'to'.
        %
        lght.cameracoordinate = true;

        lght.from.type = 'point';
        lght.from.value = [0 0 0];
        
        %{
        % Potentially has rotation, transformation or concatransformaiton
        lght.rotation.type = 'rotation';
        lght.rotation.value = {};

        lght.translation.type = 'translation';
        lght.translation.value = {};

        lght.ctform.type = 'ctform';
        lght.ctform.value = {};

        lght.scale.type = 'scale';
        lght.scale.value = {};
        %}

    case 'projection'
        lght.fov.type = 'float';
        lght.fov.value = [];

        lght.mapname.type = 'string';
        lght.mapname.value = '';

    case {'spot', 'spotlight'}
        lght.cameracoordinate = true;

        lght.from.type = 'point3';
        lght.from.value = [0 0 0];

        lght.to.type = 'point3';
        lght.to.value = [0 0 1];

        lght.coneangle.type = 'float';
        lght.coneangle.value = [];

        lght.conedeltaangle.type = 'float';
        lght.conedeltaangle.value = [];
        
        %{
        % Potentially has rotation, transformation or concatransformaiton
        lght.rotation.type = 'rotation';
        lght.rotation.value = {};

        lght.translation.type = 'translation';
        lght.translation.value = {};

        lght.ctform.type = 'ctform';
        lght.ctform.value = {};

        lght.scale.type = 'scale';
        lght.scale.value = {};
        %}

    case {'area', 'arealight'}
        % These are the default parameters for an area light, that are
        % based on the Blender export in arealight.pbrt.

        lght.type = 'area';
        lght.name = 'default-area';

        lght.twosided.type = 'bool';
        lght.twosided.value = [];

        lght.nsamples.type = 'integer';
        lght.nsamples.value = [];

        lght.spread.type = 'float';
        lght.spread.value = [];

        lght.specscale.type = 'float';
        lght.specscale.value = 100;

        lght.spd.type = 'rgb';
        lght.spd.value = [1 1 1];

        % We need a piShapeCreate() method
        rectShape = struct('meshshape','trianglemesh', ...
        'filename','', ...
        'integerindices', [0 1 2 3 4 5], ...
        'point3p',[-1 -1 0 -1 1 0 1 1 0 -1 -1 0 1 1 0 1 -1 0], ...
        'point2uv',[0 0 0 1 1 1 0 0 1 1 1 0], ...
        'normaln',[0 0 -1 0 0 -1 0 0 -1 0 0 -1 0 0 -1 0 0 -1], ...
        'height', '',...
        'radius','',...
        'zmin','',...
        'zmax','',...
        'p1','',...
        'p2','',...
        'phimax','',...
        'alpha','');
        lght.shape{1} = rectShape;

        lght.spread.type = 'float';
        lght.spread.value = 30;

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
