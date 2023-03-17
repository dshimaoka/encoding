function [f_panel, f_location] = showRFpanels(summary, xx, yy, stimXaxis, stimYaxis)
%[f_panel, f_location] = showRFpanels(summary, xx, yy)

f_location = figure;
subplot(1, 2, 1)
imagesc(summary.RF_Cx);hold on;
rectangle('position', [min(xx) min(yy) range(xx) range(yy)]);
caxis(prctile(summary.RF_Cx(:),[1 100]));
title('Cx [deg]');
axis equal tight
mcolorbar;

subplot(1, 2, 2)
imagesc(summary.RF_Cy);hold on;
rectangle('position', [min(xx) min(yy) range(xx) range(yy)]);
caxis(prctile(summary.RF_Cy(:),[1 99]));
title('Cy [deg]');
axis equal tight
mcolorbar;


f_panel = figure;
%xaxis = RF_insilico.noiseRF.xaxis;
%yaxis = RF_insilico.noiseRF.yaxis;
for ix = 1:numel(xx)
    for iy = 1:numel(yy)
        aa(ix,iy)=subplot_tight(numel(yy), numel(xx), ix + numel(xx)*(iy-1), 0.02);
        imagesc(stimXaxis, stimYaxis, squeeze(summary.RF_mean(yy(iy), xx(ix),:,:)));
       
        hold on
        plot(summary.RF_Cx(yy(iy), xx(ix)),summary.RF_Cy(yy(iy), xx(ix)), 'ro');
       
        if ix>1 || iy > 1
            set(gca,'xtick',[],'ytick',[]);
        end
        if ix==1
            ylabel(yy(iy));
        end
        if iy==numel(yy)
            xlabel(xx(ix));
        end
        %title(['x: ' num2str(xx(ix)) ', y: ' num2str(yy(iy))])
        %caxis(prctile(all(:),[1 99])); %better not to impose same color range
    end
end
linkaxes(aa(:));
