function updatedDistance = FindNextDistance(AudInfo,Condition,TrialNumber,...
    inputDistance,inputResponse,updatedResponse)
    %the input distance is not absolute value
    %1-"LEFT"-up-2-"RIGHT"-down, A starts from the LEFT side of the V
    if rem(Condition,2)==1 
        %check whether the participants get the first "LEFT" response yet.
        %If not, the difficulty level will stay the same.
        if TrialNumber == 1 %when this is the first trial
            %if the subject thinks A is on the LEFT side of V (which is correct)
            if updatedResponse == -1 
                updatedDistance = inputDistance + AudInfo.StepSizes(1); %make it harder
            else
                updatedDistance = inputDistance;
            end
        else
            %determine the step size by using the function findPair (find the 
            %number of two consecutive "RIGHT")
            numPairOfRight = findPair([inputResponse updatedResponse],[1 1 -1]);
            if numPairOfRight == 0
                stepsize = AudInfo.StepSizes(1);
            elseif numPairOfRight == 1
                stepsize = AudInfo.StepSizes(2);
            else
                stepsize = AudInfo.StepSizes(3);
            end 

            %Find the first time the subject thinks the A is on the left
            %side of the V
            if isempty(find(fliplr(inputResponse)==-1,1))
                index_mostRecentLeft = TrialNumber;
            else
                index_mostRecentLeft = find(fliplr(inputResponse)==-1,1);
            end

            %check whether there are 2 "RIGHT" in a row in the inputResponse
            if rem(index_mostRecentLeft,2) == 0 && updatedResponse == 1 %Even number of "RIGHT" responses in a row
                updatedDistance = inputDistance - stepsize; %make it easier
            elseif rem(index_mostRecentLeft,2) == 1 && updatedResponse == 1
                updatedDistance = inputDistance;
            else
                updatedDistance = inputDistance + stepsize; %make it harder
            end
        end
    %1-"RIGHT"-down-2-"LEFT"-up, A starts from the RIGHT side of the V    
    else 
        if TrialNumber == 1 %when this is the first trial
            if updatedResponse == 1
                updatedDistance = inputDistance - AudInfo.StepSizes(1);
            else
                updatedDistance = inputDistance;
            end
        else  
            %determine the step size by using the function findPair (find the 
            %number of two consecutive "LEFT")
            numPairOfRight = findPair([inputResponse updatedResponse],[-1 -1 1]);
            if numPairOfRight == 0
                stepsize = AudInfo.StepSizes(1);
            elseif numPairOfRight == 1
                stepsize = AudInfo.StepSizes(2);
            else
                stepsize = AudInfo.StepSizes(3);
            end            

            %Find the first time the subject thinks the target is on the right
            %side of the standard location
            if isempty(find(fliplr(inputResponse)==1,1))
                index_mostRecentRight = TrialNumber;
            else
                index_mostRecentRight = find(fliplr(inputResponse)==1,1);
            end

            %check whether there are 2 "LEFT" in a row in the inputResponse
            if rem(index_mostRecentRight,2) == 0 && updatedResponse == -1 %Even number of "LEFT" responses in a row
                updatedDistance = inputDistance + stepsize; %maker it easier
            elseif rem(index_mostRecentRight,2) == 1 && updatedResponse == -1
                updatedDistance = inputDistance;
            else
                updatedDistance = inputDistance - stepsize; %make it harder
            end
        end
    end
end