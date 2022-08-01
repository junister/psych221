function val = piAssetSearch(thisR,varargin)
% A method to search through the assets, returning the indices
%
% Brief description
%    Search the asset list and find those meeting a criterion
%    specified in the varargin
%
% Synopsis
%    val = piAssetSearch(thisR,varargin)
%
% Inputs
%   thisR
%  
% Optional key/val
%  object
%  branch
%  light
%  material
%  position
%  
%
% Output
%   val - array of indices into the assets meeting the conditions
%
% Description
%   We often want to find assets that meet a particular condition,
%   such as assets that have a particular material, or whose positions
%   are within a certain distance range.  We might then change the
%   material, set the 'to' at one of these assets, and so forth.
%
%   This method searches through the assets finding the ones that meet
%   a criterion specified by the varargin key/val pairs.
%
% See also
%   piAssetFind

% Examples:
%{
thisR = piRecipeDefault('scene name','chess set');
thisR.set('skymap','sky-room.exr');
idx = piAssetSearch(thisR,'object',true);
%}

%% Parse the search parameters

varargin = ieParamFormat(varargin);

p = inputParser;
p.addRequired('thisR',@(x)(isa(x,'recipe')));
p.addParameter('object',false,@islogical);
p.addParameter('namecontains','',@ischar);
p.addParameter('branch',false,@islogical);
p.addParameter('material','',@ischar);
p.addParameter('distancerange',[],@isvector);

p.parse(thisR,varargin{:});

object   = p.Results.object;
distance = p.Results.distancerange;
branch   = p.Results.branch;
material = p.Results.material;
name     = p.Results.namecontains;

%%  Start searching

val = [];

% These are the indices of nodes we will examine for other properties
if object,         val = thisR.get('objects');
elseif branch,     val = thisR.get('branches');
elseif light,      val = thisR.get('lights');   % Not right yet.
else,              val = 1:thisR.get('n nodes');
end

if ~isempty(name)
    newval = [];
    for ii=1:numel(val)
        thisName = thisR.get('asset',val(ii),'name');
        if piContains(thisName,name)
            newval(end+1) = ii; %#ok<AGROW> 
        end
    end
end
    
end
