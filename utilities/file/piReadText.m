function [txtLines, header] = piReadText(fname)
% Open, read, close excluding comment lines
%
% Synopsis
%    [txtLines, header] = piReadText(fname)
%
% Inputs
%   fname = File name.  
%
% Outputs
%   txtLines
%   header
%
% See also
%   piRead

fileID = fopen(fname);
% tmp = textscan(fileID,'%s','Delimiter','\n','CommentStyle',{'#'});
tmp = textscan(fileID,'%s','Delimiter','\n');

txtLines = tmp{1};
fclose(fileID);

% Include comments so we can read only the first line, really
fileID = fopen(fname);
tmp = textscan(fileID,'%s','Delimiter','\n');
header = tmp{1};
fclose(fileID);

end