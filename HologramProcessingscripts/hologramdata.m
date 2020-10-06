function hologramdata=hologramdata(pd,volume)

starttime=datetime('now');

diameter = pd.majdiameter;
holotimes = pd.holotimes;

Second = unique(holotimes);
hologramno = 1:length(Second);
concentration  =  length(Second);
volume     = volume*1e-3;% Conversion of cm^3 to litres


hologramdata.Second = Second;
hologramdata.hologramno = hologramno;
bin = [0  10 12.5 15 17.5 20 22.5 25 30 35 40 45 50 60 70 80 90 100 150 200 250 300 350 400 450 500 2000];


for i=1:length(bin)-1
    i
    
    index = diameter > bin(i).*1e-6 & diameter < bin(i+1)*1e-6;
    if rem(bin(i),1)~=0
        ini = bin(i)*10;
        fin = bin(i+1);
    elseif rem(bin(i+1),1)~= 0
        ini = bin(i);
        fin = bin(i+1)*10;
    else
        ini = bin(i);
        fin = bin(i+1);
    end
    for j=1:length(Second) 
        concentration(j) = numel(find(holotimes(index)==Second(j)))/volume/(bin(i+1)-bin(i));
    end
%         diameter(index)=[];
%         holotimes(index)=[];

    
     hologramdata.(['C' num2str(ini) num2str(fin)]) = concentration;  
end

holotimes = pd.holotimes;


    for j=1:length(Second) 
        concentration(j) = numel(find(holotimes==Second(j)))/volume;
    end
   hologramdata.concL =concentration;
   endtime=datetime('now');
   
   endtime-starttime
end