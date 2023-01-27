function numPair = findPair(history, number)
    length_h = length(history);
    length_n = length(number);
    test_trials = length_h - (length_n-1);
    numPair = 0;
    for i = 1:test_trials
        if isequal(history(i:(i+length_n-1)),number)
            numPair = numPair + 1;
        end
    end
end