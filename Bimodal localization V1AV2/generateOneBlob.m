%This function takes the locations of centroids, VSinfo and ScreenInfo as inputs
%and generate a texture of clouds
function dotClouds = generateOneBlob(windowPtr,loc,VSinfo,ScreenInfo)
    loc = round(loc);

    VSinfo.blankScreen((loc(1)-floor(VSinfo.boxSize/2)):...
        (loc(1)+floor(VSinfo.boxSize/2)),(loc(2)-floor(VSinfo.boxSize/2)):...
        (loc(2)+floor(VSinfo.boxSize/2))) = VSinfo.Cloud;
    VSinfo.Screen_wBlob = VSinfo.blackScreen + VSinfo.blankScreen; 
    %reset the blankScreen
    VSinfo.blankScreen = zeros(ScreenInfo.xaxis,ScreenInfo.yaxis); 
    %Turn the matrix to texture
    dotClouds =  Screen('MakeTexture', windowPtr, VSinfo.Screen_wBlob,[],[],[],2);    
end
