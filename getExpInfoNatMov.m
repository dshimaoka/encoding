function expInfo = getExpInfoNatMov(ID)

switch ID
    case 1
        expInfo.subject = 'CJ224';
        expInfo.date = '20221004';
        expInfo.nsName = 'CJ224.runPassiveMovies.033059';
        expInfo.expID = 19;
    case 2
        expInfo.nsName = 'CJ231.runPassiveMovies.010848';
        expInfo.expID = 16;
        expInfo.subject = 'CJ231';
        expInfo.date = '20221130';
    case 3
        expInfo.nsName = 'CJ229.runPassiveMovies.024114';
        expInfo.expID = 21;
        expInfo.subject = 'CJ229';
        expInfo.date = '20221101';
%         expInfo.RFxlim = [-inf 5];
%         expInfo.RFylim = [];
    case 4
        expInfo.nsName = 'CJ220.runPassiveMovies.021959';
        expInfo.expID = 17;
        expInfo.subject = 'CJ220';
        expInfo.date = '20220816';
    case 5
        expInfo.nsName = 'CJ234.runPassiveMovies.225232';
        expInfo.expID = 12;
        expInfo.subject = 'CJ234';
        expInfo.date = '20230329';
    case 6
         expInfo.nsName = 'CJ235.runPassiveMovies.071727';
        expInfo.expID = 22;
        expInfo.subject = 'CJ235';
        expInfo.date = '20230405';
    case 7
         expInfo.nsName = 'CJ235.runPassivemovies.223724';
        expInfo.expID = 13;
        expInfo.subject = 'CJ235';
        expInfo.date = '20230404';
end
