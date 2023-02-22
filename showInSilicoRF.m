function f = showInSilicoRF(RF_insilico)
% fig = showInSilicoRF(RF_insilico)

RF = RF_insilico.RF;
RF_delay = RF_insilico.RFdelay;
RF_Cx = RF_insilico.RF_Cx;
RF_Cy = RF_insilico.RF_Cy;
RF_ok = RF_insilico.RF_ok;
xaxis = RF_insilico.xaxis;
yaxis = RF_insilico.yaxis;

mRF = mean(RF,3);
crange = prctile(RF(:),[1 99]);
f = figure('position',[0 0 1900 1000]);
tiledlayout('flow');
for ii= 1:size(RF,3)
    cax=newplot;
    imagesc(xaxis, yaxis, RF(:,:,ii));
    axis equal tight;
    caxis(crange);
    if ii==1
        title(['model delay ' num2str(RF_delay(ii))]);
    else
        title(RF_delay(ii));
    end
    nexttile;
end
imagesc(xaxis, yaxis, mRF);axis equal tight;
title('mean across delays');
caxis(crange);

if RF_ok
    hold on;
    plot(RF_Cx, RF_Cy, 'ro');
end