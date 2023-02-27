function  par_save(file_name, varargin)
%-----------inputs-----------:
%file_name; name of .matfile to be saved
%varargin{}:  variables needed to be  saved to the matfile named in file_name. 
ct ={};%to be converted to structure as struct(field1,value1,...,fieldN,valueN)
fi=1;% initial field index
vi=2;%   =   value index
for i=1:numel(varargin)
    
    ct{fi} = inputname(i+1);%+1 since the 1st input is filename
    
    ct{vi} =varargin{i};
    fi=fi+2;
    vi=vi+2;
end
s = struct(ct{:}) ;% put inputs in a structure with fields that has same name as the inputs
save(file_name,'-v7.3', '-struct','s','-nocompression')
end