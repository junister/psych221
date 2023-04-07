function name = piLightNameCreate(lght,isNode,baseName)
% Create a name for a light 
%
% Synopsis
%   name = piLightNameCreate(lght,[isNode],[baseName])
%
% Input
%   lght   - A light or arealight built by piRead and parseGeometryText
%   isNode - This is a light node name or a light filename.
%            Default (true, a node)
%   baseName - Scene base name (thisR.get('input basename'));
%
% Output
%    name - The name of the node or file name
%
% Brief description
%   (1) If lght.filename is part of the lght struct, use it.
%   (2) If not, use baseName and ieHash on the final cell entry of the
%       lght. We use the first 8 characters in the hex hash. I think
%       that should be enough (8^16), especially combined with the
%       base scene name. 
%

% I am not sure why, but we sometimes have a _mat0 in the filename.
% We erase that.  Some historian needs to tell me how that gets there
% (BW 4/4/2023).
%
% See also
%   parseGeometryText, piGeometryWrite

if iscell(lght), lght = lght{1}; end
if ieNotDefined('isNode'),isNode = true; end
if ieNotDefined('baseName'), baseName = 'light'; end

if isstruct(lght) 
    if isfield(lght,'name')
        name = lght.name;
    else
        warning('No name for this lght.');
    end
elseif iscell(lght)
    str = ieHash(lght{end});
    name = sprintf('%s-%s',baseName,str(1:8));
end

if isNode && ~isequal(name(end-1:end),'_L')
    name = sprintf('%s_L', name);
end

end
