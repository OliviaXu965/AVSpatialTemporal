clear all; close all; clc
subjNs     = [3,4,5,6,8,9,11,12,13,15,16,17,18,19,20];
subjIs     = {'PW','SW','HL','YZ','NH','ZZ','BB','ZY','MR','AD','SM','SX','ZL','RE','MM'};
nS         = length(subjNs);
spatialD   = -24:8:24;
lenD     = length(spatialD);
cond     = {'congruent','incongruent'};
lenC     = length(cond);
phase    = {'pre','post'}; 
lenP     = length(phase);
modality = {'A','V'};
lenM     = length(modality);

unityJdg      = NaN(nS, lenC, lenP, lenD);
diff_unityJdg = NaN(nS, lenC, lenD);
VE            = NaN(nS, lenC, lenP, lenM, lenD);
diff_VE       = NaN(nS, lenC, lenM, lenD);

for i = 1:nS
    addpath(genpath(['/Users/hff/Desktop/NYU/Project2/Experiment code/',...
        'Bimodal localization v2/Data/', subjIs{i}]));
    C        = load(['Summary_VE_sub', num2str(subjNs(i)), '.mat'], 'Summary_VE');
    %size: 2 conditions x 2 phases x 7 spatial discrepancies
    unityJdg(i,:,:,:)    = C.Summary_VE{end-1}; 
    diff_unityJdg(i,:,:) = squeeze(unityJdg(i,:,2,:) - unityJdg(i,:,1,:));
    %size: 2 conditions x 2 phases x 2 modalities x 7 spatial discrepancies
    VE(i,:,:,:,:)        = C.Summary_VE{2}; 
    diff_VE(i,:,:,:)     = squeeze(VE(i,:,2,:,:) - VE(i,:,1,:,:)); %only auditory localizations are selected
end

%%
diff_VE_auditory = squeeze(diff_VE(:,:,1,:));
[rho,pval] = corr(diff_unityJdg(:),diff_VE_auditory(:));
disp([rho,pval]);
slope = polyfit(diff_unityJdg(:),diff_VE_auditory(:),1);
cMAP  = [125,203,151;89,191,182;78,135,163;79,79,119;93,46,88;...
         148,48,81;195,56,79;243,115,83;245,159,77;249,204,84;...
         237,225,121;187,216,123;210,105,30;100,100,100;200,200,200]./255;
marker = {'o','o'};%{'o','s'};
x_bds = [-1,1].*abs(max(diff_unityJdg(:))) + [-0.1,0.1];
y_bds = [-15,15];
x_ticks = [x_bds(1), x_bds(1)/2, 0, x_bds(end)/2, x_bds(end)];
y_ticks = linspace(y_bds(1), y_bds(end),5);
     
figure
for i = 1:nS
    for j = 1:lenC
        for k = 1:lenD
            scatter(diff_unityJdg(i,j,k), diff_VE_auditory(i,j,k), 100, marker{j},'filled',...
                'MarkerFaceColor', ones(1,3).*0.5, 'MarkerEdgeColor', zeros(1,3),...
                'MarkerFaceAlpha',0.5); hold on
        end
    end
    diff_unityJdg_subi = diff_unityJdg(i,:,:);
    diff_VE_auditory_subi = diff_VE_auditory(i,:,:);
end
plot(x_bds, polyval(slope,x_bds), 'lineWidth',3,'Color','r'); hold on
text(x_bds(1)+0.05, y_bds(2)-2, ['r = ',num2str(round(rho,3)),', p = <0.001'],...
    'fontSize',15); hold off; box off
xlim(x_bds); ylim(y_bds); xticks(x_ticks); yticks(y_ticks);
xlabel(sprintf('Change in the proportion \nof reporting a common cause'));
ylabel(sprintf('Change in the \nauditory localization shifts'));
set(gca,'FontSize',20);





