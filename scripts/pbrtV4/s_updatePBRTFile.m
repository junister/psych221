%% Update V3 to V4
%
ieInit;
piDockerConfig;
%%
sceneName = 'chessSet';
inFile = fullfile(piRootPath,'data','V3',sceneName,[sceneName,'.pbrt']);
% inFile = '/Users/zhenyi/Documents/SOW/scenes/slantedEdge/slantedEdge.pbrt';
outputDir = fullfile(piGetDir('scenes'),sceneName);
if ~exist(outputDir,'dir'), mkdir(outputDir);end

outFile = fullfile(outputDir,[sceneName,'.pbrt']);

% This does the PBRT conversion 
outFile = piPBRTUpdateV4(inFile, outFile);

%% Copy the auxiliary files

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
%{
infile = piPBRTReformat(outFile);
thisR  = piRead(infile);

piWrite(thisR);

scene = piRender(thisR);
sceneWindow(scene);

%}
% thisR = piRecipeDefault('scene name','chessSet');
% thisR = piRead(outFile);
% scene = piWRS(thisR);

%%