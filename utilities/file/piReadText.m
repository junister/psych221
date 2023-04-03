function txtLines = piReadText(fname)
% Open, read, close excluding comment lines
%
% Synopsis
%    txtLines = piReadText(fname)
%
% Brief description:
%   Read the text lines in the PBRT scene file.  Also strips any
%   trailing blanks on the line and does some fix for square brackets.
%   The square bracket thing is historical.
%
%   Comment lines are left as part of the text because they sometimes
%   contain useful information about object names.
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

% Remove empty lines here?

% We remove any trailing blank spaces from the text lines here. (BW).
for ii=1:numel(txtLines)
    idx = find(txtLines{ii} ~=' ',1,'last');
    txtLines{ii} = txtLines{ii}(1:idx);
end

% Replace left and right bracks with double-quote.  ISET3d formatting.
txtLines = strrep(txtLines, '[ "', '"');
txtLines = strrep(txtLines, '" ]', '"');

%{
% In the past we excluded the comment lines.  But then
% we included them, probably so we can get the objectnames.  That made
% this bit of code redundant.  I am removing (BW, March 31, 2023).
%
fileID = fopen(fname);
tmp = textscan(fileID,'%s','Delimiter','\n');
header = tmp{1};
fclose(fileID);
%}

end