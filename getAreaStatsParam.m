function asparam = getAreaStatsParam
% asparam = getAreaStatsParam
% parameters commonly used across experiments for areal characterization

asparam.label{1} = 'V1';
asparam.label{2} = 'V2';
asparam.label{3} = 'DM';
asparam.label{4} = 'V3';
asparam.label{5} = 'V4';
asparam.label{6} = 'DI';

asparam.ebins = 0:8;
asparam.spdlim = [0.1 15];
asparam.selectPixelTh = 6;
asparam.eccTh = 3; %[deg]
asparam.eccLim = [0 8];

