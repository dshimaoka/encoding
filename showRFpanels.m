function [f_panel, f_location] = showRFpanels(summary, brain_x, brain_y, ...
    stimXaxis, stimYaxis, showXrange, showYrange, rescaleFac, flipLR)
%[f_panel, f_location] = showRFpanels(summary, xx, yy)

if nargin<9
    flipLR=false;
end

if flipLR
    summary.RF_Cx = fliplr(summary.RF_Cx);
    summary.RF_Cy = fliplr(summary.RF_Cy);
    summary.mask = fliplr(summary.mask);
    brain_x = size(summary.mask,2) - brain_x + 1;
end

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
cb=colorbar(gca,'location','northoutside','xtick',sort(unique([showXrange, 0])));
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
cb=colorbar(gca,'location','northoutside','xtick',sort(unique([showYrange, 0])));
cb.Limits = showYrange;
addScaleBar(rescaleFac);

subplot(2,2,3);
imagesc(summary.mask);
axis equal tight
cb=colorbar(gca,'location','northoutside');
title('mask')
colormap(gca,'gray');
linkaxes(a_location);

subplot(2,2,4); % RF position in visual field
for iy = 1:numel(brain_y)
    plot(summary.RF_Cx(brain_y(iy), brain_x(:)),summary.RF_Cy(brain_y(iy), brain_x(:)), 'k-');
    hold on;
end
for ix = 1:numel(brain_x)
    plot(summary.RF_Cx(brain_y(:), brain_x(ix)),summary.RF_Cy(brain_y(:), brain_x(ix)), 'b-');
    hold on;
end

for ix = 1:numel(brain_x)
    for iy = 1:numel(brain_y)
        plot(summary.RF_Cx(brain_y(iy), brain_x(ix)),summary.RF_Cy(brain_y(iy), brain_x(ix)), 'rs');
        hold on;
    end
end
set(gca, 'xlim',showXrange,'ylim',showYrange);
axis equal;
xlim(showXrange);
ylim(showYrange);
vline(0,gca,'-','k');hline(0,gca,[],'k');
hold on; plot(showXrange(1):.5:showXrange(2),0,'o','markerfacecolor','w','color','k');
set(gca,'tickdir','out');
xlabel('azimuth [deg]'); ylabel('altitude [deg]');


%% RF in visual field
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
colormap(f_panel, gray);

