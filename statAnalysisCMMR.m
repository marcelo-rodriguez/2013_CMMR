function intStruct = statAnalysisCMMR()
%Statistical Analysis CMMR

%arguments
country ='China';

analysisType = 1;
%              1 'all' 
%              2 'a>b'
%              3 'b>a'
%              4 'eq'

levelField = false;

%TOOLS FOR DEBUGGING 

% corpus(s).code
% context=[[melMat(i-2,2) melMat(i-1,2) melMat(i,2) melMat(i+1,2)]; ... 
%     [melMat(i-2,1) melMat(i-1,1) melMat(i,1) melMat(i+1,1)]]


%clear all; clc;
%corpus=kern2nm;
load('corpusChinaGermany.mat');

if(strcmpi(country,'germany'))
    corpus=corpusGermany;
    clear corpusGermany corpusChina
else
    corpus=corpusChina;
    clear corpusGermany corpusChina
end

if(levelField==true)
    if(strcmpi(country,'china'))
        rand_sample_idxs=randsample(1417,1268);
        corpus=corpus(rand_sample_idxs);
    end
end


%---------------
%   ALGORITHM
%---------------

%init counters
mel=1;
cc=1;
paMTpb_c=1;
pbMTpa_c=1;
pbEQpa_c=1;
bPeak=1;
pls_c=1;
filter_context_c=1;

