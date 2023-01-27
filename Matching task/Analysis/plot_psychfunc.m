function binnedD = plot_psychfunc(D, Expt, Plt)
%specify plotting info
cnorm    = @(t,p) normcdf(t,p(1),p(2)).*(1-p(3))+p(3)/2;
binnedD  = cell(1,Expt.testLocations);
x_bds    = [min(Plt.x) max(Plt.x)]; 
y_bds    = [0,1]; %probability
x_ticks  = [-12,0,12];
y_ticks  = y_bds(1):0.25:y_bds(end);
cMAP     = [255,127,127;153,0,0]./255;

figure
addBackground(x_bds, y_bds, [x_bds(1), x_ticks, x_bds(end)], y_ticks);
for i = 1:Expt.testLocations
    %plot the fitted curve
    h(i) = plot(Plt.x,cnorm(Plt.x,[D.estimatedP(i*2:(i*2+1)), D.estimatedP(1)]),...
        '-','linewidth',2,'Color',cMAP(i,:)); hold on
    if Plt.bool_plt_CI
        patch([Plt.x, fliplr(Plt.x)], [Plt.CI{i}(1,:), fliplr(Plt.CI{i}(2,:))],...
            cMAP(i,:), 'FaceAlpha', 0.1,'EdgeColor',cMAP(i,:),'EdgeAlpha', 0.2); hold on
    end
end

for i = 1:Expt.testLocations
    %bin data
    binnedD{i}   = BinData(Plt.numBins, x_bds, D.sorted{i});
    %calculate the weight
    weight_trial = binnedD{i}(2,:)./sum(binnedD{i}(2,:));
    dotSize      = 2e3.*weight_trial;
    %calculate the probability of saying the V is to the right of the A 
    p_A_right    = binnedD{i}(3,:)./binnedD{i}(2,:);
    %plot the data point
    scatter(binnedD{i}(1,:),p_A_right,dotSize, 'MarkerEdgeColor',cMAP(i,:),...
        'MarkerFaceColor',cMAP(i,:), 'MarkerEdgeAlpha', 0.9,...
        'MarkerFaceAlpha', 0.5); hold on
end
text(x_bds(1)+0.25,y_bds(end)-0.025,Plt.subjI,'fontSize',15); hold off; box off
lgd = legend([h(1), h(2)],{'-12','12'},'Location','southeast','FontSize',15);
title_lgd = get(lgd,'Title');set(title_lgd,'String','Visual location (dva)');
legend boxoff; xlim(x_bds); ylim(y_bds);  xlabel('Location of auditory test stimulus (dva)');
ylabel(sprintf(['The probability of reporting \nthe auditory stimulus to the right\n',...
    'of a visual stimulus']));
set(gca,'FontSize',15, 'YTick', y_ticks, 'XTick', x_ticks);
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 0.5, 0.4]);
if Plt.bool_save == 1
    set(gcf,'PaperUnits','centimeters','PaperSize',[35 15]);
    if Plt.bool_plt_CI
        saveas(gcf, ['PsychometricFunctions_sub', num2str(Expt.subjID),'_CI'], 'pdf'); 
    else
        saveas(gcf, ['PsychometricFunctions_sub', num2str(Expt.subjID)], 'pdf'); 
    end
end

%Add background (similar to Seaborn)
function addBackground(x_bd, y_bd, x_ticks, y_ticks)
patch([x_bd(1), x_bd(2), x_bd(2), x_bd(1)], [y_bd(1), y_bd(1), y_bd(2), y_bd(2)],...
    [234,234,242]./255, 'EdgeAlpha',0); hold on
if length(xticks) >=3 
    for i = 2:length(x_ticks)-1
        plot([x_ticks(i), x_ticks(i)], [y_bd(1), y_bd(2)], 'Color',...
            [1,1,1],'lineWidth', 0.5); hold on;
    end
end
if length(yticks) >= 3
    for j = 2:length(y_ticks)-1
        plot([x_bd(1), x_bd(2)],[y_ticks(j), y_ticks(j)], 'Color',...
            [1,1,1],'lineWidth', 0.5); hold on;
    end
end

function GroupedData = BinData(numBins,bounds,data)
%This function takes the number of bins, the boundaries and the data as
%inputs and generates binned data
%1st row: stimulus intensity
%2nd row: number of total trials tested at that level of intensity
%3rd row: number of trials judging the C is to the right of the S

%calculate the mid value of each interval
scalePoints = linspace(bounds(1),bounds(2),numBins+1);
Bins = (scalePoints(2:end)+scalePoints(1:end-1))./2;
%tol is the distance between the interval boundaries and the mid value
%of that bin
tol = diff(Bins(1:2))/2;

%initialize the matrix GroupedData
GroupedData = zeros(3,length(Bins));
%the first row is the stimulus intensity (the mid value of each interval)
GroupedData(1,:) = Bins;
for l = 1:length(Bins)
    %find the indices that correspond to the data falling into the bin
    indices_fallingOnTheBin = find(abs(data(1,:)-Bins(l))<=tol);
    %sum the number of those data
    GroupedData(2,l) = length(indices_fallingOnTheBin);
    %Given those trials, how many are "right" responses
    GroupedData(3,l) = sum(data(2,indices_fallingOnTheBin));
end     
%if no trial falls on a bin, delete that column so when plotting it,
%it wouldn't make any error
GroupedData(:,GroupedData(2,:)==0) = [];
