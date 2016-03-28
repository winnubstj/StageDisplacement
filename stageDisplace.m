function [ ] = stageDisplace( tileDir )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
tileDir = 'Y:\mousebrainmicro\acquisition\2016-02-21\';
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

%%