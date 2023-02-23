function f = showInSilicoRF(RF_insilico, trange)
% fig = showInSilicoRF(RF_insilico, trange)

if nargin < 2
    trange = [-inf inf];
end

RF = RF_insilico.RF;
RF_delay = RF_insilico.RFdelay;
RF_Cx = RF_insilico.RF_Cx;
RF_Cy = RF_insilico.RF_Cy;
RF_ok = RF_insilico.RF_ok;
xaxis = RF_insilico.xaxis;
yaxis = RF_insilico.yaxis;

tidx = find(RF_insilico.RFdelay>=trange(1) & RF_insilico.RFdelay<=trange(2));
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