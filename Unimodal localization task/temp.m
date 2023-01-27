C = load('Unimodal_localization_sub9.mat', 'Unimodal_localization_data');
Adata = C.Unimodal_localization_data{end}.data;
Vdata = C.Unimodal_localization_data{end-1}.data;
Aloc_deg = C.Unimodal_localization_data{end}.Distance; 
Vloc_deg = C.Unimodal_localization_data{end-1}.initialDistance; 

colorMap = colormap('lines');
x_max = max(abs(Adata(2,:))); x_bds = [-x_max-5, x_max + 5];
y_bds = [0,20]; x_ticks = [x_bds(1), Vloc_deg, x_bds(end)];
y_ticks = 0:10:20;

figure
subplot(1,2,1)
addBackground(x_bds, y_bds, x_ticks, y_ticks)
for i = 1:length(Aloc_deg)
    idx = abs(Adata(1,:) - Aloc_deg(i)) < 1e-3;
    histogram(Adata(2,idx), -x_max:1:x_max,'FaceColor',colorMap(i,:),'FaceAlpha',...
        0.5, 'EdgeColor','none'); hold on
    plot([Vloc_deg(i), Vloc_deg(i)], y_bds, 'Color', colorMap(i,:),...
        'lineWidth', 2, 'lineStyle', '-'); hold on;
end
hold off; box off; xticks(Vloc_deg); xlim(x_bds); yticks(y_ticks);
xlabel('Auditory localization (dva)');
ylim(y_bds); ylabel('Counts'); set(gca,'FontSize',15);

subplot(1,2,2)
addBackground(x_bds, y_bds, x_ticks, y_ticks)
for i = 1:length(Vloc_deg)
    idx = abs(Vdata(1,:) - Vloc_deg(i)) < 1e-1;
    histogram(Vdata(3,idx), -x_max:1:x_max, 'FaceColor',colorMap(i,:),...
        'FaceAlpha',0.5, 'EdgeColor','none'); hold on
    plot([Vloc_deg(i), Vloc_deg(i)], y_bds, 'Color', colorMap(i,:),...
        'lineWidth', 2, 'lineStyle', '-'); hold on;
end
hold off; box off; xticks(Vloc_deg); xlim(x_bds); yticks(y_ticks);
xlabel('Visual localization (dva)'); 
ylim(y_bds); ylabel('Counts'); set(gca,'FontSize',15);

set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 0.7, 0.3]);
set(gcf,'PaperUnits','centimeters','PaperSize',[30 8]);
%saveas(gcf, 'UnimodalLocResps_example', 'pdf'); 