%for each song in the corpus:
for s=1:length(corpus)
    
    %----------------------------
    %  ANALYSIS 0: CHECKING INPUT
    %----------------------------
    %extract phrase length per songsum
    if(size(corpus(s).phraseBoundaries,1)>2)
        phrasesPerSong(s,1)= size(corpus(s).phraseBoundaries,1);
    else
        phrasesPerSong(s,1)= size(corpus(s).phraseBoundaries,1)+1;
    end
    phrasesPerSong(s,2)= min(corpus(s).phraseBoundaries(:,3));
    phrasesPerSong(s,3)= max(corpus(s).phraseBoundaries(:,3));
    
    for pl=1:size(corpus(s).phraseBoundaries(:,3),1)
        store_pls(pls_c)=corpus(s).phraseBoundaries(pl,3);
        pls_c=pls_c+1;
    end
    
    melodySizes(s)=size(corpus(s).melodyNMAT,1);
    
    
    %----------------------------
    %  PROCESS CORPUS
    %----------------------------
    
    %extract phrase locators matrix and melodyNMAT matrix
    pabMat=corpus(s).pabMat;
    melMat=corpus(s).melodyNMAT;
    
    %init struct giving country name of corpus
    intStruct.country=country;
    
    %CHECK PROCEDURE---1b%
    numPhrasePairsInSong(s)=size(corpus(s).phraseBoundaries,1)-1;
    if(size(pabMat,1)~=numPhrasePairsInSong)
        display(['PabMAT INCONSISTENT, is: ' num2str(size(pabMat,1)) ...
                 ' and should be: ' num2str(numPhrasePairsInSong)...
                 ' ,for song: ' num2str(s)])
    end
    if(all(pabMat(1,:)==[1 1 1 1 1]))
        display(['all ones ' num2str(size(pabMat,1)) ...
                 ' ,for song: ' num2str(s)])
    end
    %CHECK PROCEDURE---1e%

    
    if(size(pabMat,2)>3)
        
        
        %clear phrases that don't meet the minum length needed to test
        idx=find(pabMat(:,4)<2);
        if(~isempty(idx))
            pabMat(idx,:)=[];
        end

        idx=find(pabMat(:,5)<3);
        if(~isempty(idx))
            pabMat(idx,:)=[];
        end
        
    if(~isempty(pabMat))
        %compute intervals and store intMat
        for j=1:size(pabMat,1)  
            pa_len=pabMat(j,4);
            pb_len=pabMat(j,5);
            i=pabMat(j,3);
            

            %pitch
            pJab = abs(melMat(i,2)-melMat(i-1,2));
            pCa  = abs(melMat(i-2,2) - melMat(i-1,2));
            pCb  = abs(melMat(i,2)-melMat(i+1,2));
            %pCu  = mean([pCa pCb]);
            
            %duration
            ttlDur=sum([melMat(i-2,1) melMat(i-1,1) melMat(i,1)]);
            dJab = melMat(i-1,1)/ttlDur;
            dCa  = melMat(i-2,1)/ttlDur;
            dCb  = melMat(i,1)/ttlDur;
            %dCu  = mean([dCa dCb]);
            
            %storing  NORMAL CASE          
            if(pJab<20)%filter
                
                %pitch
                intStruct.intMat(cc,1,1)= pJab;
                intStruct.intMat(cc,2,1)= pCa;
                intStruct.intMat(cc,3,1)= pCb;
                if(pJab>pCa && pJab>pCb)
                    intStruct.intMat(cc,4,1)= 1;
                else
                    intStruct.intMat(cc,4,1)= 0;
                end
                intStruct.intMat(cc,5,1)= pa_len;
                
                %duration
                intStruct.intMat(cc,1,2)= dJab;
                intStruct.intMat(cc,2,2)= dCa;
                intStruct.intMat(cc,3,2)= dCb;
                if(dJab>dCa && dJab>dCb)
                    intStruct.intMat(cc,4,2)= 1;
                else
                    intStruct.intMat(cc,4,2)= 0;
                end
                intStruct.intMat(cc,5,2)= pa_len;
                
                %increment counter
                cc=cc+1;
            end
            
            %storing  pha > phb          
            if(pa_len > pb_len && pJab<20)%filter
                
                %pitch
                intStruct.intMat_paMT_pb(paMTpb_c,1,1)= pJab;
                intStruct.intMat_paMT_pb(paMTpb_c,2,1)= pCa;
                intStruct.intMat_paMT_pb(paMTpb_c,3,1)= pCb;
                if(pJab>pCa && pJab>pCb)
                    intStruct.intMat_paMT_pb(paMTpb_c,4,1)= 1;
                else
                    intStruct.intMat_paMT_pb(paMTpb_c,4,1)= 0;
                end
                intStruct.intMat_paMT_pb(paMTpb_c,5,1)= pa_len;
                
                %duration
                intStruct.intMat_paMT_pb(paMTpb_c,1,2)= dJab;
                intStruct.intMat_paMT_pb(paMTpb_c,2,2)= dCa;
                intStruct.intMat_paMT_pb(paMTpb_c,3,2)= dCb;
                if(dJab>dCa && dJab>dCb)
                    intStruct.intMat_paMT_pb(paMTpb_c,4,2)= 1;
                else
                    intStruct.intMat_paMT_pb(paMTpb_c,4,2)= 0;
                end
                intStruct.intMat_paMT_pb(paMTpb_c,5,2)= pa_len;
                
                %increment counter
                paMTpb_c=paMTpb_c+1;
            end  
            
            %storing  phb > pha          
            if(pb_len > pa_len && pJab<20)%filter
                
                %pitch
                intStruct.intMat_pbMT_pa(pbMTpa_c,1,1)= pJab;
                intStruct.intMat_pbMT_pa(pbMTpa_c,2,1)= pCa;
                intStruct.intMat_pbMT_pa(pbMTpa_c,3,1)= pCb;
                if(pJab>pCa && pJab>pCb)
                    intStruct.intMat_pbMT_pa(pbMTpa_c,4,1)= 1;
                else
                    intStruct.intMat_pbMT_pa(pbMTpa_c,4,1)= 0;
                end
                intStruct.intMat_pbMT_pa(pbMTpa_c,5,1)= pa_len;
                
                %duration
                intStruct.intMat_pbMT_pa(pbMTpa_c,1,2)= dJab;
                intStruct.intMat_pbMT_pa(pbMTpa_c,2,2)= dCa;
                intStruct.intMat_pbMT_pa(pbMTpa_c,3,2)= dCb;
                if(dJab>dCa && dJab>dCb)
                    intStruct.intMat_pbMT_pa(pbMTpa_c,4,2)= 1;
                else
                    intStruct.intMat_pbMT_pa(pbMTpa_c,4,2)= 0;
                end
                intStruct.intMat_pbMT_pa(pbMTpa_c,5,2)= pa_len;
                
                %increment counter
                pbMTpa_c=pbMTpa_c+1;
            end  
            
            %storing  pha == pha          
            if(pb_len == pa_len && pJab<20)%filter
                
                %pitch
                intStruct.intMat_pbEQ_pa(pbEQpa_c,1,1)= pJab;
                intStruct.intMat_pbEQ_pa(pbEQpa_c,2,1)= pCa;
                intStruct.intMat_pbEQ_pa(pbEQpa_c,3,1)= pCb;
                if(pJab>pCa && pJab>pCb)
                    intStruct.intMat_pbEQ_pa(pbEQpa_c,4,1)= 1;
                else
                    intStruct.intMat_pbEQ_pa(pbEQpa_c,4,1)= 0;
                end
                intStruct.intMat_pbEQ_pa(pbEQpa_c,5,1)= pa_len;
                
                %duration
                intStruct.intMat_pbEQ_pa(pbEQpa_c,1,2)= dJab;
                intStruct.intMat_pbEQ_pa(pbEQpa_c,2,2)= dCa;
                intStruct.intMat_pbEQ_pa(pbEQpa_c,3,2)= dCb;
                if(dJab>dCa && dJab>dCb)
                    intStruct.intMat_pbEQ_pa(pbEQpa_c,4,2)= 1;
                else
                    intStruct.intMat_pbEQ_pa(pbEQpa_c,4,2)= 0;
                end
                intStruct.intMat_pbEQ_pa(pbEQpa_c,5,2)= pa_len;
                
                %increment counter
                pbEQpa_c=pbEQpa_c+1;
            end  
        end


        %compute how many Jab are peaks in each song
        %extract Jab peaks in current song
        peaksPit=length(find(intStruct.intMat(bPeak:end,4,1)));
        peaksDur=length(find(intStruct.intMat(bPeak:end,4,2)));
        %update index
        bPeak=cc;
        %compute total of joins in current song
        ttlPeaks=size(pabMat,1);
        %compute percentage and store
        intStruct.pPeaksPerSong(mel,1)= peaksPit/ttlPeaks;
        intStruct.dPeaksPerSong(mel,1)= peaksDur/ttlPeaks;



        mel=mel+1;
        
    end
    end
