ID = 1;
switch ID
    case 1
        cth = 0.3;
    case 2
        cth = 0.25;
    case 3
        cth = 0.3;
end
rescaleFac = 0.1;

roiSuffix = '';
stimSuffix = '_part';
regressSuffix = '_nxv';
expInfo = getExpInfoNatMov(ID);
dataPaths = getDataPaths(expInfo,rescaleFac, roiSuffix, stimSuffix);

encodingSavePrefix = [dataPaths.encodingSavePrefix regressSuffix];


load([encodingSavePrefix '_summary'],'summary_adj');


%% show composite map (under construction)
summary_adj.mask = summary_adj.mask .* (summary_adj.correlation>cth);
[fig, signMap, signBorder, CyBorder] = showCompositeMap(summary_adj);
figure(fig);line([45 45],[55 55+getPixPerMm(rescaleFac)], 'linewidth',2);
savePaperFigure(fig,[encodingSavePrefix '_compositeMap']);

%% find connected pixels
connectedPixels = [];
connectedMatrix_obs = [];
for ii = 1:5
    switch ii
        case 1
            label_obs{ii} = 'V1';
        case 2
            label_obs{ii} = 'V2-DM+';
        case 3
            label_obs{ii} = 'DM-';
        case 4
            label_obs{ii} = 'V3'; %ID2 has split V3
        case 5
            label_obs{ii} = 'V4';             
    end
    figure;
    [connectedPixels{ii}, connectedMatrix{ii}] = findConnectedPixels(signBorder.*(summary_adj.correlation>cth));
    close;
end
%% matrix representation of V1,V3,V4
areaMatrix([1 4 5]) = connectedMatrix([1 4 5]);

%% split V2 and DM+
DMp = ((connectedMatrix{2}==1)+ (CyBorder==1)==2);
areaMatrix{2} = ((connectedMatrix{2}==1)+(DMp~=1))==2;

%% combine DM+ and DM-
areaMatrix{3} = ((connectedMatrix{3}==1)+(DMp==1));

%% labels for corresponding areas
label{1}='V1';
label{2}='V2';
label{3}='DM';
label{4} = 'V3';
label{5} = 'V4';

%% extract sigma per area
for iarea = 1:5
    theseIdx = (areaMatrix{iarea}==1 & summary_adj.correlation>cth);
    SF{iarea} = summary_adj.bestSF(theseIdx);
    sigma{iarea} = summary_adj.RF_sigma(theseIdx);
    RF_Cx{iarea} = summary_adj.RF_Cx(theseIdx);
    RF_Cy{iarea} = summary_adj.RF_Cy(theseIdx);
    eccentricity{iarea} = sqrt( RF_Cx{iarea}.^2 + RF_Cy{iarea}.^2);  
end

%
figure('position',[0 0 800 400]);
for iarea = 1:5
    subplot(121)
    plot(eccentricity{iarea}, sigma{iarea},'.');
    hold on;
    
    subplot(122)
    plot(eccentricity{iarea}, SF{iarea},'.');
    hold on
end
legend(label);
subplot(121); set(gca,'ColorOrderIndex',1);
subplot(122); set(gca,'ColorOrderIndex',1);
for iarea = 1:5
    subplot(121);
    movingAvgY = calculateMovingAverage(eccentricity{iarea}, sigma{iarea}, 10);
    plot(sort(eccentricity{iarea}), movingAvgY, 'linewidth',2);

    subplot(122);
    movingAvgY = calculateMovingAverage(eccentricity{iarea}, SF{iarea}, 10);
    plot(sort(eccentricity{iarea}), movingAvgY, 'linewidth',2);
end
subplot(121);
ylabel('sigma(deg)');xlabel('eccentricity(deg)');
subplot(122);
ylabel('SF(cpd)');xlabel('eccentricity(deg)');

screen2png([encodingSavePrefix '_eccentricity-sigma-sf']);


    
