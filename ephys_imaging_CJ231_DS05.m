%% assumptions
% probe is straight, not bent in the brain
% insertion point is where the last RF is observed

dataDir = '\\ad.monash.edu\home\User006\dshi0006\Documents\MATLAB\2023ImagingPaper\';

%product of CJ231_sparsenoise_figures2.m:
load(fullfile(dataDir, 'neuropix_tmp\2022\11\30\CJ231.noisegrid.095454_rf.mat'),...
    'ycoords','xcoords','Idx_all','fitresult','x1D','y1D');

%product of alignEphys2Image.m
load(fullfile(dataDir,'ephys2Image_CJ231_pen1.mat'));
%load('C:\Users\dshi0006\Dropbox\2023OsakaSapporo\my talks Osaka Sapporo\ephys2Image_CJ231_pen1.mat');

%% load encoding model result
%load('C:\Users\dshi0006\Dropbox\2023 imaging paper\2023MarchDataclub\encoding_2022_11_30_16_resize10_nxv_summary.mat','summary','summary_adj');
%load('\\storage.erc.monash.edu.au\shares\MNHS-dshi0006\Massive\processed\2022\11\30\resize10\encoding_2022_11_30_16_resize10_nxv_summary.mat','summary','summary_adj');
load(fullfile(dataDir, 'encoding_2022_11_30_16_resize10_part_nxv_summary.mat'),'summary','summary_adj');


pixPermm = getPixPerMm(1);
xrange = [-5 5];
yrange = [-5 5];
%Idx_RF = Idx_all(1:30:150);
Idx_RF = Idx_all(1:30:151);
Idx_RF(2) = 55;

rescaleFac = 0.10;

%% ephys2Image_CJ224_pen2.mat processed by alignEphys2Image.m
%insertion point in inputImage_registered
x0 = 272; %[pix]
y0 = 240; %[pix]

%base of the shank (1100um from tip)
x1=302; %[pix]
y1=90;%124; %[pix]


%% CJ224.noisegrid.161346
D2 = 1e-3 * 6700;%[mm] distance recorded in labArchives
%D2 = 1e-3 * 5980; %where last decent RF was observed
D1 = 11 - D2; %[mm]


%
B = sqrt((x0-x1)^2+(y0-y1)^2); %distance from insertion point to shank base, projected to brain surface [pix]
A = D2/D1*B;

xb = -A/sqrt(1+(y1-y0)^2/(x1-x0)^2) + x0; %tip position in image ????

E = 1e-3*ycoords; %[mm] %distance from tip %[mm]

%xdash = A/D2*(E-D2)+A; %NG!
%x = (x0-xb)/A*(xdash)+xb;

x= (x0-xb)*((E-D2)/D2+1) + xb; %xpos of channel in the image [pix]
y = (y1-y0)/(x1-x0)*(x-x0) + y0; %y-pos of channel in the image [pix]


mask = imresize(summary_adj.mask==1, size(baseImage));
RF_Cy = imresize(summary_adj.RF_Cy, size(baseImage));
RF_Cx = imresize(summary_adj.RF_Cx, size(baseImage));
corr = imresize(summary_adj.correlation, size(baseImage));


figure('position',[0 0 1000 1000]);
originalSize = size(inputImage_registered);
x_ori = 1:originalSize(2);
y_ori = 1:originalSize(1);
imagesc(x_ori, y_ori, inputImage_registered);%.*mask); 
axis equal tight off;
hold on
colormap(gray);
addScaleBar(1);
c=parula(numel(Idx_all));
plot(x(Idx_all),y(Idx_all),'o','color',[.7 .7 .7]);
s=scatter(x(Idx_all),y(Idx_all),15,c,'filled');
plot(x(Idx_RF),y(Idx_RF),'o','color','r');
rectangle('position',[200 250 100 250],'edgecolor','k');
xlim([1 originalSize(2)]); ylim([1 originalSize(1)]);
savePaperFigure(gcf,'ephys_imaging_superimposed');


%% get areal borders (from showCompositeMap.m)
signMap = imgaussfilt(summary_adj.vfs,1.5); %seems necessary for getVisualBorder
threshold = .6;%th for binalizing vfs low > less space between borders
openfac = 1;
closefac = 1;
[signMapThreshold, signBorder] = getVisualBorder(signMap, threshold, openfac, closefac);
Cy = interpNanImages(summary_adj.RF_Cy);
CyFilt = imgaussfilt(Cy,1.5);


%% superimposed map on 0.1ResizeFac
figure('position',[0 0 1000 1000]);
newSize = size(summary_adj.RF_Cy);
xResized = linspace(1, originalSize(2), newSize(2));
yResized = linspace(1, originalSize(1), newSize(1));

