function [locations, movingSteps, summedPath] = randomPath2(Location_Matrix, ExpInfo)
    %This function takes the Location Matrix, which contains starting points and endpoints
    %as inputs, chooses one midpoint so that the summed path is constant, and 
    %calculates the steps that Arduino should move relative to its previous
    %position.
    initialPosition    = Location_Matrix(:,1);
    finalPosition      = Location_Matrix(:,2);
    
    %initialize locations_relative and steps_overall
    locations          = zeros(length(initialPosition),3);
    movingSteps        = zeros(length(initialPosition),2); %2 movements
    summedPath         = zeros(1,length(initialPosition));
    getDist            = @(deg) tan(deg2rad(deg))*ExpInfo.sittingDistance;%distance in (cm) between the speaker location and the central fixation
    
    for i = 1:length(initialPosition)
        %create a position vector that excludes the original position and the final position
        position_vector = -10:2.5:10;
        position_vector(abs(position_vector-initialPosition(i))<1e-3)=[];
        position_vector(abs(position_vector-finalPosition(i))<1e-3)=[];
        
        %calculate the overall steps given those possible pairs and pick
        %the first pair which summed path is around 14
        steps_overall = abs(getDist(finalPosition(i))-getDist(position_vector))/3+ ...
            abs(getDist(position_vector)-getDist(initialPosition(i)))/3;
        index = find(abs(steps_overall-9)<3,1);  
        randMiddle = position_vector(index);
        
        %store the locations of the starting point, 2 midpoints that we
        %just picked and the endpoint in a vector and calculate the
        %relative steps Arduino should go relative to its previous location
        locations(i,:) = [initialPosition(i) randMiddle finalPosition(i)]; %in deg
        movingSteps(i,:) = (getDist(locations(i,2:end))-getDist(locations(i,1:2)))/3; %in steps
        summedPath(i) = sum(abs(movingSteps(i,:)));
    end
end
    