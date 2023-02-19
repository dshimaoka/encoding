function err = fitGauss(RF,S,resp,x,y)

predResp = S*Gauss(RF,x,y,1);

tmp = corrcoef(resp,predResp);
err = -tmp(1,2);

