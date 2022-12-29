classdef characterSample < handle
    % Class to handle creation, storage, and retrieval of character data
    % samples used for the analysis of readability in 3D, VR, AR, and MR
    %
    % Parameters (properties):
    %
    % Methods:
    %
    %
    % Examples:
    %
    %
    % D. Cardinal, Stanford University, 2022
    %

    properties
        %% Flesh out Metadata, much is in recipe, but is called out
        % separately to make it easier to do db searches, and in case
        % we have large recipes that won't fit in the database
        type = 'character';
        recipe; % includes mapping to uc_
        character = ''; % the character being rendered
        fov = 1; % Default
        resolution = [240 240]; % film resolution
        raysPerPixel = []; % passed in or from recipe
        characterMaterial = ''; % passed in or from recipe
        backgroundMaterial = ''; %passed in or from recipe
        illumination = ''; % short-hand for what's in recipe?
        mosaicMetaData = ''; % TBD info about mosaic

        %% Get ID
        ID = getDataSampleID(); % pass some params

        % Preview Images that are small enough to fit in DB
        sceneJPEG = [];
        oiJPEG = [];
        mosaicJPEG = [];

        % Stored Files that are too big for the database
        % keyed off foldername/ID(.mat or .json or .jpeg)
        sceneStoreFile = '';
        oiStoreFile = '';
        mosaicStoreFile = '';
    end

    methods
        function cSample = characterSample(options)
            %% Create a usable sample image and mosaic for
            arguments 
                options.Recipe;
            end
            recipe = options.Recipe;
        end

        function saveCharacterSample(obj)

            cMosaic = computeConeMosaic(obj);
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


            %% Save oi/scene/mosaic
            % The hope is that they can be saved in directories with those names
            % but file names that are "ID.mat" (unless JSON is needed/practical).

            % Check Results == before saving metadata into DB
            % We switch based on which one in the save routine, so maybe we
            % can simplify to save all three?
            result = saveDataFiles(obj, 'oi',oi, 'scene', scene, 'cMosaic', cMosaic);
            if result == 0
                % Save Metadata
                % ...
                % save recipe
            else
                warning("unable to save data files");
            end

        end


    end
end



