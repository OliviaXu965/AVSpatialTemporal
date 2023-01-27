%% This script analyzes the AV alignment data
clear all;close all;clc
%-------------------------------------------------------------------------
%load the data
%-------------------------------------------------------------------------
subjNum              = 16;
subjInitial          = 'PW';
addpath(genpath(['/e/3.3/p3/hong/Desktop/Project5/Matching task/Analysis/',subjInitial,'/']));
C                    = load(strcat('A_aligns_V_sub', num2str(subjNum), '.mat'),...
                        'A_aligns_V_data');
ExpInfo              = C.A_aligns_V_data{1};
%get the updating distance for all the staircases and convert it to deg
Distance             = C.A_aligns_V_data{8};
Distance(:,end)      = []; %the last one was generated but never used in the experiment
%get the response (whether participants think the V is to the left or right of the A)
LeftOrRight          = C.A_aligns_V_data{6};
%get the data for easy trials
data_easyTrials      = C.A_aligns_V_data{10};

%-------------------------------------------------------------------------
%Get relevant information
%-------------------------------------------------------------------------

%there are 2 locations of the V: [-12, 12]
locations_V         = C.A_aligns_V_data{3}.locations_deg;
%for each test location, there were 2 staircases
%1. the A starts from the left side of the V
%2. the A starts from the right side of the V
numStaircasesPerLoc = ExpInfo.numStaircases/ExpInfo.testLocations;
%number of easy trials
numEasyTrials       = length(data_easyTrials);
%number of easy trials for each test location
numEasyTrialsPerLoc = size(data_easyTrials,2)/length(locations_V);

%% plot the interleaved staircases
figure(1)
%create a color matrix for those 8 interleaved staircases
colorMat = [70,130,180;255,140,0; 34,139,34;255,0,0]./255;
%for each test location, there are 2 interleaved staircases
for k = 1:ExpInfo.testLocations
    for i = 1:numStaircasesPerLoc
        %plot the location of the A
        plot(1:ExpInfo.numTrials,Distance((k-1)*2+i,:),'-','LineWidth',2,...
            'Color',colorMat(k,:)); hold on
    end
    %plot the location of the V
    plot([1 ExpInfo.numTrials],[locations_V(k) locations_V(k)],'--',...
        'LineWidth',2,'Color',colorMat(k,:)); hold on
    
    %plot the responses (blue: A is to the left of V; yellow: A is to the right of V)
    for i = 1:numStaircasesPerLoc
        for j = 1:ExpInfo.numTrials 
            if LeftOrRight((k-1)*2+i,j)==-1
                plot(j,Distance((k-1)*2+i,j),'Marker','s','MarkerEdgeColor',...
                    'y','MarkerFaceColor','b','MarkerSize',7);
            else
                plot(j,Distance((k-1)*2+i,j),'Marker','s','MarkerEdgeColor',...
                    'b','MarkerFaceColor','y','MarkerSize',7);
            end
            hold on
        end
    end
    xlabel('Trial number'); ylabel('Stimulus location (deg)');
end
hold off; box off
xlim([1 ExpInfo.numTrials]);
%xticks([1 ExpInfo.numTrials/2 ExpInfo.numTrials]); yticks(testLocs);
title('Interleaved Staircases');
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 0.4, 0.4]);
set(gca,'FontSize',15, 'XTick',[1 ExpInfo.numTrials/2 ExpInfo.numTrials],...
    'YTick',locations_V);
set(gcf,'PaperUnits','centimeters','PaperSize',[27 15]);
saveas(gcf,sprintf(['InterleavedStaircases_sub' num2str(subjNum) '.pdf']));

%% sort the data and add easy trials
%combine the loc of the V and the responses for the 2 interleaved staircases 
%for each test location together
Distance_reshaped    = reshape(Distance',[ExpInfo.numTrials*numStaircasesPerLoc,...
                        ExpInfo.testLocations])';
LeftOrRight_reshaped = reshape(LeftOrRight',[ExpInfo.numTrials*numStaircasesPerLoc,...
                        ExpInfo.testLocations])';
