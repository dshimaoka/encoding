function [fig, signMap, signBorder, CyBorder, mask] = ...
    showCompositeMap(summary_adj, corrth, showXrange, showYrange, rescaleFac)
% [fig, signMap, signBorder] = showCompositeMap(summary_adj)
% under construction

% mask = zeros(size(summary_adj.thisROI));
% mask(~isnan(summary_adj.RF_Cx))=1;

% mask = summary_adj.correlation/prctile(summary_adj.correlation(:),99);
% mask(mask>1)=1;

if nargin < 2
    corrth = 0.25;
end
%for JNSS meeting
%mask = (summary_adj.correlation > corrth) .* summary_adj.mask;

mask_c = imgaussfilt(summary_adj.correlation)>corrth;
se = strel('disk',10);
%mask = (1-imclose(1-mask_c,se)).*summary_adj.mask;
mask = imopen(mask_c,se).*summary_adj.mask;

%imagesc(summary_adj.RF_Cy, 'alphadata',mask)
% Cymax=prctile(abs(summary_adj.RF_Cy(:)),[99]);
% caxis([-Cymax Cymax]);
% title('Cy [deg]');
% axis equal tight
% bkrmap = customcolormap(linspace(0,1,3), ...
%    [0 1 0; 0 0 0; 1 0 0]);
% colormap(gca, bkrmap);
% mcolorbar(gca,.5,'southoutside');


%% vertical meridian
hold on;
Cy = interpNanImages(summary_adj.RF_Cy);
CyFilt = imgaussfilt(Cy,1.5);
%contour(CyFilt, [0 0], '--w','linewidth',2);


%% areal boundary according to the mouse algorithm
% signMap = summary_adj.vfs;
fig = figure('position',[0 0 1000 1000]);
signMap = imgaussfilt(summary_adj.vfs,1.5); %seems necessary for getVisualBorder
threshold = .6;%th for binalizing vfs low > less space between borders
openfac = 1;
closefac = 1;
[signMapThreshold, signBorder] = getVisualBorder(signMap, threshold, openfac, closefac);
%subplot(211);imagesc(signMap);
%subplot(212);imagesc(im_final);


for ii = 1:4
    switch ii
        case 1
            image = summary_adj.RF_Cx;
            cmap = pwgmap;
        case 2
            image = summary_adj.RF_Cy;
            %cmap = customcolormap(linspace(0,1,3), ...
            %    [1 0 0; 0 0 0; 0 1 0]);
            cmap = pwgmap;
        case 3
              image = summary_adj.vfs;
            cmap = customcolormap(linspace(0,1,3), ...
                [0 0 1; 0 0 0; 1 0 0]);
        case 4
            image = signBorder;
            cmap = customcolormap(linspace(0,1,3), ...
                [0 0 1; 0 0 0; 1 0 0]);
    end
    subplot(2,2,ii);
    imagesc(image, 'alphadata', mask);
    if ii==1
        title('Cx [deg]');
        caxis([-max(abs(showXrange)) max(abs(showXrange))]);
        colormap(gca, cmap);
        cb=colorbar(gca,'location','northoutside','xtick',sort(unique([showXrange, 0])));
        cb.Limits = showXrange;
    elseif ii == 2
        title('Cy [deg]');
        caxis([-max(abs(showYrange)) max(abs(showYrange))]);
        colormap(gca, cmap);
        cb=colorbar(gca,'location','northoutside','xtick',sort(unique([showYrange, 0])));
        cb.Limits = showYrange;

    elseif ii==3 || ii==4
        title('VFS');
        caxis([-1 1]);
        colormap(gca, cmap);
        cb=colorbar(gca,'location','northoutside','xtick',[-1 0 1]);
    end
    
    hold on; 
    contour(signBorder,[-0.1 0.1],'w','linewidth',2);
    contour(CyFilt, [0 0], ':w','linewidth',2);
    CyBorder = (CyFilt>=0);
    addScaleBar(rescaleFac);
    axis equal tight ij;
    whitebg(gcf,'w');
    
end
