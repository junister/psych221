%% Gateway to ISET3d validation scripts
%
%    v_iset3d_v4
%
% Tutorial scripts.  When these all run, it is a partial validation of the
% code.  More specific tests are still needed.
%
% Validations in this script do not involve calculations that require using
% Flywheel or Google Cloud. There is another validation script, v_piCloud,
% that should check those functions.
%
% ZL,BW, DJC
%
% See also
%   v_piCloud

setpref('ISET3d', 'benchmarkstart', cputime); % if I just put it in a variable it gets cleared:(
setpref('ISET3d', 'tStart', tic);

%% Basic

%% Depth in x,y,z dimensions
disp('*** DEPTH -- t_piIntro_macbeth')
setpref('ISET3d', 'tvdepthStart', tic);
try
    % seems to have broken?
    t_piIntro_macbeth;               % Gets the depth map
catch
    disp('Macbeth failed');
end

setpref('ISET3d', 'tvdepthTime', toc(getpref('ISET3d', 'tvdepthStart', 0)));

%% Zmap
disp('t_piIntro_macbeth_zmap')
setpref('ISET3d', 'tvzmapStart', tic);
t_piIntro_macbeth_zmap;          % Get the zmap
setpref('ISET3d', 'tvzmapTime', toc(getpref('ISET3d', 'tvzmapStart', 0)));

%% Demo working with materials
disp('*** MATERIALS -- t_piIntro_material')
setpref('ISET3d', 'tvmaterialStart', tic);
t_piIntro_material;
setpref('ISET3d', 'tvmaterialTime', toc(getpref('ISET3d', 'tvmaterialStart', 0)));

disp('*** LIGHTS -- t_piIntro_light')
setpref('ISET3d', 'tvlightStart', tic);
t_piIntro_light;
setpref('ISET3d', 'tvlightTime', toc(getpref('ISET3d', 'tvlightStart', 0)));

disp('t_piIntro_pbrtv4')
setpref('ISET3d', 'tvpbrtStart', tic);
t_piIntro_pbrtv4;
setpref('ISET3d', 'tvpbrtTime', toc(getpref('ISET3d', 'tvpbrtStart', 0)));

%%  Check that the scenes in the data directory still run
%{
disp('v_piDataScenes')
v_piDataScenes;                  % Checks the local data scenes
%}
%%  Rotate the camera

disp('*** CAMERA MOTION -- t_cameraMotion')
setpref('ISET3d', 'tvcammotionStart', tic);
t_cameraMotion;
setpref('ISET3d', 'tvcammotionTime', toc(getpref('ISET3d', 'tvcammotionStart', 0)));

%% Maybe redundant with prior cameramotion

disp('*** CAMERA POSITION -- t_cameraPosition')
setpref('ISET3d', 'tvcampositionStart', tic);
t_cameraPosition;
setpref('ISET3d', 'tvcampositionTime', toc(getpref('ISET3d', 'tvcampositionStart', 0)));

%% Try a lens

disp('*** FISHEYE LENS -- t_piIntro_fisheyelens')
setpref('ISET3d', 'tvfisheyeStart', tic);
try
    t_piIntro_fisheyelens;
catch
    disp('fisheye failed')
end
setpref('ISET3d', 'tvfisheyeTime', toc(getpref('ISET3d', 'tvfisheyeStart', 0)));


%% It runs, but we are not happy
%{
disp('t_piIntro_meshLabel')
t_piIntro_meshLabel
%}

%%  Not clearly needed, but it is fast
disp('*** SKYMAPS -- t_skymapDaylight')
setpref('ISET3d', 'tvskymapStart', tic);
t_skymapDaylight;
setpref('ISET3d', 'tvskymapTime', toc(getpref('ISET3d', 'tvskymapStart', 0)));

%% Textures

%{
disp('*** TEXTURES -- t_piIntro_texture')
t_piIntro_texture;
%}
%% Summary
tTotal = toc(getpref('ISET3d','tStart'));
afterTime = cputime;
beforeTime = getpref('ISET3d', 'benchmarkstart', 0);
glData = opengl('data');
disp(strcat("v_ISET3d-v4 (LOCAL) ran  on: ", glData.Vendor, " ", glData.Renderer, "with driver version: ", glData.Version));
disp(strcat("v_ISET3d-v4 (LOCAL) ran  in: ", string(afterTime - beforeTime), " seconds of CPU time."));
disp(strcat("v_ISET3d-v4 ran  in: ", string(tTotal), " total seconds."));
disp('===========');
fprintf("Depth:      %5.1f seconds.\n", getpref('ISET3d','tvdepthTime'));
fprintf("ZMap:       %5.1f seconds.\n", getpref('ISET3d','tvzmapTime'));
fprintf("Material:   %5.1f seconds.\n", getpref('ISET3d','tvmaterialTime'));
fprintf("Light:      %5.1f seconds.\n", getpref('ISET3d','tvlightTime'));
fprintf("PBRT:       %5.1f seconds.\n", getpref('ISET3d','tvpbrtTime'));
fprintf("Cam Motion: %5.1f seconds.\n", getpref('ISET3d','tvcammotionTime'));
fprintf("Cam Pos.:   %5.1f seconds.\n", getpref('ISET3d','tvcampositionTime'));
fprintf("Fisheye:    %5.1f seconds.\n", getpref('ISET3d','tvfisheyeTime'));
fprintf("Skymap:     %5.1f seconds.\n", getpref('ISET3d','tvskymapTime'));

%% END

