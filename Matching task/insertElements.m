function [newVec,newIndices_newElements] = insertElements(indices, newElements, Vec)
    newVec = NaN(1,length(Vec) + length(newElements));
    for i = 1:length(newElements)
        if i == 1
            newVec(1:indices(i)+1) = [Vec(1:indices(i)) newElements(i)];
        else
            newVec((indices(i-1)+i):(indices(i)+i)) = ...
                [Vec((indices(i-1)+1):indices(i)) newElements(i)];
        end
    end
    newVec((indices(end)+length(newElements)+1):end) = ...
        Vec((indices(end)+1):end);
    newIndices_newElements = indices+(1:length(newElements));
end