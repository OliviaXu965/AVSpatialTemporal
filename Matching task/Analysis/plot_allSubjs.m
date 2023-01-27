clear all; close all; clc
%load the data
subjN_dict = [3,4,5,6,8,9,11,12,13,15,16,17,18,19,20];
subjI_dict = {'PW','SW','HL','YZ','NH','ZZ','BB','ZY','MR','AD','SM','SX','ZL','RE','MM'};
lenS       = length(subjN_dict);
get95CI    = @(m,n) [m(ceil(n*0.025)), m(floor(n*0.975))];
[a_A, b_A, lb_a_A, ub_a_A, lb_b_A, ub_b_A] = deal(NaN(1,lenS));
pltInfo.numBins   = 30; 
pltInfo.bool_save = 0;

for i = 1:lenS
    subjN    = subjN_dict(i); 
    subjI    = subjI_dict{i}; pltInfo.subjI = subjI;
    addpath(genpath(['/Users/hff/Desktop/NYU/Project2/Experiment code/',...
        'Matching task v3/Data/', subjI]));
    C = load(['AV_alignment_sub', num2str(subjN), '_dataSummary.mat'],...
        'AV_alignment_data');
    ExpInfo  = C.AV_alignment_data{1};
    data     = C.AV_alignment_data{2};
    numBtst  = size(data.PSE,1);
    dati)   = data.polyfit(1); b_A(i) = data.polyfit(2);
    PSE_btst = data.PSE;
    ab_btst = arrayfun(@(idx) polyfit([-12,-4,4,12], PSE_btst(idx,:),1)',...
                        1:numBtst, 'UniformOutput', false);
    ab_btst_mat = [ab_btst{:}]; 
    bds_a_A   = get95CI(sort(ab_btst_mat(1,:)), numBtst); 
    lb_a_A(i) = bds_a_A(1); ub_a_A(i) = bds_a_A(end);
    bds_b_A   = get95CI(sort(ab_btst_mat(2,:)), numBtst);
    lb_b_A(i) = bds_b_A(1); ub_b_A(i) = bds_b_A(end);
    
    D        = load(['A_aligns_V_sub', num2str(subjN), '.mat'],'A_aligns_V_data');
    Distance = D.A_aligns_V_data{8};
    Distance(:,end)= []; %the last one was generated but never used in the experiment
    %specify plotting information
    bds               = [min(Distance(:)), max(Distance(:))]; numX = 1e3;
    pltInfo.x         = linspace(bds(1)-5,bds(end)+5, numX);
    %plot psychometric curve
    plot_psychfunc(data, ExpInfo, pltInfo);
    
    %plot PSE
    plot_PSE(data, ExpInfo, pltInfo)
end

%% plot
mean_a_A = mean(a_A); 
mean_b_A = mean(b_A); 
SE_a_A   = std(a_A)/sqrt(lenS); 
SE_b_A   = std(b_A)/sqrt(lenS);
disp(['Group mean a_A: ', num2str(mean_a_A), ', SEM: ', num2str(SE_a_A)]);
disp(['Group mean b_A: ', num2str(mean_b_A), ', SEM: ', num2str(SE_b_A)]);
bool_save = 1;
plot_regLines(a_A, b_A, lb_a_A, ub_a_A, lb_b_A, ub_b_A, mean_a_A,...
    mean_b_A, SE_a_A, SE_b_A, bool_save)

