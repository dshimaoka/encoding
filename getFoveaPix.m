function [fvY, fvX] = getFoveaPix(ID, rescaleFac)
%[fvY, fvX] = getFoveaPix(ID, rescaleFac)
switch ID
    case 1
        fvY = round(52*rescaleFac/0.1); %50
        fvX = round(40*rescaleFac/0.1);
    case 2
        fvY = round(52*rescaleFac/0.1);
        fvX = round(41*rescaleFac/0.1); %41
    case 3
        fvY = round(50*rescaleFac/0.1); %56
        fvX = round(39*rescaleFac/0.1); %38
    case 4
        fvY = round(33*rescaleFac/0.1);
        fvX = round(37*rescaleFac/0.1);
    case 5 %TOBE FIXED
        fvY = round(33*rescaleFac/0.1);
        fvX = round(37*rescaleFac/0.1);
    case 6 %TOBE FIXED
        fvY = round(45*rescaleFac/0.1);
        fvX = round(40*rescaleFac/0.1);
    case 7 %TOBE FIXED
        fvY = round(40*rescaleFac/0.1);
        fvX = round(42*rescaleFac/0.1);
    case 8
        fvY = round(42*rescaleFac/0.1); %36
        fvX = round(39*rescaleFac/0.1); 
        corr_th = 0.2;
    case 9
        fvY = round(45*rescaleFac/0.1);%50
        fvX = round(7*rescaleFac/0.1);
        corr_th = 0.2;
        
end