numTrials_comb       = size(Distance_reshaped,2);

%organize the data
for i = 1:ExpInfo.testLocations
    %put the location of the V in the 1st row and the response in the 2nd row
    data.sorted{i}(1,1:numTrials_comb) = Distance_reshaped(i,:);
    data.sorted{i}(2,1:numTrials_comb) = LeftOrRight_reshaped(i,:);
    
    %from easy trials, find the indices of the trials that match the test location
    matching_idx = (data_easyTrials(3,:) == locations_V(i));
    %append the location of the A to data.sorted
    data.sorted{i}(1,numTrials_comb+1:numTrials_comb+numEasyTrialsPerLoc) = ...
        data_easyTrials(4,matching_idx);
    %append the response to data.sorted
    data.sorted{i}(2,numTrials_comb+1:numTrials_comb+numEasyTrialsPerLoc) = ...
        data_easyTrials(6,matching_idx);
   
    %when fitting a psychometric function, we will calculate the
    %probability of saying the V is to the right of the A, so we change all
    %-1 to 0
    data.sorted{i}(2,data.sorted{i}(2,:)==-1) = 0;
end

%% fit a psychometric function
%common lapse rate, alpha1, sigma1, alpha2, sigma2,
lb              = [   0, -15,  0.01,  0, 0.01]; 
ub              = [0.06,   0,    10, 15,   10]; %set boundaries
initialization  = [   0,  -7,     3,  7,    3];
options         = optimoptions(@fmincon,'MaxIterations',1e5,'Display','off');
nLogL           = @(p) nLL_commonLapse(p(1),p(2),p(3),p(4),p(5),data.sorted);
[data.estimatedP, LogLValue] = fmincon(nLogL, initialization,[],[],[],[],...
                    lb,ub,[],options);
disp('Estimated values of the parameters:');
disp(data.estimatedP);

%% plot fitted psychometric function 
%specify plotting information
bds                 = [min(Distance(:)), max(Distance(:))]; numX = 1e3;
pltInfo.x           = linspace(bds(1)-3,bds(end)+3, numX);
pltInfo.numBins     = 30; 
pltInfo.bool_save   = 1;
pltInfo.subjI       = subjInitial;
pltInfo.bool_plt_CI = 0;
data.binned         = plot_psychfunc(data, ExpInfo, pltInfo);

%% Do bootstrap and calculate the confidence interval of PSE
numBootstraps = 1e3;
[data.PSE,data.PSE_lb,data.PSE_ub,data.estP] = Bootstrap(data.sorted,...
    numBootstraps, lb,ub,options);
disp(mean(data.PSE));

%%
cnorm = @(t,p) normcdf(t,p(1),p(2)).*(1-p(3))+p(3)/2;
[psychfunc1_btst, psychfunc2_btst] = deal(NaN(numBootstraps, length(pltInfo.x))); 
for i = 1:numBootstraps
    estP_i = data.estP(i,:);
    psychfunc1_btst(i,:) = cnorm(pltInfo.x, [estP_i(2), estP_i(3), estP_i(1)]);
    psychfunc2_btst(i,:) = cnorm(pltInfo.x, [estP_i(4), estP_i(5), estP_i(1)]);
end

psychfunc1_btst_sort = sort(psychfunc1_btst,1);
psychfunc2_btst_sort = sort(psychfunc2_btst,1);
idx_lb               = floor(numBootstraps*0.025);
idx_ub               = ceil(numBootstraps*0.975);
pltInfo.CI           = {[psychfunc1_btst_sort(idx_lb,:);psychfunc1_btst_sort(idx_ub,:)],...
                        [psychfunc2_btst_sort(idx_lb,:);psychfunc2_btst_sort(idx_ub,:)]};

%plot with confidence intervals
pltInfo.bool_plt_CI  = 1;
plot_psychfunc(data, ExpInfo, pltInfo);
                    
%% save the data
out1FileName = ['AV_alignment_sub' num2str(subjNum) '_dataSummary'];
AV_alignment_data = {ExpInfo, data};
save(out1FileName,'AV_alignment_data');
