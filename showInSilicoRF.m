function f = showInSilicoRF(RF_insilico, trange)
% fig = showInSilicoRF(RF_insilico, trange)

if nargin < 2
    trange = [-inf inf];
end

RF = RF_insilico.noiseRF.RF;
RF_delay = RF_insilico.noiseRF.RFdelay;
RF_Cx = RF_insilico.noiseRF.RF_Cx;
RF_Cy = RF_insilico.noiseRF.RF_Cy;
RF_ok = RF_insilico.noiseRF.RF_ok;
xaxis = RF_insilico.noiseRF.xaxis;
yaxis = RF_insilico.noiseRF.yaxis;

tidx = find(RF_delay>=trange(1) & RF_delay<=trange(2));
mRF = squeeze(mean(RF(:,:,tidx),3));

crange = prctile(abs(RF(:)),[99]);
f = figure('position',[0 0 1900 1000]);
tiledlayout('flow');
for ii= 1:size(RF,3)
    cax=newplot;
    imagesc(xaxis, yaxis, RF(:,:,ii));
    axis equal tight;
    caxis([-crange crange]);
    if ii==1
        title(['model delay ' num2str(RF_delay(ii))]);
    else
        title(RF_delay(ii));
    end
    nexttile;
end
imagesc(xaxis, yaxis, mRF);axis equal tight;
title('mean across delays');
caxis([-crange crange]);
colorbar;

if RF_ok
    hold on;
    plot(RF_Cx, RF_Cy, 'ro');
end