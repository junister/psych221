function ieObject = piRender_local(thisR, pbrtPath)
%% temp function, will be replaced by a docker based function
% 
%
outfile  = thisR.get('output file');
[outputDir, fname,~] = fileparts(outfile);
currDir    = pwd;
cd(outputDir);
outputFile = fullfile(outputDir, [fname,'.exr']);
renderCmd  = [pbrtPath, ' --gpu',thisR.outputFile,' --outfile ',outputFile];
system(renderCmd)
cd(currDir);

%%
%% read data
energy   = piReadEXR(outputFile);
dim_energy = size(energy);
if dim_energy(3)==31
    wave = 400:10:700;
elseif dim_energy(3)==16
    wave = 400:20:700;
end
photons  = Energy2Quanta(wave,energy);
ieObject = piSceneCreate(photons,'wavelength', wave);
ieObject = sceneInterpolateW(ieObject,[400:10:700]);
% get depth
depthImage   = piReadEXR(outputFile,'data type','zdepth');
ieObject = sceneSet(ieObject,'depth map',depthImage);
end