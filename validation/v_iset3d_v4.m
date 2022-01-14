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

%% Basic

disp('t_piIntro_macbeth')
t_piIntro_macbeth;               % Gets the depth map

disp('t_piIntro_material')
t_piIntro_material;

disp('t_piIntro_light')
t_piIntro_light;

disp('t_piIntro_pbrtv4')
t_piIntro_pbrtv4;

%% Zmap

disp('t_piIntro_macbeth_zmap')
t_piIntro_macbeth_zmap;          % Get the zmap

%%  Check that the scenes in the data directory still run
%{
disp('v_piDataScenes')
v_piDataScenes;                  % Checks the local data scenes
%}
%%  Rotate the camera

disp('t_piIntro_cameramotion')
t_piIntro_cameraMotion

%% Maybe redundant with prior cameramotion

disp('t_piIntro_cameraposition')
t_cameraPosition

%% Try a lens

disp('t_piIntro_fisheyelens')
try
    t_piIntro_fisheyelens;
catch
    disp('fisheye failed')
end

%%  Change the lighting

disp('t_piIntro_light')
t_piIntro_light;

%%  Glass, mirrors ...

disp('t_piIntro_material')
t_piIntro_material

%% It runs, but we are not happy

%{
disp('t_piIntro_meshLabel')
t_piIntro_meshLabel
%}
%%  Not clearly needed, but it is fast

disp('t_skymapDaylight')
t_skymapDaylight

%% Textures

%{
disp('t_piIntro_texture')
t_piIntro_texture
%}

%% END

