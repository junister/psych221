function outFile = piPBRTUpdateV4(inFile,outFile)
% update PBRT file with v3 format to v4 format
[sceneDir, fname,ext] =fileparts(inFile);
dockerCMD = 'docker run -ti --rm';
dockerImage = 'camerasimulation/pbrt-v4-cpu';
% outFile = fullfile(sceneDir,[fname,'-v4.pbrt']);
VolumeCMD = sprintf('--workdir="%s" --volume="%s:%s"',sceneDir,sceneDir,sceneDir);
CMD = sprintf('%s %s %s pbrt --upgrade %s > %s',dockerCMD, VolumeCMD, dockerImage, inFile, outFile);
[status,result]=system(CMD);
if status
    error(result);
end

%% deal with more cases which are handled properly by PBRT v4

fileIDin = fopen(outFile);

% Create a tmp file
outputFullTmp = fullfile(sceneDir, [fname, '_tmp.pbrt']);
fileIDout = fopen(outputFullTmp, 'w');

while ~feof(fileIDin)
    thisline=fgets(fileIDin);
    
    % delete "string strategy" params
    if ischar(thisline) && contains(thisline,'string strategy')
        continue
        
    % delete "twosided" for arealight
    elseif ischar(thisline) && contains(thisline,'twosided')
        continue
        % delete "twosided" for arealight
    elseif ischar(thisline) && contains(thisline,'Warning')
        continue
    % change ":Vector (1,2,3)" to "# Dimension [1 2 2]"
    elseif ischar(thisline) && contains(thisline,':Vector')
        thisline = strrep(thisline, ':Vector','#Dimension:');
        thisline = strrep(thisline, ', ',' ');
        thisline = strrep(thisline, '(','[');
        thisline = strrep(thisline, ')',']');   
        fprintf(fileIDout, '%s', thisline);
        continue
    end
    fprintf(fileIDout, '%s', thisline);
end
fclose(fileIDin);
fclose(fileIDout);

movefile(outputFullTmp, outFile);

inputMaterialfname  = fullfile(sceneDir,  [fname, '_materials', ext]);
outputMaterialfname = fullfile(outputDir, [fname, '_materials', ext]);
inputGeometryfname  = fullfile(sceneDir,  [fname, '_geometry',  ext]);
outputGeometryfname = fullfile(outputDir, [thisName, '_geometry',  ext]);

if exist(inputMaterialfname, 'file')
    piPBRTUpdateV4(inputMaterialfname,outputMaterialfname);
end

if exist(inputGeometryfname, 'file')
    piPBRTUpdateV4(inputGeometryfname,outputGeometryfname);
end



end