function [obj,results] = piWRS(thisR,varargin)
% Write, render, show radiance image
%
% Write, Render, Show a scene specified by a recipe (thisR).
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
%   ... others).  If it is a char, then we convert it to a cell.
%   'show'  -  Call a window to show the object (default) and insert it in
%              the vcSESSION database
%   'docker image name' - Specify the docker image
%
% Returns
%   obj     - a scene or oi
%   results - The piRender text outputs

%
% See also
%   piRender, sceneWindow, oiWindow

%%
varargin = ieParamFormat(varargin);

p = inputParser;
p.addRequired('thisR',@(x)(isa(x,'recipe')));
% p.addParameter('dockerimagename','camerasimulation/pbrt-v4-cpu:latest',@ischar);
p.addParameter('rendertype','radiance',@(x)(ischar(x) || iscell(x)));
p.addParameter('ourdocker','');
p.addParameter('name','',@ischar);
p.addParameter('show',true,@islogical);

p.parse(thisR,varargin{:});
ourDocker  = p.Results.ourdocker;

renderType = p.Results.rendertype;
if ischar(renderType)
    renderType = {renderType};
end

name = p.Results.name;
show = p.Results.show;

%% In version 4 we set the render type this way

thisR.set('render type',renderType);

piWrite(thisR);

[obj,results] = piRender(thisR, 'ourdocker', ourDocker);

switch obj.type
    case 'scene'
        if ~isempty(name), obj = sceneSet(obj,'name',name); end
        if show, sceneWindow(obj); end
    case 'opticalimage'
        if ~isempty(name), obj = oiSet(obj,'name',name); end
        if show, oiWindow(obj); end
end

end
