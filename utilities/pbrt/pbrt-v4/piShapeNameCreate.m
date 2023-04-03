function name = piShapeNameCreate(shape,isNode,baseName)
% Create a name for an asset that is an object with a shape
%
% Synopsis
%   name = piShapeNameCreate(shape,[isNode],[baseName])
%
% Input
%   shape  - Shape struct built by piRead and parseGeometryText
%   isNode - This is shape node name.  If not, then this is a filename.
%             Default (true)
%   baseName - Scene base name (thisR.get('input basename'));
%
% Output
%    name - The node or file name
%
% Brief description
%   (1) Use file name if it is already part of the shape struct
%   (2) Hash on the point3p slot in the shape struct
%
% If this is a node name, we append an _O. If it is a file, we do not
% append an _O. 
%
% See also
%   parseGeometryText, piGeometryWrite

if ieNotDefined('isNode'),isNode = true; end
if ~isNode && ~exist('baseName','var')
    error('Scene base name required for a shape file name.');
end

if ~isempty(shape.filename)
    [~, n, ~] = fileparts(shape.filename);

    % If there was a '_mat0' added to the ply file name
    % remove it.
    if contains(n,'_mat0'), n = erase(n,'_mat0'); end

    % Add the _O because it is an object.
    if isNode, name = sprintf('%s_O', n);
    else,  name = n;
    end
else
    str = ieHash(shape.point3p);
    name = sprintf('%s-%s',baseName,str(1:8));
    if isNode, name = sprintf('%s_O', name); end
end

end
