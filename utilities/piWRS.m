function [obj, results, thisD] = piWRS(thisR,varargin)
% Write, Render, Show a scene specified by a recipe (thisR).
%
% Brief description:
%   We often write, render and show a scene or oi.  This executes that
%   sequence, allowing the user to set a few parameters.  It is possible to
%   control some of the parameters in key/val options.
%
%   If you set the render type in the calling argument, we just adjust the
%   recipe locally.  The recipe will not be changed upon return.
%
% Synopsis
%   [isetObj, results] = piWRS(thisR, varargin)
%
% Inputs
%   thisR - A recipe
%
% Optional key/val pairs
%   'name'  - Set the Scene or OI name
%   'render type' - Cell array of render objectives ('radiance','depth',
%           ... others).  If it is a char, then we convert it to a cell.
%   'show'  -  Call a window to show the object (default) and insert it in
%           the vcSESSION database
%   'our docker' - Specify the docker wrapper we will pass to piRender
%
% Returns
%   obj     - a scene or oi
%   results - The piRender text outputs
%   thisD   - a dockerWrapper with the parameters for this run
%
% Description
%   
%
% See also
%   piRender, sceneWindow, oiWindow

%%
varargin = ieParamFormat(varargin);

p = inputParser;

p.addRequired('thisR',@(x)(isa(x,'recipe')));

% You can over-ride the render type with this argument
p.addParameter('rendertype','',@(x)(ischar(x) || iscell(x)));

p.addParameter('ourdocker','');
p.addParameter('name','',@ischar);
p.addParameter('show',true,@islogical);

p.parse(thisR,varargin{:});
ourDocker  = p.Results.ourdocker;

% Determine whether we over-ride or not
renderType = p.Results.rendertype;
if isempty(renderType),     renderType = thisR.get('render type'); % Use the recipe render type
elseif ischar(renderType),  renderType = {renderType};     % Turn a string to cell
elseif iscell(renderType)        % Good to go  
end

name = p.Results.name;
show = p.Results.show;

%% In version 4 we set the render type this way

% We preserve the render type in the recipe.
oldRenderType = thisR.get('render type');

% But the user may have given us a new render type
thisR.set('render type',renderType);

piWrite(thisR);

[~,username] = system('whoami');

if strncmp(username,'zhenyi',6)
    [obj,results] = piRenderZhenyi(thisR, 'ourdocker', ourDocker);
else
    [obj,results, thisD] = piRender(thisR, 'ourdocker', ourDocker);
end

switch obj.type
    case 'scene'
        if ~isempty(name), obj = sceneSet(obj,'name',name); end
        if show, sceneWindow(obj); end
    case 'opticalimage'
        if ~isempty(name), obj = oiSet(obj,'name',name); end
        if show, oiWindow(obj); end
end

thisR.set('render type',oldRenderType);

end
