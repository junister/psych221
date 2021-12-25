function newR = piRecipeCopy(thisR)
    newR  = recipe;
    params = fieldnames(thisR);
    for ii = 1:numel(params)
        newR.(params{ii}) = thisR.(params{ii});
    end
end