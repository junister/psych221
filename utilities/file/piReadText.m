function txtLines = piReadText(fname)
% Open, read, close excluding comment lines
%
% Synopsis
%    txtLines = piReadText(fname)
%
% Inputs
%   fname = PBRT scene file name.  
%
% Outputs
%   txtLines - Cell array of each of the text lines in the file.
%
% See also
%   piRead

%% Open the PBRT scene file
fileID = fopen(fname);
% tmp = textscan(fileID,'%s','Delimiter','\n','CommentStyle',{'#'});
tmp = textscan(fileID,'%s','Delimiter','\n');

txtLines = tmp{1};
fclose(fileID);

%{
% It seems like in the past we excluded the comment lines.  But then
% we included them, probably so we can get the objectnames.  That made
% this bit of code redundant.  I am removing (BW, March 31, 2023).
fileID = fopen(fname);
tmp = textscan(fileID,'%s','Delimiter','\n');
header = tmp{1};
fclose(fileID);
%}

end