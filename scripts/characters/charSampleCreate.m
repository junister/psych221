function charSampleCreate(obj, thisR, options)
%% Create a usable sample image and mosaic for
arguments
    obj;
    thisR; % for saving to metadata
    options.thisName = 'letter';
end

%  Needs ISETBio -- and set parallel to thread pool for performance
if piCamBio
    warning('Cone Mosaic requires ISETBio');
    return
end
% Create an oi if we aren't passed one
if isequal(class(obj),'oi')
    oi=obj;
else
    scene = obj;
    oi = oiCreate('wvf human');

end

poolobj = gcp('nocreate');
if isempty(poolobj)
    parpool('Threads');
end

% Create the coneMosaic object
% We want this to be about .35mm in diameter
% or 1 degree FOV
cMosaic = coneMosaic;
cMosaic.fov = [1 1]; % 1 degree in each dimension
cMosaic.emGenSequence(50);

oi = oiCompute(oi, scene);
cMosaic.name = options.thisName;
cMosaic.compute(oi);
cMosaic.computeCurrent;

% We now have a recipe, an oi and/or scene, and a cone mosaic with absorbtions
% We get both a scene and an oi if the scene has been rendered with pinhole
% The next step is to save it for analysis
% The mosaic and oi/scene are too large for a mongoDB data item

% Current thought is to create a unique ID, then store the oi, scene, and
% cone mosaic with that ID in separate folders. .mat seems okay, since it
% is smaller than .json, and I don't know if we have other tools that need
% .json (if the pytorch code uses it, we can switch).

% Then save the overall metadata (including recipe) to a mongoDB item with
% that same ID. Need to figure out what/which indices we have.

% If we also save the metadata to a .json in the metadata folder, then it
% will be easier to re-create the mongoDB. In fact as a first pass we might
% want to write out all the files and then bulk import them into a db.

%% Flesh out Metadata
dataSample.type = 'character';
dataSample.recipe = thisR;
dataSample.character = ''; XXX
dataSample.fov = 1; % Default
dataSample.resolution = [240 240]; NEED TO SET
dataSample.charMaterial = ''; NEED TO SET
dataSample.backgroundMaterial = ''; NEED TO SET
dataSample.illumination = ''; NEED TO SET, COULD BE COMPLEX
dataSample.mosaicMetaData = ''; NEED TO SET


%% Get ID & save Metadata

docSample.ID = getDataSampleID(); % pass some params

%% Save oi/scene/mosaic

% =======================================================================
%% START SUPPORT FUNCTIONS HERE
%%
    function ID =  getDataSampleID(prefix)

        timeStampSeparator = '__'; % keep timestamp accessible

        % figure out a uniqueID that would be helpful
        % Time should be GMT (I think) although mostly it needs to help
        % with local values. I guess we could store timezone.
        % NOTE: They want us to use datetime, but I can't find an easy way
        % to get it to use milliseconds. Example code in the doc doesn't
        % work.
        timeStamp = datestr(now,'yyyy_mm_dd_HH_MM_SS_FFF'); %#ok<TNOW1,DATST> 
        ID = [prefix timeStampSeparator timeStamp];

    end

end



