sceneName = 'checkerboard';
inFile = fullfile('/Users/zhenyi/git_repo/dev/iset3d-v4/data/V3',sceneName,[sceneName,'.pbrt']);

outputDir = fullfile(piRootPath,'data/V4',sceneName);
if ~exist(outputDir,'dir'), mkdir(outputDir);end
outFile = fullfile(outputDir,[sceneName,'.pbrt']);

outFile = piPBRTUpdateV4(inFile, outFile);

[inputDir,~,~]=fileparts(inFile);
fileList = dir(inputDir);
fileList(1:2)=[];
for ii = 1:numel(fileList)
    [~,~,ext]=fileparts(fileList(ii).name);
    if strcmp(ext,'.pbrt')
        continue;
    else
        copyfile(fullfile(fileList(ii).folder, fileList(ii).name), ...
            fullfile(outputDir, fileList(ii).name));
    end
end