end

%------------------------
%  STATISTICAL ANALYSIS
%------------------------

switch analysisType
    case 1 
        toTest=intStruct.intMat;
        plotTitle= ' | case: All ph_a_b';
    case 2
        toTest=intStruct.intMat_paMT_pb;
        plotTitle= ' | case: ph_a > p_b';
    case 3
        toTest=intStruct.intMat_pbMT_pa;
        plotTitle= ' | case: ph_a < p_b';
    case 4
        toTest=intStruct.intMat_pbEQ_pa;
        plotTitle= ' | case: ph_b = p_a';
    otherwise
        error('select an analysistype')
end


%------------------------
%  ANALYSIS 1: GLOBAL
%------------------------
intStruct.songs=[mel-1 s];
intStruct.songSizes=[min(melodySizes) max(melodySizes)];
intStruct.songSizesHist=hist(melodySizes, max(melodySizes));
intStruct.numPhrases= sum(phrasesPerSong(:,1));
intStruct.numPhrasePairs=[size(intStruct.intMat,1) ...
                          sum(numPhrasePairsInSong)];
intStruct.averagePhrasesPerSong=[mean(phrasesPerSong(:,1)) ...
                                 std(phrasesPerSong(:,1))];
intStruct.phraseLengthRange=[min(phrasesPerSong(:,1)) ...
                             max(phrasesPerSong(:,1))];
                         
intStruct.phraseLengthHist=hist(store_pls, max(phrasesPerSong(:,1)));

%%combined over all corpus
ttl_peaks = size(intStruct.intMat,1);

%BOTH agree -> best that we can expect
tst=intStruct.intMat;
tst(tst(:,4,1)~=tst(:,4,2),:,:) = [];
tst(tst(:,4,1)==0,:,:) = [];
bothPeak=size(tst,1);
%BOTH dis-agree -> jump phrases
tst=intStruct.intMat;
tst(tst(:,4,1)~=tst(:,4,2),:,:) = [];
tst(tst(:,4,1)==1,:,:) = [];
bothNoPeak=size(tst,1);
%pitch YES - duration NO
tst=intStruct.intMat;
tst(tst(:,4,1)==tst(:,4,2),:,:) = [];
tst(tst(:,4,1)==0 & tst(:,4,2)==1,:,:) = [];
pitchYesDurNO=size(tst,1);
%pitch NO - duration YES
tst=intStruct.intMat;
tst(tst(:,4,1)==tst(:,4,2),:,:) = [];
tst(tst(:,4,1)==1 & tst(:,4,2)==0,:,:) = [];
pitchNODurYES=size(tst,1);
%pitch YES
tst=intStruct.intMat;
peaksPit = length(find(tst(:,4,1)));
pitchYES = peaksPit;
%duration YES
tst=intStruct.intMat;
peaksDur = length(find(tst(:,4,2)));
durYES   = peaksDur;

