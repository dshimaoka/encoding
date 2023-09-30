function [f_panel, f_location] = showRFpanels(summary, brain_x, brain_y, ...
    stimXaxis, stimYaxis, showXrange, showYrange, rescaleFac)
%[f_panel, f_location] = showRFpanels(summary, xx, yy)




[brainX, brainY] = meshgrid(brain_x,brain_y);

absYrange = max(abs(showYrange));

f_location = figure('position',[0 0 1000 1000]); 
a_location(1)=subplot(2, 2, 1);
imagesc(summary.RF_Cx);hold on;
%rectangle('position', [min(brain_x) min(brain_y) range(brain_x) range(brain_y)]);
plot(brainX, brainY, 'ks');
%caxis(round(prctile(summary.RF_Cx(:),[1 100])));
%caxis(showXrange);
title('Cx [deg]');
axis equal tight
caxis([-max(abs(showXrange)) max(abs(showXrange))]);
colormap(gca, pwgmap);
cb=colorbar(gca,'location','northoutside','xtick',sort([showXrange, 0]));
cb.Limits = showXrange;
addScaleBar(rescaleFac);

a_location(2)=subplot(2, 2, 2);
imagesc(summary.RF_Cy);hold on;
%rectangle('position', [min(brain_x) min(brain_y) range(brain_x) range(brain_y)]);
plot(brainX, brainY, 'ks');
%caxis(round(prctile(summary.RF_Cy(:),[1 99])));
caxis([-absYrange absYrange]);
colormap(gca, pwgmap);
title('Cy [deg]');
axis equal tight
cb=colorbar(gca,'location','northoutside','xtick',sort([showYrange, 0]));
cb.Limits = showYrange;
addScaleBar(rescaleFac);

subplot(2,2,3);
imagesc(summary.mask);
axis equal tight
cb=colorbar(gca,'location','northoutside');
title('mask')
colormap(gca,'gray');
linkaxes(a_location);

f_panel = figure;
%xaxis = RF_insilico.noiseRF.xaxis;
%yaxis = RF_insilico.noiseRF.yaxis;
for ix = 1:numel(brain_x)
    for iy = 1:numel(brain_y)
        aa(ix,iy)=subplot_tight(numel(brain_y), numel(brain_x), iy + numel(brain_y)*(ix-1), 0.02);
        thisImage = squeeze(summary.RF_mean(brain_y(iy), brain_x(ix),:,:));
        imagesc(stimXaxis, stimYaxis, thisImage);
        axis xy equal tight;
        hold on
        plot(summary.RF_Cx(brain_y(iy), brain_x(ix)),summary.RF_Cy(brain_y(iy), brain_x(ix)), 'ro');
        xlim(showXrange);
        ylim(showYrange);
        vline(0,gca,'-','w');hline(0,gca,[],'w');
        
        set(gca,'tickdir','out');
        %set(gca,'xtick',[],'ytick',[]);
        ylabel(brain_y(iy));
        xlabel(brain_x(ix));
        %title(['x: ' num2str(xx(ix)) ', y: ' num2str(yy(iy))])
        %caxis(prctile(all(:),[1 99])); %better not to impose same color range
        thisRange = [-max(abs(thisImage(:))) max(abs(thisImage(:)))];
        caxis(thisRange)
    end
end
linkaxes(aa(:));
mcolorbar([], 0.5);
colormap(gray);
