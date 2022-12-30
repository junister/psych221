function result = saveDataFiles(obj, options)
% find base storage folder, can leverage off prepData for DB
% version
arguments
    obj;
    options.oi = obj.oi;
    options.scene = obj.scene;
    options.cMosaic = obj.cMosaic;
end

% Where do we want our root folder?
% right now seedling someplace
% IRL we'll put them on acorn or a public version of seedline
% or a more powerful server if needed
sampleDataRoot = 'v:\characters';
sampleDataType = 'MATLAB'; % could be JSON
switch sampleDataType
    case 'MATLAB'
        suffix = '.mat';
    case 'JSON'
        suffix = '.json';
end
try
    % can probably group these:)
    if ~isempty(options.oi)
        saveDataFileDir = fullfile(sampleDataRoot, 'oi');
        save(fullfile(saveDataFileDir,['oi_' obj.ID suffix], 'oi'));
    end
    if ~isempty(options.scene)
        saveDataFileDir = fullfile(sampleDataRoot, 'scene');
        save(fullfile(saveDataFileDir,['scene_' obj.ID suffix], 'scene'));
    end
    if ~isempty(options.cMosaic)
        saveDataFileDir = fullfile(sampleDataRoot, 'mosaic');
        save(fullfile(saveDataFileDir,['mosaic_' obj.ID suffix], 'cMosaic'));
    end
catch
    result = -1; % something failed
    return
end
result = 0;


end

