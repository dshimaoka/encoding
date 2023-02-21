function showInSilicoRF(RF_insilico)
% showInSilicoRF(RF_insilico)

RF_is = RF_insilico.RF;
RF_Cx = RF_insilico.RF_Cx;
RF_Cy = RF_insilico.RF_Cy;
RF_ok = RF_insilico.RF_ok;
xaxis = RF_inxilico.xaxis;
yaxis = RF_inxilico.yaxis;

  crange = prctile(RF_is(:),[1 99]);
    figure('position',[0 0 1900 1000]);
    tiledlayout('flow');
    for ii= 1:size(RF_is,3)
        cax=newplot;
        imagesc(xaxis, yaxis, RF_is(:,:,ii));
        axis equal tight;
        caxis(crange);
        if ii==1
            title(['model delay ' num2str(lagTimes_is(ii))]);
        else
            title(lagTimes_is(ii));
        end
        nexttile;
    end
    imagesc(xaxis, yaxis, mRF);axis equal tight;
    title('mean across delays');
    caxis(crange);
    mcolorbar(gca,.5);
    
    if RF_ok
        hold on;
        plot(RF_Cx, RF_Cy, 'ro');
    end