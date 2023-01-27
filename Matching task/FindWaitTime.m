function waitTime = FindWaitTime(steps)
    %This script plots the number of steps vs. the time it needs to finish
    %moving 
    steps = abs(steps);
    T = [0.569, 0.639, 0.650, 0.615, 0.639, 0.650, 0.639, 0.627, 0.650, 0.627;
        0.731, 0.824, 0.778, 0.848, 0.813, 0.801, 0.778, 0.813, 0.824, 0.836;
        0.766, 0.801, 0.813, 0.836, 0.813, 0.789, 0.801, 0.801, 0.824, 0.801;
        0.906, 0.918, 0.882, 0.859, 0.917, 0.894, 0.94, 0.871, 0.906, 0.871;
        0.94, 0.917, 0.952, 0.929, 0.917, 0.94, 0.917, 0.94, 0.929, 0.917;
        1.207, 1.161, 1.254, 1.184, 1.219, 1.207, 1.207, 1.207, 1.242, 1.184;
        1.521, 1.335, 1.382, 1.358, 1.358, 1.324, 1.416, 1.382, 1.37, 1.486;
        1.498, 1.463, 1.521, 1.498, 1.498, 1.544, 1.498, 1.498, 1.509, 1.509;
        1.811, 1.8, 1.823, 1.846, 1.881, 1.811, 1.869, 1.8, 1.8, 1.776;
        2.310, 2.357, 2.38, 2.368, 2.403, 2.345, 2.368, 2.415, 2.345, 2.368;
        2.717, 2.728, 2.740, 2.786, 2.74, 2.763, 2.728, 2.763, 2.752, 2.752;
        3.077, 3.111, 3.077, 3.1, 3.111,3.158, 3.123, 3.158, 3.088, 3.146];
        
    numSteps_v = [0.5, 0.75, 1, 2, 2.59, 4, 5.17, 6, 7.76,10.35,12.93,15.52];
    numSteps = repmat(numSteps_v',[1 10]);
    
    numOfSteps = 3200;
    minFullSpeedDistance = 6400;
    criticalStep = minFullSpeedDistance/numOfSteps;
    idx = find(numSteps_v > criticalStep,1);
    
    %divide the data
    T1 = T(1:(idx-1),:); 
    T2 = T(idx:end,:);
    
    numSteps1 = numSteps(1:(idx-1),:);
    numSteps2 = numSteps(idx:end,:);
    
    p1 = polyfit(numSteps1(:),T1(:),1);
    p2 = polyfit(numSteps2(:),T2(:),3);
    safetyTime = 1;
    
    waitTime = NaN(1,length(steps));
    for i = 1:length(steps)
        if steps(i) >= criticalStep
            waitTime(i) = polyval(p2,steps(i)) + safetyTime;
        else
            waitTime(i) = polyval(p1,steps(i)) + safetyTime;
        end
    end
    
%     x1 = 0:0.01:criticalStep;
%     y1 = polyval(p1,x1);
% 
%     x2 = criticalStep:0.01:max(numSteps2);
%     y2 = polyval(p2,x2);
%     
%     figure(1)
%     plot(numSteps(:),T(:),'.');
%     hold on
%     plot(x1,y1,'r-');
%     hold on
%     plot(x2,y2,'r-');
%     hold on
%     plot([criticalStep criticalStep],[0 3.5],'r--');
%     hold off
%     xlabel('Number of steps (1 step = 3 cm)','FontSize',15);
%     ylabel('Time elapsed (second)','FontSize',15);
end
