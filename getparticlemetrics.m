% Function to generate the particle metrics from the hist files  
% Rules for automatic classification and decision tree is applied here
% These rules can be edited
% SYNTAX:  
%          getparticlemetrics(rules)   
%  eg:
%       getparticlemetrics({'pixden','ge',0.79;'dsqoverlz','le',2;...
%           'underthresh','ge',0.04;'asprat','le',1.5})

function pStats = getparticlemetrics(rules,tree)
    tic

%     Loading the appropriate trees
%     load 'particletree.mat' particletree
%     load 'particletree.mat' particletree
%     load 'noisetree.mat' noisetree
    
    pathtohistmat=pwd;
    histdetails = dir(fullfile(pathtohistmat,'*hist.mat'));



%   Extracting time details for ACE-ENA pmetrics
    holotimes  = length(histdetails);
    holonum    = length(histdetails);
    timestamp  = length(histdetails);
    holosecond = length(histdetails);
       
    for cnt = 1:length(histdetails)
        tmp = histdetails(cnt).name;
        tmp = tmp(end-34:end-9);
        yr = str2double(tmp(1:4));
        mt = str2double(tmp(6:7));
        dy = str2double(tmp(9:10));
        hr = str2double(tmp(12:13));
        mn = str2double(tmp(15:16));
        sc = str2double(tmp(18:19)) + 1e-6*str2double(tmp(21:26));
        sd = str2double(tmp(18:19));
        
        holotimes(cnt)  = hr*3600+mn*60+sc;
        holosecond(cnt) = hr*3600+mn*60+sd;
        timestamp(cnt)  = datenum(yr,mt,dy,hr,mn,sc);
        holonum(cnt)    = cnt;
    end
    
    
%     Determining the number of holograms in each second 
    noholograms(:,1)  = unique(holosecond);  
    for cnt = 1:length(noholograms(:,1))
        ind = find(noholograms(cnt,1) == holosecond);
        noholograms(cnt,2) = length(ind);
    end
    
    
%     Saving the data 
    pStats.header      = histdetails(1).name(1:end-36);
    pStats.noholograms = noholograms;
    
    %     Saving info about all processed holograms
    holoinfo   = nan(length(histdetails),2);
    holoinfo(:,1) = holonum;
    holoinfo(:,2) = timestamp;
    holoinfo(:,3) = holotimes;
    holoinfo(:,4) = holosecond;
    pStats.holoinfo = holoinfo;
    pStats.rules   = rules;
    pStats.noisetree = tree.noisetree;
    pStats.particletree = tree.particletree;
    
    
%     particledata=load(fullfile(pathtohistmat,histdetails(1).name));
%     pStats.metricnames = particledata.pd.metricnames;   
%     
%     if ~any(strcmp(pStats.metricnames,'pixden'))
%         pStats.metricnames{end+1} = 'pixden';
%     end
%     if ~any(strcmp(pStats.metricnames,'holotimes'))
%         pStats.metricnames{end+1} = 'holotimes';
%     end
%     if ~any(strcmp(pStats.metricnames,'timestamp'))
%         pStats.metricnames{end+1} = 'timestamp';
%     end
%     if ~any(strcmp(pStats.metricnames,'holonum'))
%         pStats.metricnames{end+1} = 'holonum';
%     end
%    
% %    Determining index of predefined rules 
%     
%      if exist('rules','var')
%         ruleVar = [];
%         for cnt = 1:size(size(rules,1))
%             tmp = find((strcmp(rules{cnt,1},pStats.metricnames)) == 1);
%             ruleVar = [ruleVar;tmp]; 
%         end
%      end
%             
%     
% %        Saving the metrics
%     pStats.metricmat = [];
%     for cnt=length(histdetails)-20:length(histdetails)
%         particledata=load(fullfile(pathtohistmat,histdetails(cnt).name));
%         pixden    = 4*particledata.pd.getmetric('area')./...
%             (pi*particledata.pd.getmetric('minsiz').*...
%             particledata.pd.getmetric('majsiz'));
%         metricmat = [particledata.pd.metricmat];
%         metricmat(:,end+1) = pixden;
%         metricmat(:,end+1) = ones(length(pixden),1)*holotimes(cnt);
%         metricmat(:,end+1) = ones(length(pixden),1)*timestamp(cnt);
%         metricmat(:,end+1) = ones(length(pixden),1)*holonum(cnt);
%         
% %         Applying the dynamic rules
% 
%         pStats.metricmat = [pStats.metricmat;metricmat];
%     end
%     
    
         particledata=load(fullfile(pathtohistmat,histdetails(1).name));
         metricnames = [particledata.pd.metricnames;'pixden';'holotimes';...
             'timestamp';'holosecond';'holonum'];
         for i=1:length(metricnames)
            pStats.metrics.(metricnames{i})=[];
         end
         
     pStats  = getallhistmetrics(pStats,histdetails);
      
    toc 
end

function pStats  = getallhistmetrics(pStats,histdetails)
        
        for cnt=1:length(histdetails)
            particledata=load(histdetails(cnt).name);
            metrics = particledata.pd.getmetrics;
            
%           Adding pixden rule if it dosent exist
            if ~isfield(metrics,'pixden')
                metrics.pixden = 4*metrics.area./(pi*metrics.minsiz.*metrics.majsiz);
            end
            
            
%           Adding holonum, holotimes and timestamp

            metrics.holonum   = ones((length(metrics.pixden)),1)*pStats.holoinfo(cnt,1);
            metrics.timestamp = ones((length(metrics.pixden)),1)*pStats.holoinfo(cnt,2);
            metrics.holotimes = ones((length(metrics.pixden)),1)*pStats.holoinfo(cnt,3);
            metrics.holosecond= ones((length(metrics.pixden)),1)*pStats.holoinfo(cnt,4);
           
                fnames = fieldnames(metrics);       
%               Saving the predicted particles from each hologram

                if exist('pStats','var')
                    for cnt2=1:length(fnames)
                        pStats.metrics.(fnames{cnt2}) ...
                        = cat(1,pStats.metrics.(fnames{cnt2})...
                        ,metrics.(fnames{cnt2}));
                    end
                else
                    for cnt2=1:length(fnames)
                        pStats.metrics.(fnames{cnt2})=metrics.(fnames{cnt2});
                    end
                end
                
            
            
         end  
end