%STORE
intStruct.corpusStats.ttl_num_phrasepairs      = ttl_peaks;
intStruct.corpusStats.pdYESPeaks_percent(1)    = bothPeak;
intStruct.corpusStats.pdYESPeaks_percent(2)    = bothPeak/ttl_peaks;
intStruct.corpusStats.pdNoPeaks_percent(1)     = bothNoPeak;
intStruct.corpusStats.pdNoPeaks_percent(2)     = bothNoPeak/ttl_peaks;
intStruct.corpusStats.pYesdNO_percent(1)       = pitchYesDurNO;
intStruct.corpusStats.pYesdNO_percent(2)       = pitchYesDurNO/ttl_peaks;
intStruct.corpusStats.pNOdYES_percent(1)       = pitchNODurYES;
intStruct.corpusStats.pNOdYES_percent(2)       = pitchNODurYES/ttl_peaks;
intStruct.corpusStats.pYES_percent(1)          = pitchYES;
intStruct.corpusStats.pYES_percent(2)          = pitchYES/ttl_peaks;
intStruct.corpusStats.dYES_percent(1)           = durYES;
intStruct.corpusStats.dYES_percent(2)           = durYES/ttl_peaks;


%compute percentage of cases where peaks are in song
intStruct.perSongStats.numSongs  = (mel-1);
%pitch peak
pAllSong=length(find(intStruct.pPeaksPerSong==1));
intStruct.perSongStats.p_YESallSong(1)  = pAllSong;
intStruct.perSongStats.p_YESallSong(2)  = pAllSong/(mel-1);
%pitch no peak
pNoneInSong=length(find(intStruct.pPeaksPerSong==0));
intStruct.perSongStats.p_NoneInSong(1)  = pNoneInSong;
intStruct.perSongStats.p_NoneInSong(2)  = pNoneInSong/(mel-1);
%duration peak
dAllSong=length(find(intStruct.dPeaksPerSong==1));
intStruct.perSongStats.d_PeaksAllSong(1)  = dAllSong;
intStruct.perSongStats.d_PeaksAllSong(2)  = dAllSong/(mel-1);
%duration no peak
dNoneInSong=length(find(intStruct.dPeaksPerSong==0));
intStruct.perSongStats.d_NoneInSong(1)    = dNoneInSong;
intStruct.perSongStats.d_NoneInSong(2)    = dNoneInSong/(mel-1);

%------------------------
%  ANALYSIS 2: BOXPLOTS
%------------------------

% figure;
% subplot(2,1,1)
% boxplot(toTest(:,1:3,1))
% title('Pitch')
% 
% 
% subplot(2,1,2)
% boxplot(toTest(:,1:3,2))
% title('Duration')


    
fh = figure;
subplot(2,1,1)
cases=['J(pab)';'C(pa) ';'C(pb) '];
boxplot(toTest(:,1:3,1),cases,'colors','k','jitter',1,'medianstyle',...
              'line','whisker',2,'symbol',' ');
set(gca,'xtick',1:size(cases,1),'xticklabel',cases); 
title(['Corpus: ' country ' ' plotTitle ' | Pitch Analysis'])
ylabel('API (Semitones)')

subplot(2,1,2)
cases=['J(pab)';'C(pa) ';'C(pb) '];
boxplot(toTest(:,1:3,2),cases,'colors','k','jitter',1,'medianstyle',... 
              'line','whisker',2,'symbol',' ');
set(gca,'xtick',1:size(cases,1),'xticklabel',cases); 
title(['Corpus: ' country ' ' plotTitle ' | Duration Analysis'])
xlabel('Join Interval and Context Intervals')
ylabel('N IOI')
    
%for rotation
%    hB=findobj(fh,'Type','hggroup');
%    hL=findobj(hB,'Type','text');
%    set(hL,'Rotation',30); 
%    set(gca,'xtick',1:size(cases,1)); 

