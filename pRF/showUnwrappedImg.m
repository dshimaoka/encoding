function showUnwrappedImg(x,y,img,t)

if ~exist('t','var')
    t = (1:size(img,2))/60;
end

if  length(x)==1
    x = 1:x;
end

if length(y)==1
    y =1:y;
end


clf

tic
for frameNum = 1:length(t)
    
    image(x,y,reshape(img(:,frameNum),length(y),length(x)));
    axis equal
    axis tight
    colormap(gray(256));
    drawnow
    while toc<t(frameNum)
    end
end



