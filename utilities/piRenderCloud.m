function ieObject = piRenderCloud(thisR)
%% render using a google VM
%{
inputFolder = '/Users/zhenyi/git_repo/dev/iset3d-v4/local/TeaTime-converted'
outputfile = piRenderCloud(inputFolder);
%}
%%
wave = 400:10:700;
zone = 'us-west1-a';
instanceName = 'zhenyi27@holidayfun-zhenyi';
%%
tic
disp('*** Start rendering using a gcloud instance...');

% zip folder
inputFolder = thisR.get('output dir');
[rootDir,fname]=fileparts(inputFolder);
zipName = [fname,'.zip'];
zipFile = fullfile(rootDir,zipName);
zip(zipFile, inputFolder);
% upload folder to google instance/ unzip/ render/ and bring back
disp('Uploading the scene...');
vmFolder = '~/git_repo/renderVolume';
cmd = sprintf('gcloud compute scp --zone=%s %s %s:%s',...
    zone, zipFile, instanceName,vmFolder);
[status] = system(cmd);
if status
    error(result)
end
disp('Rendering...');

baseCmd = spritnf('gcloud compute ssh --zone=%s %s ',...
    zone, instanceName);
renderCmd = strcat(baseCmd, sprintf(' --command ''cd %s && unzip -o %s && cd %s && ~/git_repo/PBRT-GPU/pbrt-zhenyi/build/pbrt --gpu %s --outfile %s''  ',...
    vmFolder, zipName, fname,[fname, '.pbrt'],[fname, '.exr']));

[status] = system(renderCmd);
if status
    error(result)
end

localFolder = fullfile(inputFolder,'renderings');
if ~exist(localFolder,'dir'), mkdir(localFolder);end
GetImgCMD = sprintf('gcloud compute scp --zone=%s %s:%s %s',...
    zone, instanceName, fullfile(vmFolder, fname, [fname, '.exr']), localFolder);
[status] = system(GetImgCMD);
if status
    error(result)
else
    outFile  = fullfile(localFolder, [fname, '.exr']);
end
% clean data
disp('Data cleaning...');
delete(zipFile);
[status]= system(strcat(baseCmd,sprintf(' --command ''rm -r %s && mkdir %s''',vmFolder,vmFolder)));
%%
elapsedTime = toc;
fprintf('Rendering time for %s:  %.1f sec ***\n\n',fname,elapsedTime);

%% Convert the returned data to an ieObject
disp('Creating iset object');
if isempty(thisR.metadata)
    ieObject = piEXR2ISET(outFile, 'recipe',thisR,'label',{'radiance'});
else
    ieObject = piEXR2ISET(outFile, 'recipe',thisR,'label',thisR.metadata.rendertype);
end
%% 
if isstruct(ieObject)
    switch ieObject.type
        case 'scene'
            curWave = sceneGet(ieObject,'wave');
            if ~isequal(curWave(:),wave(:))
                ieObject = sceneSet(ieObject, 'wave', wave);
            end
            
        case 'opticalimage'
            curWave = oiGet(ieObject,'wave');
            if ~isequal(curWave(:),wave(:))
                ieObject = oiSet(ieObject,'wave',wave);
            end
            
        otherwise
            error('Unknown struct type %s\n',ieObject.type);
    end
end
disp('*** Done');
end