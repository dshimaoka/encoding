function out = Gauss(RF,x,y,dims)
%out = Gauss(RF,x,y)

if ~isfield(RF,'theta')
    RF.theta = 0;
end

if ~isfield(RF,'a')
    RF.a = 1;
end

a = cos(RF.theta)^2/2/RF.sig^2 + sin(RF.theta)^2/2/(RF.sig*RF.a)^2;
b = -sin(2*RF.theta)/4/RF.sig^2 + sin(2*RF.theta)/4/(RF.sig*RF.a)^2 ;
c = sin(RF.theta)^2/2/RF.sig^2 + cos(RF.theta)^2/2/(RF.sig*RF.a)^2;

out = exp( - (a*(x-RF.center(1)).^2 + 2*b*(x-RF.center(1)).*(y-RF.center(2)) + c*(y-RF.center(2)).^2)) ;







if exist('dims','var')
    out= out(:);
end

