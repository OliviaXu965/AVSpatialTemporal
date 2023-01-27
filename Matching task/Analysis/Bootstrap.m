%This function takes the data, number of bootstraps, boundaries for fitting
%a psychometric function, initialization as inputs and generates 
function [PSEs, Value_lb, Value_ub, estimatedP] = Bootstrap(data,...
    numBootstraps,lb,ub,options) 
    %1st row: stimulus intensity
    %2nd row: number of "right" responses  
    numPF      = length(data);
    numTrials  = size(data{1},2);
    PSEs       = zeros(numBootstraps,numPF);
    randInit   = @(val_lb, val_ub) rand(1)*(val_ub - val_lb) + val_lb;
    estimatedP = NaN(numBootstraps, length(lb));
    for i = 1:numBootstraps
        disp(i)
        %resample with replacement
        indices_selected = randi([1 numTrials],[1 numTrials]);
        data_selected = cell(1,numPF);
        for j = 1:numPF;data_selected{j} = data{j}(:,indices_selected);end
        %random initialization
        init = arrayfun(@(idx) randInit(lb(idx), ub(idx)), 1:5);
        %use the resampled data to fit a psychometric curve
        nLogL = @(p) nLL_commonLapse(p(1),p(2),p(3),p(4),p(5),data_selected);
        [estimatedP(i,:),~] = fmincon(nLogL,init,[],[],[],[],lb,ub,[],options);     
        PSEs(i,:) = estimatedP(i,2:2:end);
    end
    
    %sort the JND and find the value that corresponds to 2.5% and 97.5%
    PSEs_sorted = sort(PSEs);
    Value_lb = PSEs_sorted(ceil(numBootstraps*0.025),:);
    Value_ub = PSEs_sorted(floor(numBootstraps*0.975),:);
end
    

    