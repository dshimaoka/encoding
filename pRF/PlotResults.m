function PlotResults(RFx,RFy,RFsig,r,xVoxRange,yVoxRange,nCols,nRows,R, cothresh)
%PlotResults
%load('CompiledData', 'nCols','nRows','R');
%%
% Generate the 'anatomy' image - the mean of the optical imaging data over
% time.
anat = mean(R,1);
anat = reshape(anat,nRows,nCols);
anat  = 128*(anat-min(anat(:)))/(max(anat(:))-min(anat(:)));

%%

%load('Results', 'r','RFx','RFy','RFsig','xVoxRange','yVoxRange');

if ~exist('xVoxRange','var')
    xVoxRange = 1:size(anat,2);
end

if ~exist('yVoxRange','var')
    yVoxRange = 1:size(anat,1);
end

anat = anat(yVoxRange,xVoxRange);

ang = 180*atan2(RFy,RFx)/pi;
rad = sqrt(RFx.^2+RFy.^2)*180/pi;
% cothresh  = 0.33;
%%
figure(1)
showMap(anat,rad,r>cothresh);

title('Eccentricity');


%%
figure(2)
showMap(anat,ang,r>cothresh);
title('Polar Angle');

%%

figure(3)
showMap(anat,RFsig*180/pi,r>cothresh);
title('Size');


%%

figure(4)
showMap(anat,RFx*180/pi,r>cothresh,[0 130]);
title('Azimuth (x)');

%%

figure(5)
showMap(anat,RFy*180/pi,r>cothresh,[-40 60]);
title('Elevation (y)');


%%
% 

tile(2,3);%does not exist 9/9/15
%tilefigs;
%mergefigs(1:5);