function [obj,results] = piWRS(thisR,varargin)
% Write, render, show radiance image
%
% Write, Render, Show a scene specified by a recipe
%
% Synopsis
%   [isetObj, results] = piWRS(thisR)
% 
% See also
%   piRender, sceneWindow, oiWindow

%%
varargin = ieParamFormat(varargin);

p = inputParser;
p.addRequired('thisR',@(x)(isa(x,'recipe')));
p.addParameter('dockerimagename','camerasimulation/pbrt-v4-cpu',@ischar);
p.addParameter('rendertype','radiance',@ischar);
p.addOptional('ourdocker','');

p.parse(thisR,varargin{:});
ourDocker = p.Results.ourdocker;
renderType = p.Results.rendertype;

%%
piWrite(thisR);

[obj,results] = piRender(thisR,...
    'ourdocker',ourDocker);

switch obj.type
    case 'scene'
        sceneWindow(obj);
    case 'opticalimage'
        oiWindow(obj);
end

end