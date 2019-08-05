%%% Script parameters:
% Path of the manifest file that was used to dowanload for the GDC portal
manifestPath = '\gdc_manifest_20190730_134239_Part1And2.txt';

% Data folder of raw files downloaded from the GDC each contain a gz file
tcgaDataFolder = 'RNASeq_Raw';

% Output folder for gz files extraction
outputFolder = 'RNASeq_Extracted';

% Path of the apiRequest file
queryPath = 'apiRequest.txt';

printExtracProgressEvery = 200;
printAPIProgressEvery = 100;
%%%% end of Script parameters

%%%%%%%%%%%%
% Loads the manifest file (contians gz file names and their matched file id)
%%%%%%%%%%%%
manifest = tdfread(manifestPath);
for field = fieldnames(manifest)'
    if(ischar(manifest.(field{1})))
        manifest.(field{1}) = cellstr(manifest.(field{1}));
    end
end

%%%%%%%%%%%%
% Data extraction
%%%%%%%%%%%%
tcgaRNASeq = struct;
tcgaRNASeq.fileName = cell(length(manifest.id),1);
for i=1:length(manifest.id)
    
    % For each file name in the manifest file, identifies the revlevant file id
    % to unzip and then loads
    id = manifest.id{i};
    curDataFolder = sprintf('%s\\%s',tcgaDataFolder,id);
    fileList = dir(fullfile(curDataFolder, '*.gz'));
    fullName = fullfile(fileList.folder,fileList.name);
    extractedName = gunzip(fullName,outputFolder);
    
    delimiterIn = '\t';
    headerlinesIn = 0;
    % Read data from one file
    curData = importdata(extractedName{1},delimiterIn,headerlinesIn);
    
    % Add the data of current file to the tcgaRNASeq struct
    if (i==1)
        tcgaRNASeq.genes = curData.rowheaders;
        tcgaRNASeq.data = zeros(length(tcgaRNASeq.genes),length(manifest.id));
        tcgaRNASeq.data(:,1) = curData.data;
        tcgaRNASeq.file_id = cell(length(manifest.id),1);
    else
        [genesNew,ia,ib] = union(tcgaRNASeq.genes,curData.rowheaders);
        if(length(genesNew)>length(tcgaRNASeq.genes))
            disp('Different genes');
        else
            [exists,locs] = ismember(curData.rowheaders,tcgaRNASeq.genes);
            locs = locs(exists);
            tcgaRNASeq.data(locs,i) = curData.data(exists);
        end
    end
    tcgaRNASeq.file_id{i} = id;
    tcgaRNASeq.fileName{i} = fileList.name;
    
    if(mod(i,printExtracProgressEvery)==0)
        fprintf('%.1f percent completed extraction\n', i/length(manifest.id)*100);
    end
end

%%%%%%%%%%%%
% Calls the GDC API to get additional information for each file such as
% case_id and sample_id.
% This part takes a while, ~1 sec per file. This may be improved if querying
% for several ids in each request, but limited to 10 by the API.
%%%%%%%%%%%%
tcgaRNASeq.case_id = cell(length(tcgaRNASeq.file_id),1);
tcgaRNASeq.project_id = cell(length(tcgaRNASeq.file_id),1);
tcgaRNASeq.sample_id = cell(length(tcgaRNASeq.file_id),1);
tcgaRNASeq.sample_type = cell(length(tcgaRNASeq.file_id),1);
tcgaRNASeq.sample_type_id = cell(length(tcgaRNASeq.file_id),1);
tcgaRNASeq.submitter_id = cell(length(tcgaRNASeq.file_id),1);

fid = fopen(queryPath);
raw = fread(fid,inf);
queryRaw = char(raw');
fclose(fid);

problematicIds = [];
for i=1:length(tcgaRNASeq.file_id)
    
    id = tcgaRNASeq.file_id{i};
    % Replaces $$$ to the file_id
    query = strrep(queryRaw,'$$$',id);
    options = weboptions('Timeout', 20);
    
    try
        queryRes = webread(query,options);
    catch
        try
            queryRes = webread(query,options);
        catch
            problematicIds(end+1) = i;
            fprintf('Error in API request for file_id: %s\n', id);
            continue;
        end
    end
    
    % Extracts the info
    tcgaRNASeq.case_id{i} = queryRes.data.hits.cases.case_id;
    tcgaRNASeq.project_id{i} = queryRes.data.hits.cases.project.project_id;
    tcgaRNASeq.sample_id{i} = queryRes.data.hits.cases.samples.sample_id;
    tcgaRNASeq.sample_type{i} = queryRes.data.hits.cases.samples.sample_type;
    tcgaRNASeq.sample_type_id{i} = queryRes.data.hits.cases.samples.sample_type_id;
    tcgaRNASeq.submitter_id{i} = queryRes.data.hits.cases.samples.submitter_id;
    
    if(mod(i,printExtracProgressEvery)==0)
        fprintf('%.1f percent completed API request\n', i/length(tcgaRNASeq.file_id)*100);
    end
end
tcgaRNASeq.sample_type_id = cellfun(@str2num, tcgaRNASeq.sample_type_id);
