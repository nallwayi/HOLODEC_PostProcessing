% dividing into radius bins

function output = data2bin(pd,volume)

bin = [0  10 12.5 15 17.5 20 22.5 25 30 35 40 45 50 60 70 80 90 100 150 200 250 300 350 400 450 500 2000];
% bin = [0  10 12.5 15 17.5 20 22.5 25 30 35 40 45 50 60];
% 
diameter   = pd.majdiameter;
holotimes  = round(pd.holotimes(1)):round(pd.holotimes(end));
holonum    = pd.holonum;
volume     = volume*1e-3;% Conversion of cm^3 to litres
concentration = length(holotimes);
for i=1:size(bin,2)-1
    i
    index = find(diameter > bin(i).*1e-6 & diameter < bin(i+1)*1e-6);
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
    for t=1:length(holotimes)
        
        no_holograms = max(pd.holonum(round(pd.holotimes)==holotimes(t)));
        if ~isempty(no_holograms)

            concentration(t) = sum(round(pd.holotimes(index))==holotimes(t))/no_holograms/volume/(bin(i+1)-bin(i));
        else
            concentration(t)=0;
        end
        
    end

    
%     output.(['C' num2str(ini) num2str(fin)]) = zeros(size(input.diameter,1),1);,
    output.(['C' num2str(ini) num2str(fin)]) = concentration;
    
%     num =num+numel(index);
end
output.Second=holotimes;

    for t=1:length(holotimes)
        
        no_holograms = max(pd.holonum(round(pd.holotimes)==holotimes(t)));
        if ~isempty(no_holograms)
            concentration(t) = sum(round(pd.holotimes)==holotimes(t))/no_holograms/volume;    
        else
            concentration(t)=0;
        end
    end
    
    output.concL = concentration; 
    
end