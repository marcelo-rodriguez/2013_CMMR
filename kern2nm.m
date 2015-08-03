function EFSC = kern2nm()

%-------------
% DESCRIPTION
%-------------

% parser returns:
% struct array with fields:
% code              Essen Code              (e.g C0001)
% key               key of melody           (e.g. C, G#, A-)
% phraseBoundaries  phrase info matrix      [start | end | length]
% pabMat            phrase pair(a,b) mat    [start | end | mid | length(pha) | length(phb)]
% melodyNMAT        melody note matrix      [durations (MIDIticks) | pitches (MIDI number)]



%-------------
% ALGORITHM
%-------------

%select ONE or MULTIPLE input files to be read
[filename,filepath] = uigetfile({'*.krn','EFSC files'; ...
            '*.txt','txt files';'*.*', 'All files (*.*)'}, ...
            'plese select one or more filename-lists to be parsed',...
            'MultiSelect', 'on'); 
		if(isequal(filename,0) || isequal(filepath,0))
			error('Wrong number of input arguments');
        end
        
        
        
%set loop length
if(ischar(filename))
    numfiles=1;
elseif(iscell(filename))
    numfiles=length(filename);
end

fsng_c=1;
for f=1:numfiles 
    
    %read the data from lists
    if(ischar(filename))
        fpath = [filepath filename];
    elseif(iscell(filename))
        fpath = [filepath filename{f}];
    end
    fid      = fopen(fpath);
    flines   = textscan(fid, '%s', 'delimiter', '\n');
    flines   = flines{1};


    %extract FAMILY field information
    %extract TITLE
    %extract CODE
    regEx = '[!]+SCT: (?<code>[a-zA-Z]*[0-9]*)';
    tmp = regexp(flines,regEx,'names');
    idx = find(not(cellfun('isempty', tmp)));
    EFSC(fsng_c).code=tmp{idx}.code;
    
    %extract KEY
    regEx = '\*(?<key>[a-zA-Z](-|#)?):';
    tmp = regexp(flines,regEx,'names');
    idx = find(not(cellfun('isempty', tmp)));
    %EFSC(fsng_c)= tmp{idx};
    EFSC(fsng_c).key=tmp{idx}.key;



    %extract indexes localtion for BEGIN melody symbol
    regEx='*[a-zA-Z](-|#)?:';
    tmp=regexp(flines,regEx);
    bMel = find(not(cellfun('isempty', tmp)));

    %extract indexes localtion for END melody symbol
    exp='==';
    tmp=regexp(flines,exp);
    eMel = find(not(cellfun('isempty', tmp)));

    %extract melody and copy in new cell array
    melody=flines(bMel+1:eMel-1);

    %get bar locations
    regEx = '=+';
    tmp=regexp(melody,regEx);
    idx = find(not(cellfun('isempty', tmp)));      
    %remove bars
    melody(idx)=[];
    
    %get comments locations
    regEx = '!+';
    tmp=regexp(melody,regEx);
    idx = find(not(cellfun('isempty', tmp)));      
    %remove comments
    melody(idx)=[];
    
    %get changeMeasure locations
    regEx = '\*';
    tmp=regexp(melody,regEx);
    idx = find(not(cellfun('isempty', tmp)));      
    %remove changeMeasure
    melody(idx)=[];
    
    %clean melody (slurs, ties)
    melody = melodyClean(melody);

    clear idx tmp regEx
    
    %Extract PHRASE STARTS/ENDS LOCATIONS + phrase LENGTHS
    
    %phrase starts
    regEx = '{';
    tmp   = regexp(melody,regEx);
    idx   = find(not(cellfun('isempty', tmp)));
    EFSC(fsng_c).phraseBoundaries=zeros(length(idx),3);
    
    %phrase ends
%     regEx = '}';
%     tmp=regexp(melody,regEx);
%     idx2 = find(not(cellfun('isempty', tmp)));
    idx2=[idx(2:end)-1;length(melody)];
    
    %phrase lengths
    lngths=[idx(2:end);idx2(end)]-idx;
    lngths(end)=lngths(end)+1; %correction for last phrase
    
    %store
    pBound=[idx idx2 lngths];
    EFSC(fsng_c).phraseBoundaries=pBound;
    
    %Create Phrase Pairs (a,b) Matrix: pabMat
    if(size(pBound,1)>1)
        
        %protection
%         if(size(pBound,1)<=3); sz=size(pBound,1); 
%         else sz=size(pBound,1)-1; end
        sz=size(pBound,1);
        
        %extract values
        c=1;
        for i=2:sz; 
            pabMat(c,1)=pBound(i-1,1);
            pabMat(c,2)=pBound(i,2);
            pabMat(c,3)=pBound(i,1);
            pabMat(c,4)=pBound(i-1,3);
            pabMat(c,5)=pBound(i,3); 
            c=c+1; 
        end
    
        EFSC(fsng_c).pabMat=pabMat;
        %CHECK PROCEDURE---1b%
        if(size(pabMat,1)~=(size(pBound,1)-1))
            display(['PabMAT INCONSISTENT, is: ' num2str(size(pabMat,1)) ...
                     ' and should be: ' num2str(size(pBound,1)-1)...
                     ' ,for song: ' num2str(f) ...
                     ' ,ESFC code: ' num2str(EFSC(fsng_c).code)])
        end
        %CHECK PROCEDURE---1e%
        clear pabMat
    else
        %assign something to the one phrase case (to filter it later)
        EFSC(fsng_c).pabMat=[1 1 1 1 1]; 
        clear pabMat
    end
    

    %creating a note matrix from kern melody
        %inits
        melNMAT=zeros(length(melody),2);
    for e=1:length(melody)
        
        
        %extract duration
        regEx = '{?(?<dur>[0-9]+\.?)[a-zA-z]+}?';
        tmp = regexp(melody{e},regEx,'names');

        %encode and save duration
        melNMAT(e,1)=dur2miditick(tmp.dur);
        
        
        %if REST is found %PROTECTION%
        regEx = 'r+';
        tmp = regexp(melody{e},regEx);
        if(~isempty(tmp))
            display(f)
            display(EFSC(fsng_c).code)
            error('melody contains a rest!')
        end

        %extract pitch
        regEx = '{?[0-9]*(?<pitch>[a-zA-z]+(-|#)*)}?';
        tmp = regexp(melody{e},regEx,'names');

        %encode and save pitch
        melNMAT(e,2)=kern2midipitch(tmp.pitch);

    end

    %save melody nmat
    EFSC(fsng_c).melodyNMAT=melNMAT;
    
    fsng_c=fsng_c+1;
end

function midipitch = kern2midipitch(kernPitch)

%extract pitch
regEx   = '(?<noteName>[a-zA-z]+)';
p       = regexp(kernPitch,regEx,'names');

%check if accidentals
regEx   = '[a-zA-z]+(?<flatSharp>(-|#)*)';
a       = regexp(kernPitch,regEx,'names');
a_flag  = ~isempty(a.flatSharp);

%check octave
o_up_flag   = isstrprop(kernPitch(1), 'lower');

%1 - encode diatonic midi pitch
switch(lower(p.noteName(1)))
   case 'c'
      midipitch=60;
   case 'd'
      midipitch=62;
   case 'e'
      midipitch=64;
   case 'f'
      midipitch=65;
   case 'g'
      midipitch=67;
   case 'a'
      midipitch=69;
   case 'b'
      midipitch=71;
end

%2 - encode octave
if(o_up_flag)
    o_num     = length(p.noteName)-1;
    midipitch = midipitch + 12*(o_num);
else
    o_num     = length(p.noteName);
    midipitch = midipitch - 12*(o_num);
end

%3 - encode accidentals
if(a_flag) 
    if(strcmp(a.flatSharp(1),'#'))
        a_up_num     = length(a.flatSharp);
        midipitch    = midipitch + 1*(a_up_num);
    elseif(strcmp(a.flatSharp(1),'-'))
        a_dn_num     = length(a.flatSharp);
        midipitch    = midipitch - 1*(a_dn_num);
    end
end

function miditick = dur2miditick(kernDur)

%check if dotted
regEx = '[0-9]+(?<dotted>\.+)';
tmp = regexp(kernDur,regEx,'names');

if(isempty(tmp))
    %convert to numerical value
    kernDur = str2num(kernDur);

    %convert kern duration to miditick conversion
    switch(kernDur)
       case 48 %32note-tripplet
          miditick=2;
       case 32 %32note
          miditick=3;
       case 24 %16note tripplet
          miditick=4;
       case 16 %16note
          miditick=6;
       case 12 %8note tripplet
          miditick=8;
       case 8 %8note
          miditick=12;
       case 6 %4note tripplet
          miditick=16;
       case 4 %4note
          miditick=24;
       case 3 %2note tripplet
          miditick=32;
       case 2 %2note
          miditick=48;
       case 1 %whole-note
          miditick=96;
       case 0 %breve
          miditick=192;        
    end
    
else
    
    %extract numberical value
    regEx = '(?<duration>[0-9]+)\.+';
    tmp2  = regexp(kernDur,regEx,'names');
    
    %convert to numerical value
    tmp2.duration = str2num(tmp2.duration);

    %convert kern duration to miditick conversion
    switch(tmp2.duration)
       case 48 %32note-tripplet
          miditick=2;
       case 32 %32note
          miditick=3;
       case 24 %16note tripplet
          miditick=4;
       case 16 %16note
          miditick=6;
       case 12 %8note tripplet
          miditick=8;
       case 8 %8note
          miditick=12;
       case 6 %4note tripplet
          miditick=16;
       case 4 %4note
          miditick=24;
       case 3 %2note tripplet
          miditick=32;
       case 2 %2note
          miditick=48;
       case 1 %whole-note
          miditick=96;
       case 0 %breve
          miditick=192;        
    end
    
    %increment according to dotted (check wikipedia for the formula)
    n=length(tmp.dotted);
    miditick= 2*miditick - (miditick/(2^n));

    
end

function cleanMel = melodyClean(mel)

regEx = '[';
tmp=regexp(mel,regEx);
idx1 = find(not(cellfun('isempty', tmp)));

regEx = ']';
tmp=regexp(mel,regEx);
idx2 = find(not(cellfun('isempty', tmp))) ;

regEx = '(';
tmp=regexp(mel,regEx);
idx3 = find(not(cellfun('isempty', tmp))) ;

regEx = ')';
tmp=regexp(mel,regEx);
idx4 = find(not(cellfun('isempty', tmp))) ;

regEx = '_';
tmp=regexp(mel,regEx);
idx5 = find(not(cellfun('isempty', tmp))) ;

idx=[idx1;idx2;idx3;idx4;idx5];
idx=sort(idx);

for ii=1:length(idx) 
    i           = idx(ii);
    tmp         = char(mel{i});
    regEx       = '\[|\(|_|\)|\]';
    idxs        = regexp(tmp,regEx);
    tmp(idxs)   = [];
    mel{i}      = tmp;
end

cleanMel=mel;



