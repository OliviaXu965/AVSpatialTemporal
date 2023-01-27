function [locations_relative,summedPath] = randomPath2(Location_Matrix)
    %This function takes the Location Matrix, which contains starting points and endpoints
    %as inputs, chooses one midpoint so that the summed path is constant, and 
    %calculates the steps that Arduino should move relative to its previous
    %position.
    initialPosition = Location_Matrix(:,1);
    finalPosition = Location_Matrix(:,2);
    
    %initialize locations_relative and steps_overall
    locations_relative = zeros(length(initialPosition),2); %2 movements
    summedPath = zeros(1,length(initialPosition));
    
    for i = 1:length(initialPosition)
        %create a position vector that excludes the original position and the final position
        %position_vector = [-7.76, -5.54, -3.33, -1.11, 1.11, 3.33, 5.54, 7.76];
        position_vector = [-5.54, -3.33, -1.11, 1.11, 3.33, 5.54];
        position_vector(abs(position_vector-initialPosition(i))<1e-3)=[];
        position_vector(abs(position_vector-finalPosition(i))<1e-3)=[];
        
        %generate all the combinations of midpoints
        combinations_overall = nchoosek(1:length(position_vector),1); %nchoosek generates all the possible combinations, but the order also matters.
        randMiddleStep_overall = position_vector(combinations_overall); %randMiddleStep_overall stores the corresponding locations of all the possible pairs of the 2 midpoints
        
        %calculate the overall steps given those possible pairs and pick
        %the first pair which summed path is around 14
        steps_overall = abs(finalPosition(i)-randMiddleStep_overall)+ ...
            abs(randMiddleStep_overall-initialPosition(i));
        index = find(abs(steps_overall-8)<2,1);  
        randMiddleStep = randMiddleStep_overall(index);
        
        %store the locations of the starting point, 2 midpoints that we
        %just picked and the endpoint in a vector and calculate the
        %relative steps Arduino should go relative to its previous location
        locations = [initialPosition(i) randMiddleStep finalPosition(i)]; 
        locations_relative(i,:) = locations(2:end)-locations(1:2);
        summedPath(i) = sum(abs(locations_relative(i,:)));
    end
end
    