% Function to generate the PDF of the data from the ict file data



function [avgrad,pdf,concL,dr,variance] = pdfgenerator(input,timerange,radiusrange)

%  Extracting the data

string  = strsplit(extractAfter(input.header{end},"C:"),",");
length  = size(string,2);

if extractAfter(string(end),"-") == "inf"
    length = length -1;
end
avgrad  = zeros(length,1);
dr      = zeros(length,1);
concL   = zeros(length,1);
pdf     = zeros(length,1);
variance = zeros(length,1);
 for i=1:length
    tempstr = erase(string{i},"C:");
    startpos = extractBefore(tempstr,"-");
    endpos   = extractAfter(tempstr,"-");
    
    
    avgrad(i) = (str2double(startpos)+str2double(endpos))/4; 
    dr(i)     = (str2double(endpos)-str2double(startpos)) ;
    
    if rem(str2double(endpos),1)
        endpos = num2str(str2double(endpos)*10);
    end
    if rem(str2double(startpos),1) 
        startpos = num2str(str2double(startpos)*10);
    end
    
    % Selecting the data from the given time interval
    starttime = str2double(extractBefore(timerange,"-"));
    endtime   = str2double(extractAfter(timerange,"-"));
    
    ind1      = find(input.Second == starttime);
    ind2      = find(input.Second == endtime);
    ref       = strcat("C",startpos,endpos);
    data      = input.(ref)(ind1:ind2);
    index     = ~isnan(data);
    concL(i)  = mean(data(index))*dr(i);
    pdf(i)    = mean(data(index));
    variance(i)= var(data(index));
    
 end
    
    pdf       = pdf./sum(concL);
    
    % Trimming the data to match the radius range
    startrad  = str2double(extractBefore(radiusrange,"-"));
    endrad    = str2double(extractAfter(radiusrange,"-"));
    index     = find(avgrad >startrad & avgrad < endrad);
    avgrad    = avgrad(index);
    dr        = dr(index);
    pdf       = pdf(index);%./sum(pdf(index));
    concL     = concL(index);
    variance  = variance(index);
    
 
end
