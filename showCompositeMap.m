function [fig, signMap, signBorder, CyBorder, mask] = ...
    showCompositeMap(summary_adj, corrth, showXrange, showYrange, rescaleFac)
% [fig, signMap, signBorder, CyBorder, mask] = ...
%     showCompositeMap(summary_adj, corrth, showXrange, showYrange, rescaleFac)
% creates maps of 
%   preferred altitude
%   preferred azimuth
%   areal boundary based on visual field sign
%   brain image

if nargin < 2
    corrth = 0.25;
end
%for JNSS meeting
%mask = (summary_adj.correlation > corrth) .* summary_adj.mask;

mask_c = imgaussfilt(summary_adj.correlation)>corrth;
se = strel('disk',10);
%mask = (1-imclose(1-mask_c,se)).*summary_adj.mask;
mask_c2 = imopen(mask_c,se).*summary_adj.mask;

% Find connected components
cc = bwconncomp((mask_c2==1));

% Compute properties of connected components
stats = regionprops(cc, 'Area');

% Find the index of the largest connected component
[~, idx] = max([stats.Area]);

% Create a new binary image with only the largest connected component
newmask = false(size(mask_c2));
newmask(cc.PixelIdxList{idx}) = true;

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
fig = figure('position',round([0 0 4000 2000]/getPixPerMm(rescaleFac)));
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
            %image = signBorder;
            %cmap = customcolormap(linspace(0,1,3), ...
            %    [0 0 1; 0 0 0; 1 0 0]);
            image = summary_adj.thisROI;
            cmap = gray;
    end
    
    subplot(1,4,ii);
    if ~flipLR
        imagesc(image, 'alphadata', newmask);
    else
        imagesc(fliplr(image), 'alphadata', fliplr(newmask));
    end
    if ii==1
        title('Cx [deg]');
        caxis([-max(abs(showXrange)) max(abs(showXrange))]);
        colormap(gca, cmap);
        cb=colorbar(gca,'location','northoutside','xtick',sort(unique([showXrange, 0])));
        cb.Limits = showXrange;cb.TickDirection = 'out';
    elseif ii == 2
        title('Cy [deg]');
        caxis([-max(abs(showYrange)) max(abs(showYrange))]);
        colormap(gca, cmap);
        cb=colorbar(gca,'location','northoutside','xtick',sort(unique([showYrange, 0])));
        cb.Limits = showYrange;cb.TickDirection = 'out';

    elseif ii==3
        title('VFS');
        caxis([-1 1]);
        colormap(gca, cmap);
        cb=colorbar(gca,'location','northoutside','xtick',[-1 0 1]);
        cb.TickDirection = 'out';
    elseif ii==4
        colormap(gca,cmap);
        cb=colorbar(gca,'location','northoutside');
        cb.TickDirection = 'out';
    end
    
    hold on; 
    if nargin>=5
        for ib=1:length(brainPix)
            brain_x = brainPix(ib).brain_x;
            if flipLR
                brain_x = size(newmask,2) - brain_x + 1;
            end
            brain_y = brainPix(ib).brain_y;
            [brainX, brainY] = meshgrid(brain_x,brain_y);
            plot(brainX, brainY, 's');
        end
    end
    if ~flipLR
        contour(signBorder,[-0.1 0.1],'w','linewidth',2);
        [h]=contour(CyFilt, [0 0], 'w','linewidth',1);
    elseif flipLR
        contour(fliplr(signBorder),[-0.1 0.1],'w','linewidth',2);
        [h]=contour(fliplr(CyFilt), [0 0], 'w','linewidth',1);
    end        
    % Extract data points from contour lines
    xMarkers = [];
    yMarkers = [];
    % Loop through each contour line
    for i = 2:length(h)
        % Extract data points from contour lines
        xMarkers = [xMarkers, h(1,i)]; % Add NaN to separate lines
        yMarkers = [yMarkers, h(2,i)];
    end
    
    % interleave markers
    %xMarkers = xMarkers(1:3:end);
    %yMarkers = yMarkers(1:3:end);
    
    [X,Y] = meshgrid(1:size(newmask,2), 1:size(newmask,1));
    % Keep only the points within the binary mask
    insideMask = inpolygon(xMarkers, yMarkers, X(newmask), Y(newmask));
    
    
    % Add markers
    plot(xMarkers(insideMask), yMarkers(insideMask), 'ko', 'MarkerSize', 3, 'LineWidth', 1,...
        'markerfacecolor','w');
    
    CyBorder = (CyFilt>=0);
    addScaleBar(rescaleFac);
    axis equal tight ij;
    set(gca,'xtick',[],'ytick',[]);
    whitebg(gcf,'w');
    
end
