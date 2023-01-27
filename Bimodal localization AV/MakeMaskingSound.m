function MaskNoise = MakeMaskingSound(duration)
    
%     %cut the recorded motor noise
%     [MotorNoise{4},~] = audioread('Motor Noise4.m4a',[1e5 1.5e5]); %176400
%     [MotorNoise{3},~] = audioread('Motor Noise3.m4a',[1e5 1.5e5]);
%     [MotorNoise{2},~] = audioread('Motor Noise2.m4a',[9.8e4 1.7e5]);
%     [MotorNoise{1},~] = audioread('Motor Noise1.m4a',[1.1e5 2.1e5]);
%     
%     %put them together in a single vector
%     orders = perms([1 2 3 4]);
%     length_v = length(MotorNoise{4})+length(MotorNoise{3})+...
%         length(MotorNoise{2})+length(MotorNoise{1});
%     MaskNoise = zeros(size(orders,1),length_v);
%     
%     for i = 1:size(orders,1)
%         MaskNoise(i,:) = [(MotorNoise{orders(i,1)})',3.*(MotorNoise{orders(i,2)})',...
%             6.*(MotorNoise{orders(i,3)})',9.*(MotorNoise{orders(i,4)})'];
%     end
%   
%     %cut the vector so that it's 176400
%     MaskNoise(:,(duration+1):end)=[];
      rng;
      lb = 8.163e5;
      ub = 9.462e5;
      [M,~] = audioread('Motor Noise Slow.m4a',[lb ub]);
      MotorNoise = repmat(M',[1 ceil(duration/(ub-lb))]);
      
      %choose a random starting point
      startingPoint_last = length(MotorNoise) - duration;
      startingPoint = randi(startingPoint_last,[1 1]);
      MaskNoise = MotorNoise(startingPoint:(startingPoint+duration-1));
end