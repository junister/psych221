%% Gateway to ISET3d validation scripts
%
%    v_iset3d_v4
%
% Validation and Tutorial scripts.  When these all run, it is a partial validation of the
% code.  More specific tests are still needed.
%
% ZL,BW, DJC
%

%%
setpref('ISET3d', 'benchmarkstart', cputime); % if I just put it in a variable it gets cleared:(
setpref('ISET3d', 'tStart', tic);

%% Basic
ieInit;
if ~piDockerExists, piDockerConfig; end


%% Quick version of DockerWrapper tests
disp('*** DOCKER -- v_DockerWrapper');
setpref('ISET3d', 'tvdockerStart', tic);
try
    v_DockerWrapper('length','short');
    setpref('ISET3d', 'tvdockerTime', toc(getpref('ISET3d', 'tvdockerStart', 0)));
catch
    disp('Docker Wrapper test failed');
    disp('Make sure you have a remote image set up before running');
    setpref('ISET3d', 'tvdockerTime', -1);
end

%% Depth in x,y,z dimensions
disp('*** DEPTH -- t_piIntro_macbeth')
setpref('ISET3d', 'tvdepthStart', tic);
try
    t_piIntro_macbeth;               % Gets the depth map
    setpref('ISET3d', 'tvdepthTime', toc(getpref('ISET3d', 'tvdepthStart', 0)));
catch
    disp('Macbeth failed');
    setpref('ISET3d', 'tvdepthTime', -1);
end

%% Omni camera (e.g. one with a lens)
disp('v_omni')
setpref('ISET3d', 'tvomniStart', tic);
v_omni;          
setpref('ISET3d', 'tvomniTime', toc(getpref('ISET3d', 'tvomniStart', 0)));

%% Assets
disp('t_assets')
setpref('ISET3d', 'tvassetsStart', tic);
t_assets;          % Get the zmap
setpref('ISET3d', 'tvassetsTime', toc(getpref('ISET3d', 'tvassetsStart', 0)));

%% Demo working with materials
disp('*** MATERIALS -- t_piIntro_material')
setpref('ISET3d', 'tvmaterialStart', tic);
t_piIntro_material;
setpref('ISET3d', 'tvmaterialTime', toc(getpref('ISET3d', 'tvmaterialStart', 0)));

%% Demo working with lights
disp('*** LIGHTS -- t_piIntro_light')
setpref('ISET3d', 'tvlightStart', tic);
try
    t_piIntro_light;
    setpref('ISET3d', 'tvlightTime', toc(getpref('ISET3d', 'tvlightStart', 0)));
catch
    disp('piIntro_Light failed');
    setpref('ISET3d', 'tvlightTime', -1);
end

%% Our Intro Demo
disp('*** INTRO -- t_piIntro')
setpref('ISET3d', 'tvpbrtStart', tic);
t_piIntro;
setpref('ISET3d', 'tvpbrtTime', toc(getpref('ISET3d', 'tvpbrtStart', 0)));

%%  Translate and Rotate the camera
disp('*** CAMERA POSITION -- t_cameraPosition')
setpref('ISET3d', 'tvcampositionStart', tic);
t_cameraPosition;
setpref('ISET3d', 'tvcampositionTime', toc(getpref('ISET3d', 'tvcampositionStart', 0)));

%% Various renders of the Chess Set
disp('*** CHESS SET -- t_piIntro_chess')
setpref('ISET3d', 'tvchessStart', tic);
try
    t_piIntro_chess;
catch
    disp('chess set failed')
end
setpref('ISET3d', 'tvchessTime', toc(getpref('ISET3d', 'tvchessStart', 0)));


%% This does not run in v4 yet
%{
disp('t_piIntro_meshLabel')
t_piIntro_meshLabel
%}

%%  test our skymap specific API
disp('*** SKYMAPS -- t_skymapDaylight')
setpref('ISET3d', 'tvskymapStart', tic);
v_skymap;
setpref('ISET3d', 'tvskymapTime', toc(getpref('ISET3d', 'tvskymapStart', 0)));

%% Textures
% THIS DOES NOT WORK IN v4 yet
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
fprintf("Docker:     %5.1f seconds.\n", getpref('ISET3d','tvdockerTime'));
fprintf("Depth:      %5.1f seconds.\n", getpref('ISET3d','tvdepthTime'));
fprintf("Omni:       %5.1f seconds.\n", getpref('ISET3d','tvomniTime'));
fprintf("Assets:     %5.1f seconds.\n", getpref('ISET3d','tvassetsTime'));
fprintf("Material:   %5.1f seconds.\n", getpref('ISET3d','tvmaterialTime'));
fprintf("Light:      %5.1f seconds.\n", getpref('ISET3d','tvlightTime'));
fprintf("Cam Pos.:   %5.1f seconds.\n", getpref('ISET3d','tvcampositionTime'));
fprintf("Chess Set:  %5.1f seconds.\n", getpref('ISET3d','tvchessTime'));
fprintf("Skymap:     %5.1f seconds.\n", getpref('ISET3d','tvskymapTime'));

%% END

