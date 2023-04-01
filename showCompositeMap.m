function fig = showCompositeMap(summary_adj)
% under construction

% mask = zeros(size(summary_adj.thisROI));
% mask(~isnan(summary_adj.RF_Cx))=1;

% mask = summary_adj.correlation/prctile(summary_adj.correlation(:),99);
% mask(mask>1)=1;

mask = (summary_adj.correlation > 0.2) .* summary_adj.mask;

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
fig = figure;
signMap = imgaussfilt(summary_adj.vfs,1.5); %seems necessary for getVisualBorder
threshold = .6;%th for binalizing vfs low > less space between borders
openfac = 1;
closefac = 1;
[signMapThreshold, im_final] = getVisualBorder(signMap, threshold, openfac, closefac);
%subplot(211);imagesc(signMap);
%subplot(212);imagesc(im_final);

for ii = 1:4
    switch ii
        case 1
            image = summary_adj.RF_Cx;
            cmap = parula;
        case 2
            image = summary_adj.RF_Cy;
            cmap = customcolormap(linspace(0,1,3), ...
                [1 0 0; 0 0 0; 0 1 0]);
        case 3
              image = summary_adj.vfs;
            cmap = customcolormap(linspace(0,1,3), ...
                [0 0 1; 0 0 0; 1 0 0]);
        case 4
            image = im_final;
            cmap = customcolormap(linspace(0,1,3), ...
                [0 0 1; 0 0 0; 1 0 0]);
    end
    subplot(2,2,ii);
    imagesc(image, 'alphadata', mask);
    
    colormap(gca, cmap);
    hold on; 
    contour(im_final,[-0.1 0.1],'w','linewidth',2);
    contour(CyFilt, [0 0], ':w','linewidth',2);
    axis equal tight ij;
    whitebg(gcf,'w');
end
