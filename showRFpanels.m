function [f_panel, f_location] = showRFpanels(summary, brain_x, brain_y, stimXaxis, stimYaxis)
%[f_panel, f_location] = showRFpanels(summary, xx, yy)

[brainX, brainY] = meshgrid(brain_x,brain_y);

f_location = figure;
a_location(1)=subplot(1, 2, 1)
imagesc(summary.RF_Cx, 'alphadata',summary.mask);hold on;
%rectangle('position', [min(brain_x) min(brain_y) range(brain_x) range(brain_y)]);
plot(brainX, brainY, 'ko');
caxis(round(prctile(summary.RF_Cx(:),[1 100])));
title('Cx [deg]');
axis equal tight
mcolorbar([],0.5,'northoutside');

a_location(2)=subplot(1, 2, 2)
imagesc(summary.RF_Cy, 'alphadata',summary.mask);hold on;
%rectangle('position', [min(brain_x) min(brain_y) range(brain_x) range(brain_y)]);
plot(brainX, brainY, 'ko');
caxis(round(prctile(summary.RF_Cy(:),[1 99])));
title('Cy [deg]');
axis equal tight
mcolorbar([],0.5,'northoutside');

linkaxes(a_location);

f_panel = figure;
%xaxis = RF_insilico.noiseRF.xaxis;
%yaxis = RF_insilico.noiseRF.yaxis;
for ix = 1:numel(brain_x)
    for iy = 1:numel(brain_y)
        aa(ix,iy)=subplot_tight(numel(brain_y), numel(brain_x), ix + numel(brain_x)*(iy-1), 0.02);
        imagesc(stimXaxis, stimYaxis, squeeze(summary.RF_mean(brain_y(iy), brain_x(ix),:,:)));
        axis xy equal tight;
        hold on
        plot(summary.RF_Cx(brain_y(iy), brain_x(ix)),summary.RF_Cy(brain_y(iy), brain_x(ix)), 'ro');
        
        vline;hline;
        
        if ix>1 || iy > 1
            set(gca,'xtick',[],'ytick',[]);
        end
        if ix==1
            ylabel(brain_y(iy));
        end
        if iy==numel(brain_y)
            xlabel(brain_x(ix));
        end
        %title(['x: ' num2str(xx(ix)) ', y: ' num2str(yy(iy))])
        %caxis(prctile(all(:),[1 99])); %better not to impose same color range
    end
end
linkaxes(aa(:));
