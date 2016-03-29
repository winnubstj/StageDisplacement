function [ ] = stageDisplace( )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
% Set Java heap memory to 4 gb in Matlab/preferences/General/Java Heap
% memory
tileDir = 'Y:\mousebrainmicro\acquisition\2016-02-21\';
chan = 0;
%% load and convert Json file to .mat
jsonFile = fullfile(tileDir,'dashboard.json');
matFile = fullfile(tileDir,'dashboard.mat');
if isempty(dir(matFile))
    %load JSON
    fprintf('\nLoading Json file..');
    if isempty(dir(jsonFile)), error('JSON file: %s could not be found',jsonFile); end
    opt.ShowProgress = true;
    jsonData = loadjson(jsonFile,opt);
    fprintf('\nSaving Json file..');
    save(matFile,'jsonData');
else
    %load Mat
    fprintf('\nLoading pre-parsed Json file..');
    load(matFile);
end
fprintf('\nDone');

%% Get lattice position and file location all tiles.
contents = structfun(@(x) x,jsonData.tileMap,'UniformOutput',false);
contents = struct2cell(contents);
nTiles = cellfun(@(x) size(x,2),contents); %only days that have tiles.
contents = contents(nTiles>1);
contents = horzcat(contents{:});
latPos = cellfun(@(x) x.contents.latticePosition,contents); % get Lattice position.
latPos = [latPos.x;latPos.y;latPos.z]';
fileLoc = cellfun(@(x) fullfile(jsonData.monitor.location,x.relativePath),contents,'UniformOutput',false)'; % get file position.
%% Take out duplicates

%% Starting MIJ
fprintf('\nStarting MIJ for Fiji Registration');
javaaddpath 'C:\Program Files\MATLAB\R2015b\java\mij.jar'
javaaddpath 'C:\Program Files\MATLAB\R2015b\java\ij-1.50g.jar'
MIJ.start('C:\Fiji.app\plugins');
IJ=ij.IJ();
fprintf('Done!\n');
%% Perform calculation at 25,50 and 70% of sample
targetZ = round([prctile(unique(latPos(:,3)),50),prctile(unique(latPos(:,3)),50),prctile(unique(latPos(:,3)),70)]);
for cZ = targetZ
   %% select random tiles untill good transform matrix is found.
   pass = false;
   while pass==false
       %% Search for neighbors.
       tileList = find(latPos(:,3)==cZ);
       rng(9); % seed random num gen.
       cTile = tileList(randi(length(tileList)));
       x1Tile = find(ismember(latPos,[latPos(cTile,1)+1,latPos(cTile,2),latPos(cTile,3)],'rows'));
       y1Tile = find(ismember(latPos,[latPos(cTile,1),latPos(cTile,2)+1,latPos(cTile,3)],'rows'));
       if isempty(x1Tile) || isempty(y1Tile)
           continue
       end
       %% Open Images;
       fprintf('Loading Images..\n');
       x1Tile=fileLoc{x1Tile}; y1Tile=fileLoc{y1Tile};
       x1Tile = fullfile(x1Tile,sprintf('%s-ngc.%i.tif',x1Tile(end-4:end),chan));
       y1Tile = fullfile(y1Tile,sprintf('%s-ngc.%i.tif',y1Tile(end-4:end),chan));
       IJ.open(x1Tile);IJ.open(y1Tile);
   end
end
