
% Function to generate the particle metrics from the hist files or 
% the output of the carft. Rules for automatic classification is applied here
% These rules can be edited
% SYNTAX:  For Carft output
%          getparticlemetrics(GUIhandles,'basic') : get basic metrics
%          getparticlemetrics(GUIhandles)         : get all metrics
%          For hist files
%          getparticlemetrics('basic')            : get basic metrics
%          getparticlemetrics()                   : get all metrics

function [nullflag,inputdata]=getparticlemetrics(inputdata,parameters)

%  Input argument validataions
if nargin <1
    inputdata=[];parameters=[];%index=[];
elseif nargin <2
    if ischar(inputdata)
        parameters = inputdata;
        inputdata=[];%index=[];
    else
        parameters=[];
    end    
% elseif nargin <3
%     if ~ischar(parameters)
%         index = parameters;parameters=[];
%     else
%         index=[];
%     end
end


% Defining all metric names
if strcmp(parameters,'basic')
    metricnames = {'zpos','xpos','ypos','majsiz','minsiz','pixden','underthresh',...
        'd2ne','nd2ne','d2nc','nd2nc','d2c','nd2c','eqsiz','dsqoverlz','d2nep','holonum',...
        'holotimes','timestamp'};
else
    metricnames={'numzs','zLIndampg','zLIndcompg','zLInd','prtclthresh',...
'prtclglblbkgndlvl','prtclnoiseamp','zpos','area','xpos','ypos','majsiz',...
'minsiz','orient','alvl','balvl','perimcx','perimcy','perimmean','perimstd',...
'perimnum','minamp','maxamp','rngamp','meanamp','stdamp','minph','maxph',...
'rngph','meanph','stdph','mincompg','maxcompg','rngcompg','meancompg',...
'stdcompg','minampg','maxampg','rngampg','meanampg','stdampg','minphg',...
'maxphg','rngphg','meanphg','stdphg','pixden','prminamp','prmaxamp','prrngamp',...
'prmeanamp','prstdamp','prminph','prmaxph','prrngph','prmeanph','prstdph',...
'prmincompg','prmaxcompg','prrngcompg','prmeancompg','prstdcompg',...
'prminampg','prmaxampg','prrngampg','prmeanampg','prstdampg','prminphg',...
'prmaxphg','prrngphg','prmeanphg','prstdphg','underthresh','asprat',...
'pampdepth','ptcharea','ptchthrarea','ptchngrps','ptchxsiz','ptchysiz',...
'phfl','d2ne','nd2ne','d2nc','nd2nc','d2c','nd2c','eqsiz','dsqoverlz','d2nep',...
'tphstdamp','tphstdampg','tphstdcompg','tphstdph','tphstdphg','tphmaxamp',...
'tphmaxampg','tphmaxcompg','tphmaxph','tphmaxphg','tphmeanamp','tphmeanampg',...
'tphmeancompg','tphmeanph','tphmeanphg','tphunderthresh','tphpampdepth','holonum',...
'holotimes','timestamp','noholograms'};
end

% Reading data from the hist files or carft output
if isempty(inputdata)
   [nullflag,inputdata] = readhistfiles(metricnames);
else
   [nullflag,inputdata] = readfromGUIhandles(inputdata,metricnames);
end


%  This function reads all the patricle metrics details from the current
%  folder into a single input file
    function [nullflag,inputdata] = readhistfiles(metricnames)
        global hologramnumber
        nullflag=0;                          
        for i=1:length(metricnames)
            inputdata.(metricnames{i})=[];
        end
%         pathtohistmat='/homes/CLOUD/nallwayi/Documents/ACEENA/RF02/RF02_05/recon/seq06';
        pathtohistmat=pwd;
        histdetails = dir(fullfile(pathtohistmat,'*hist.mat'));
        if isempty(histdetails)            
            nullflag=1;
            return
        end
        
%         Extracting time details for ACE-ENA data
        holotimes  = length(histdetails);
        holonum   = length(histdetails);
        timestamp = length(histdetails);
        noholograms = length(histdetails);
       
        for i = 1:length(histdetails)
            tmp = histdetails(i).name;
            tmp = tmp(13:end);
            yr = str2double(tmp(1:4));
            mt = str2double(tmp(6:7));
            dy = str2double(tmp(9:10));
            hr = str2double(tmp(12:13));
            mn = str2double(tmp(15:16));
            sc = str2double(tmp(18:19)) + 1e-6*str2double(tmp(21:26));
            holotimes(i) = hr*3600+mn*60+sc;
            timestamp(i) = datenum(yr,mt,dy,hr,mn,sc);
        end
        
        for i=1:length(histdetails)
%             noholograms(i) = sum(unique(holotimes)<ceil(holotimes(i))...
%                 & unique(holotimes)>floor(holotimes(i)));
            noholograms(i) = sum(second(timestamp)<=ceil(second(timestamp(i)))...
                & second(timestamp)>floor(second(timestamp(i))));
            holonum(i) = hologramnumber;
            hologramnumber = hologramnumber +1;
        end
        
        for i=1:length(histdetails)
            particledata=load(fullfile(pathtohistmat,histdetails(i).name));
            metrics = particledata.pd.getmetrics;
            
%           Adding pixden rule if it dosent exist
            if ~isfield(metrics,'pixden')
                metrics.pixden = 4*metrics.area./(pi*metrics.minsiz.*metrics.majsiz);
            end
%           Rules to remove artifacts from hist files
            ind = metrics.pixden >= 0.79 & metrics.dsqoverlz <=2 &...
                metrics.underthresh >= 0.04 & metrics.asprat<=1.5 ;
%             ind = find(metrics.dsqoverlz <=2 & metrics.underthresh >= 0.1);
            
%           Adding holonum, holotimes and timestamp

            metrics.holotimes = ones((length(metrics.pixden)),1)*holotimes(i);
            metrics.holonum   = ones((length(metrics.pixden)),1)*holonum(i);
            metrics.timestamp = ones((length(metrics.pixden)),1)*timestamp(i);
            metrics.noholograms = ones((length(metrics.pixden)),1)*noholograms(i);           

            if ~isempty(ind)
                fnames = intersect(fieldnames(metrics),metricnames);
                for j=1:length(fnames)
                    inputdata.(fnames{j}) = cat(1,inputdata.(fnames{j}),metrics.(fnames{j})(ind));
                end
            end
        end
    end

% This function is to get the details of the metics from the carft output
    function [nullflag,inputdata] = readfromGUIhandles(GUIhandles,metricnames)
        nullflag=0;
        metrics = fieldnames(GUIhandles.ps);
        metrics = intersect(metricnames,metrics);
        metrics = cat(1,metrics,{'isparticlebyhand';'isparticlebypredict'});
    
        ind1 = find(GUIhandles.ps.pixden >= 0.85 & GUIhandles.ps.dsqoverlz <=2 ...
            & GUIhandles.ps.underthresh >= 0.1 & GUIhandles.ps.isparticlebyhand == "Particle_round" );
        ind2 = find(GUIhandles.ps.pixden >= 0.85 & GUIhandles.ps.dsqoverlz <=2 ...
            & GUIhandles.ps.underthresh >= 0.1 & GUIhandles.ps.isparticlebypredict == "Particle_round" );
        ind = union(ind1,ind2);
        
        for i=1:length(metrics)
            inputdata.(metrics{i}) = GUIhandles.ps.(metrics{i})(ind);
        end       
    end
end