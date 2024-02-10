function [hashSHA256,contentStruct] = contentCreate(obj, varargin)
% Create a content in the collection
%
% Brief
%   Create a content in the collection.
% 
% Syntax
%   [status, contentID] = idb.contentCreate(varargin)
%
% Input
%    collection: collection name
%
%
% Optional key/values parameters
%
%
% Return
%     hashSHA256: unique ID created by mongo database
%
% Description
%
%
% Zhenyi, Stanford, 2024

%% Parse inputs
varargin = ieParamFormat(varargin);
p = inputParser;
p.addParameter('collectionname', '',@ischar);
p.addParameter('type', '',@ischar);
p.addParameter('name', '',@ischar);
p.addParameter('filepath', '',@ischar);
p.addParameter('category', '',@ischar);
p.addParameter('size', '',@isnumeric);
p.addParameter('createdat', char(datetime('now')),@ischar);
p.addParameter('updatedat', '',@ischar);
p.addParameter('createdby', getenv('USER'),@ischar);
p.addParameter('updatedby', getenv('USER'),@ischar);
p.addParameter('author', getenv('USER'),@ischar);
p.addParameter('tags', '',@ischar);
p.addParameter('description', '',@ischar);
p.addParameter('format', '',@ischar);

% assets and scenes
p.addParameter('mainfile', '',@ischar);
p.addParameter('source','',@ischar);

p.parse(varargin{:});
%%
contentStruct = contentSet(p.Results);
hashSHA256 = hashStruct(contentStruct);
contentStruct.hash = hashSHA256;
queryString = sprintf("{""hash"": ""%s""}", hashSHA256);
try
    doc = find(obj.connection, p.Results.collectionname, Query = queryString);
    if isempty(doc)
        docCount = insert(obj.connection, p.Results.collectionname, contentStruct);
    else
        disp('[INFO]: Content already exists.');
    end

catch ex
    fprintf("[INFO]: Database add failed: %s\n", ex.message);
end
if docCount<0
    fprintf("[INFO]: Database add failed: %s\n", p.Results.collectionname);
end
end


%%
function s = contentSet(parameters)
s = struct(...
    'type', parameters.type, ...
    'name', parameters.name, ...
    'category', parameters.category, ...
    'size', parameters.size, ...
    'createdat', parameters.createdat, ...
    'updatedat', parameters.updatedat, ...
    'createdby', parameters.createdby, ...
    'updatedby', parameters.updatedby, ...
    'author', parameters.author, ...
    'tags', parameters.tags, ...
    'filepath', parameters.filepath, ...
    'description', parameters.description, ...
    'format', parameters.format, ...
    'mainfile', parameters.mainfile, ...
    'source', parameters.source ...
    );
end











