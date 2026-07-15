%% Unmix spectra from Living Image and save results
%% Joseph R. Merrilll
%% Cold Spring Harbor Laboratory
%% Updated 2019/10/09
%%
%% A script to calculate and print the least squares fit of BLI spectra from Living Image to
%% two reference spectra. Instructions;
%%  1)  Open an image sequence in Living Image
%%  2)  Add 5 ROI and position over each subject (note this script only works w/ 5 ROI so add 5 even if there are fewer subjects)
%%  3)  Click measure ROI, then export the results as a txt file
%%  4)  Run this script and select the exported ROI file
%% Output;
%%  The coefficients of the red and green components, the normalized (sum to 1) coeffients, the R-square of the fit the red/green and green/red
%%  ratios are tabulated and saved in a text file (unmix_output.txt) in the same location as the raw ROI data. Plots of the acquired and fit
%%  spectra, superimposed w/ the red and green reference spectra are also saved for all subjects (FitPlot_i.png). Optionally, a powerpoint
%%  report can be created using the exportToPPTX tool: https://www.mathworks.com/matlabcentral/fileexchange/40277-exporttopptx
%%

green = [240000000;286000000;314000000;252000000;398000000;340000000;218000000;128000000];  % reference spectra (update as nec.)
red = [-551000;514000;2180000;14000000;116000000;238000000;208000000;130000000];
normgreen = green/max(green);
normred = red/max(red);
ref = [normgreen,normred];                        % reference matrix
lambda = [520:20:660];                            % measured wavelengths

% user selects ROI file exported from Living Image and data is loaded
[lifile,lipath] = uigetfile;        
ROImx = importdata(fullfile(lipath,lifile),'\t',1);
% retrieve name of Living Image sequence
seq = ROImx.textdata{2,1};
seq = strsplit(seq,'_');
seq = seq{1};

mouse = zeros(8,5);
for i = 1:5                     % create vectors of spectra for all 5 mice from Living Image export file
    first = 0+i;
    last = 35+i;
    mouse(:,i) = ROImx.data(first:5:last,1);
end

A = zeros(2,5);                 % matrix of calculated coefficients (2 coeff., 5 subjects)
normA = zeros(2,5);
gor = zeros(1,5);
rog = zeros(1,5);
fit = zeros(1,8);
fitSSE = zeros(1,5);
fitSST = zeros(1,5);
fitRsq = zeros(1,5);

for i = 1:5
    [A(:,i),fitSSE(i)] = lsqnonneg(ref,mouse(:,i));     % calculate least-squares fit of ROI data to the green and red reference spectra. Also pull sum of squares due to error (SSE)
    normA(:,i) = A(:,i)/norm(A(:,i),1);                 % have green and red coefficients sum to 1
    gor(i) = A(1,i)/A(2,i);                             % green over red ratio
    rog(i) = A(2,i)/A(1,i);                             % red over green ratio
    
    fit = normgreen*A(1,i)+normred*A(2,i);              % curve fit of acquired spectrum to the two references    
	mn = mean(mouse(:,i));                              % mean of sampled values
    fitSST(i) = sum((mouse(:,i)-mn).^2);                % calculate sum of squares about the mean (SST)
    fitRsq(i) = 1 - (fitSSE(i)/fitSST(i));          	% calculate R-square
    
    % save plot of acquired spectrum, fit spectrum and red and green reference spectra, all normalized
    fitplot = plot(lambda,normgreen,'g',lambda,normred,'r',lambda,mouse(:,i)/max(mouse(:,i)),'-*b',lambda,fit/max(fit(:)),'m--');
	fitplot(4).LineWidth = 1.5;
    title(['Mouse ' num2str(i)]);
    legend({'green ref','red ref','acq. spectrum','fit spectrum'},'Location','best');
    xlabel('Wavelength (nm)');
    ylabel('Normalized flux');
    ylim([0 inf]);
    print([lipath 'FitPlot_' num2str(i)],'-dpng');
end

% tabulate and print output data to text file
fid = fopen(fullfile(lipath,['unmix_' seq '.txt']),'w');
fprintf(fid,'%-18s\t %-12s\t %-12s\t %-12s\t %-12s\t %-12s\r\n',seq,'mouse1','mouse2','mouse3','mouse4','mouse5');
fprintf(fid,'%18s\t %12.3e\t %12.3e\t %12.3e\t %12.3e\t %12.3e\r\n','green coef.',A(1,:));
fprintf(fid,'%18s\t %12.3e\t %12.3e\t %12.3e\t %12.3e\t %12.3e\r\n','red coef.',A(2,:));
fprintf(fid,'%18s\t %12.3f\t %12.3f\t %12.3f\t %12.3f\t %12.3f\r\n','norm. green coef.',normA(1,:));
fprintf(fid,'%18s\t %12.3f\t %12.3f\t %12.3f\t %12.3f\t %12.3f\r\n','norm. red coef.',normA(2,:));
fprintf(fid,'%18s\t %12.3f\t %12.3f\t %12.3f\t %12.3f\t %12.3f\r\n','R-square of fit',fitRsq(:));
fprintf(fid,'%18s\t %12.3f\t %12.3f\t %12.3f\t %12.3f\t %12.3f\r\n','green/red ratio',gor(:));
fprintf(fid,'%18s\t %12.3f\t %12.3f\t %12.3f\t %12.3f\t %12.3f\r\n','red/green ratio',rog(:));
fclose(fid);

% ask user whether to make a PPT report
yppt = questdlg('Would you like to create a PPT report?','Report','Yes','No','No');
switch yppt
    case 'Yes'
        bippt = 1;
    case 'No'
        bippt = 0;
end
% if yes, create the PPT report (requires exportToPPTX tool to be installed in Matlab path)
if 1
    
    isOpen  = exportToPPTX();
    if ~isempty(isOpen)
        exportToPPTX('close');
    end
    
    exportToPPTX('open','unmix_template.pptx');
    
    for j = 1:5
        exportToPPTX('addslide','Layout','fitplot');
        exportToPPTX('addtext',seq,'Position','sequence');
        exportToPPTX('addtext',['mouse' num2str(j)],'Position','subject');
        curplot = imread([lipath 'FitPlot_' num2str(j) '.png']);
        exportToPPTX('addpicture',curplot,'Position','plot');
        tableData = {...
            'green coef.',sprintf('%.3e',A(1,j));...
            'red coef.',sprintf('%.3e',A(2,j));...
            'norm. green coef.',sprintf('%.3f',normA(1,j));...
            'norm. red coef.',sprintf('%.3f',normA(2,j));...
			'R-square of fit',sprintf('%.3f',fitRsq(j));...
            'green/red ratio',sprintf('%.3f',gor(j));...
            'red/green ratio',sprintf('%.3f',rog(j))};
        exportToPPTX('addtable',tableData,'Position','table');
    end
    % save PPT in raw data directory, then go back
    mldir = pwd;
    cd(lipath);
    newFile = exportToPPTX('save',['unmix_' seq '.pptx']);
    exportToPPTX('close');
    cd(mldir);
    
end

fprintf('dunzo');