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
t_piIntro_macbeth;               % Gets the depth map
setpref('ISET3d', 'tvdepthTime', toc(getpref('ISET3d', 'tvdepthStart', 0)));

%% Zmap
disp('t_piIntro_macbeth_zmap')
t_piIntro_macbeth_zmap;          % Get the zmap

%% Demo working with materials
disp('*** MATERIALS -- t_piIntro_material')
t_piIntro_material;

disp('*** LIGHTS -- t_piIntro_light')
t_piIntro_light;

disp('t_piIntro_pbrtv4')
t_piIntro_pbrtv4;

%%  Check that the scenes in the data directory still run
%{
disp('v_piDataScenes')
v_piDataScenes;                  % Checks the local data scenes
%}
%%  Rotate the camera

disp('*** CAMERA MOTION -- t_cameraMotion')
t_cameraMotion;

%% Maybe redundant with prior cameramotion

disp('*** CAMERA POSITION -- t_cameraPosition')
t_cameraPosition;

%% Try a lens

disp('*** FISHEYE LENS -- t_piIntro_fisheyelens')
try
    t_piIntro_fisheyelens;
catch
    disp('fisheye failed')
end

%%  Change the lighting

disp('*** MODIFY LIGHTING -- t_piIntro_light')
t_piIntro_light;

%% It runs, but we are not happy

%{
disp('t_piIntro_meshLabel')
t_piIntro_meshLabel
%}
%%  Not clearly needed, but it is fast

disp('*** SKYMAPS -- t_skymapDaylight')
t_skymapDaylight;

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

%% END

