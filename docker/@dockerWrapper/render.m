function [status, result] = render(obj, renderCommand, outputFolder)

if obj.gpuRendering == true
    useContainer = obj.getContainer('PBRT-GPU');
    % okay this is a hack!
    renderCommand = replaceBetween(renderCommand, 1,4, 'pbrt --gpu ');
else
    useContainer = obj.getContainer('PBRT-CPU');
end

% Windows doesn't seem to like the t flag
if ispc
    flags = '-i ';
else
    flags = '-it ';
end

containerRender = sprintf("docker exec %s %s sh -c 'cd %s && %s'",flags, useContainer, outputFolder, renderCommand);
[status, result] = system(containerRender);
end