for ii=1%:2
    %subplot(1,2,ii);
    switch ii
        case 1
            imagesc(xResized, yResized,summary_adj.RF_Cy);
            hold on;
            contour(xResized, yResized, signBorder,[0 0],'k','linewidth',1);
            [h]=contour(xResized, yResized, CyFilt, [0 0], 'k','linewidth',1);
            
            colormap(gca, pwgmap);mcolorbar(gca,.5,'northoutside');
            caxis([-5 5]);
        case 2
            imagesc(xResized, yResized,summary_adj.vfs);
            hold on;
            
            cmap = customcolormap(linspace(0,1,3), ...
                [0 0 1; 0 0 0; 1 0 0]);
            colormap(gca, cmap);mcolorbar(gca,.5,'northoutside');
            caxis([-1 1]);
    end
    whitebg('k');
    c=parula(numel(Idx_all));
    
    plot(x(Idx_all),y(Idx_all),'o','color',[.7 .7 .7]);
    s=scatter(x(Idx_all),y(Idx_all),15,c,'filled');
    plot(x(Idx_RF),y(Idx_RF),'o','color','r');
    rectangle('position',[200 250 100 250],'edgecolor','k');
    axis equal tight off;
    xlim([1 originalSize(2)]); ylim([1 originalSize(1)]);
end

savePaperFigure(gcf,'ephys_imaging_superimposed_s');





%% RF position according to imaging
RFy_i = [];
RFx_i = [];
for ich = 1:384
    RFy_i(ich,1) = RF_Cy(round(y(ich)),round(x(ich)));
    RFx_i(ich,1) = RF_Cx(round(y(ich)),round(x(ich)));
end


%% RF position accordign to ephys
figure;
%foveal representation
fvY = 52;
fvX = 39;

RFx = fitresult(:,3) - summary.RF_Cx(fvY,fvX);
RFy = fitresult(:,4) + summary.RF_Cy(fvY,fvX);
 

%% RF positions ephys vs imaging 
% plot(Idx_all, RFy(Idx_all),'.');
% hold on;
% plot(Idx_all, RFy_i(Idx_all),'.');

%plot(RFy_i(Idx_all),RFy(Idx_all),'o'); 
figure;
plot(RFy_i(Idx_all),RFy(Idx_all),'-o','color',[.7 .7 .7]);hold on;
plot(RFy_i(Idx_RF),RFy(Idx_RF),'o','color','r');hold on;
scatter(RFy_i(Idx_all),RFy(Idx_all),25,c,'filled'); 
corrVal = corr2(RFy_i(Idx_all), RFy(Idx_all));
axis square; 
xlabel('imaging [deg]');
ylabel('ephys [deg]');
axis padded
set(gca,'tickdir','out');
title(sprintf('r=%.2f',corrVal));
savePaperFigure(gcf,'ephys_imaging_scatter');



%% RF mapping ephys (from CJ231_sparsenoise_figures2.m)
load('\\ad.monash.edu\home\User006\dshi0006\Documents\MATLAB\2023ImagingPaper\neuropix_tmp\2022\11\30\CJ231.noisegrid.095454_rf.mat');
r1D = reshape(r2D, size(r2D,1)*size(r2D,2), []);
meanResp = reshape(mean(r1D),1,1,[]);
stdResp = reshape(std(r1D),1,1,[]);
r2Dz = (r2D - meanResp)./stdResp;

nChPerPanel = numel(Idx_RF);

figure('position',[0 0 1900 1000]);
for ii = 1:nChPerPanel %a(jj):min(a(jj)+nChPerPanel, 384)%Ids_RF(1:30)
    subplot(1,nChPerPanel,ii);
    
    kk = Idx_RF(ii);
    imagesc(x1D- summary.RF_Cx(fvY,fvX),y1D+ summary.RF_Cy(fvY,fvX),r2Dz(:,:,kk));
    axis equal tight;
    xlim(xrange);ylim(yrange);
    hold on
    plot(RFx(kk),RFy(kk),'ro');
    hline(0,gca,'--');vline(0,gca,'-');
    set(gca,'tickdir','out');
    tname = sprintf('%d a/b:%.2f \n resnorm:%.4f', ...
        ycoords(kk), fitresult(kk,1)/fitresult(kk,5), nresnorm(kk));
    title(tname);
    axis xy
    caxis([-10 10]);
end
mcolorbar(gca,.5);
colormap(flipud(gray));
savePaperFigure(gcf,'ephys_imaging_RF');



%% brain surface pictures
figure;
subplot(121);
imagesc(baseImage);axis equal tight off; colormap(gray);
line(492-[45 45],600-[45 45+pixPermm], 'linewidth',2,'color','w');
subplot(122);
imagesc(inputImage_registered);axis equal tight off; colormap(gray);
hold on;
plot([x(1) x0],[y(1) y0],'-','color','r');
line(492-[45 45],600-[45 45+pixPermm], 'linewidth',2,'color','k');
savePaperFigure(gcf,'ephys_imaging_brainImages');




