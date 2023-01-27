function nLL = nLL_commonLapse(lapse, alpha1, sigma1, alpha2, sigma2, D)
    %put all the sigma's and alpha's together in a vector
    alpha    = [alpha1, alpha2];
    sigma    = [sigma1, sigma2];
    numALocs = size(D{1},1); %4 auditory locations
    nLL      = 0; %initialize nLL
    for i = 1:numALocs
        pc  = normcdf(D{i}(1,:),alpha(i), sigma(i))*(1-lapse)+lapse/2;
        nLL = nLL - sum(log(pc.^D{i}(2,:).*(1-pc).^(1-D{i}(2,:))));
    end
 end   
    
    