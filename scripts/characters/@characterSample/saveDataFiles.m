function result = saveSampleDataFiles(options)
        % find base storage folder, can leverage off prepData for DB
        % version
        arguments
            options.oi = []'
            options.scene = [];
            options.cMosaic = [];
        end
        % Where do we want our root folder?
        % right now seedling someplace
        % IRL we'll put them on acorn or a public version of seedline
        % or a more powerful server if needed
        sampleDataRoot = 'v:\characters';
        sampleDataType = 'MATLAB'; % could be JSON
        saveDataFileDir = fullfile(sampleDataRoot, type);

        switch sampleDataType
            case 'MATLAB'
                suffix = '.mat';
            case 'JSON'
                suffix = '.json';
        end

        %% NEEDS HELP, BUT TIME FOR BED
        saveDataFile = fullfile(saveDataFileDir, [object.ID suffix]);

        % make sure we get what we want for 'object' 
        % Kind of yucky
        % Need to decide whether to call for all 3 in one function
        % or have 3 functions that each call for separate ones
        switch class(object)
            case 'oi'
                saveObject = 'oi';
            case 'scene'
                saveObject = 'scene';
            case 'coneMosaic'
                saveObject = 'cMosaic';
            otherwise
                warning('do not know how to save this');
                result = -1; % didn't work
        end
        try
            save(saveDataFile, saveObject);
        catch
            result = -1; % failed
        end
    end
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