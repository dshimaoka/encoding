function [aparam] = getAnalysisParam(ID)
%created from alignVFS.m

switch ID
    case 1
        aparam.stimSuffix = '_part';
        aparam.corrth = 0.26;
        aparam.showXrange = [-7 0]; aparam.showYrange = [-3.8 3.8];
        aparam.flipLR = false;
        aparam.brainPix(1).brain_y = 29:40;
        aparam.brainPix(1).brain_x = 16;
        aparam.brainPix(2).brain_y = [29];% 34;%30;
        aparam.brainPix(2).brain_x = 6:16;
    case 2
        aparam.stimSuffix = '_part';
        aparam.corrth = 0.24;
        aparam.showXrange = [-10 1]; aparam.showYrange = [-7.5 7.5];
        aparam.flipLR = false;
        aparam.brainPix(1).brain_y = 22:40;
        aparam.brainPix(1).brain_x = 23;
        aparam.brainPix(2).brain_y = 25;
        aparam.brainPix(2).brain_x = 9:23;
    case 3
        aparam.stimSuffix = '_part';
        aparam.corrth=0.29;
        aparam.showXrange = [-7 0]; aparam.showYrange = [-3.8 3.8];
        aparam.flipLR = false;
    case 8
        aparam.stimSuffix = '_square30';
        aparam.corrth=0.3;
        aparam.showXrange = [-10 1]; aparam.showYrange = [-7.5 7.5];
        aparam.flipLR = false;
    case 9
        aparam.stimSuffix = '_square28';
        aparam.corrth=0.33;
        aparam.showXrange = [-10 1]; aparam.showYrange = [-7.5 7.5];
        aparam.flipLR = true;
end