print -depsc2 figplot1.eps

%------------------------
%  ANALYSIS 3: means
%------------------------

%  PITCH
Lpa=unique(toTest(:,5,1));
statsPitch=zeros(length(Lpa),4);
cntr=1;
for i=1:length(Lpa)
    group           = Lpa(i);
    idxs            = find(toTest(:,5,1)==group); 
    tmp             = toTest(idxs,:,1);
    [h1,p,ci,stats]  = ttest2(tmp(:,1),tmp(:,2));
    [h2,p,ci,stats]  = ttest2(tmp(:,1),tmp(:,3));
    
    
    if(h1==1 && h2==1)
        statsPitch(cntr,1) = mean(tmp(:,1));
        statsPitch(cntr,2) = mean(tmp(:,2));
        statsPitch(cntr,3) = mean(tmp(:,3));
        statsPitch(cntr,4) = group;
        cntr=cntr+1;
    end
end
statsPitch(statsPitch(:,1)==0,:) = [];
statsPitch(statsPitch(:,1)>6,:) = [];

figure;
hold on; 
plot([1:size(statsPitch,1)],statsPitch(:,2),'*b','MarkerSize',9);
plot([1:size(statsPitch,1)],statsPitch(:,3),'xr','MarkerSize',9);
plot([1:size(statsPitch,1)],statsPitch(:,1),'ok','MarkerSize',9);
lsline
hold off; 
%axis([0 length(statsPitch(:,4))+0.3 1 max(max(statsPitch(:,1:3)))])
axis([0 length(statsPitch(:,4))+0.3 1.5 5])
parts = strread(num2str(statsPitch(:,4)'),'%s','delimiter',' ');
set(gca,'XTick',[1:length(statsPitch(:,4))])
set(gca,'XTickLabel',parts)


%legend('C(pha)','C(phb)','regression lines','regrJ(phab)','regrC(phb)','regrC(pha)')
%title(['Corpus: ' country ' ' plotTitle ' | Pitch Analysis'])
%xlabel('Length of the First Phrase in Phrase-Pair ph_a_b')
xlabel('Length of ph_a')
%ylabel('Average Pitch Interval Size (Semitones)')
ylabel(' PI ')

print -depsc2 figplot2.eps

% DURATION
Lpa=unique(toTest(:,5,2));
statsDur=zeros(length(Lpa),4);
cntr=1;
for i=1:length(Lpa)
    group           = Lpa(i);
    idxs            = find(toTest(:,5,2)==group); 
    tmp             = toTest(idxs,:,2);
    [h1,p,ci,stats]  = ttest2(tmp(:,1),tmp(:,2));
    [h2,p,ci,stats]  = ttest2(tmp(:,1),tmp(:,3));
    
    
    if(h1==1 && h2==1)
        statsDur(cntr,1) = mean(tmp(:,1));
        statsDur(cntr,2) = mean(tmp(:,2));
        statsDur(cntr,3) = mean(tmp(:,3));
        statsDur(cntr,4) = group;
        cntr=cntr+1;
    end
end
statsDur(statsDur(:,1)==0,:) = [];
%statsDur(statsDur(:,1)>6,:) = [];

figure;
hold on; 
plot([1:size(statsDur,1)],statsDur(:,2),'*b','MarkerSize',9);
plot([1:size(statsDur,1)],statsDur(:,3),'xr','MarkerSize',9);
plot([1:size(statsDur,1)],statsDur(:,1),'ok','MarkerSize',9);
lsline
hold off; 
%axis([0 length(statsDur(:,4))+0.3 0 max(max(statsDur(:,1:3)))+0.05])
axis([0 length(statsDur(:,4))+0.3 0.15 0.67])
parts = strread(num2str(statsDur(:,4)'),'%s','delimiter',' ');
set(gca,'XTick',[1:length(statsDur(:,4))])
set(gca,'XTickLabel',parts)

%title(['Corpus: ' country ' ' plotTitle ' | Duration Analysis'])
%xlabel('Length of the First Phrase in Phrase-Pair ph_a_b')
%ylabel('Normalized Inter-Onset-Interval Size')
ylabel(' N IOI ')

print -depsc2 figplot3.eps


