% This script executes when exiting Matlab
%
% I had some issues restarting Matlab because this routine did not return
% in a timely fashion.  We should probably debug some more. (BW).
%
%%
disp("Removing remote docker containers used by PBRT V4\n")

dockerWrapper.reset();

disp("Finished")

%%