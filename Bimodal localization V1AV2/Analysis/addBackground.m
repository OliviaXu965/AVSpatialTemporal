%==========================================================================
%                         HELPING FUNCTIONS
%==========================================================================
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
end