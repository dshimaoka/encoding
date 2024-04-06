function [fvY, fvX] = getFoveaPix(ID, rescaleFac)
%[fvY, fvX] = getFoveaPix(ID, rescaleFac)
switch ID
    case 1
        fvY = round(52*rescaleFac/0.1); %50
        fvX = round(40*rescaleFac/0.1);
    case 2
        fvY = round(49*rescaleFac/0.1); %52
        fvX = round(44*rescaleFac/0.1); %41
    case 3
        fvY = round(50*rescaleFac/0.1); %56
        fvX = round(39*rescaleFac/0.1); %38
    case 8
        fvY = round(36*rescaleFac/0.1); %42
        fvX = round(39*rescaleFac/0.1); 
        corr_th = 0.2;
    case 9
        fvY = round(45*rescaleFac/0.1);%50
        fvX = round(7*rescaleFac/0.1);
        corr_th = 0.2;
   
end