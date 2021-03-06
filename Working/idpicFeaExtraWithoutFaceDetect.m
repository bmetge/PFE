% 2014 05 22
% id pic feature extraction using code_face and code_point

function [idfea,picfea,label] = idpicFeaExtra(algparam,fparam)
fprintf('debut du programm');
fw=fopen('landmarksFace.txt','w');
findex=fopen('indexingFoundNotFound.txt','w');
global facefound;
facefound = 0;
global facenotfound;
facenotfound = 0;
%% face similar trans
% set the mean face for the normalization
idimage_name = 'dictionary/idimage200'; % modify here if you want an other mean face
load(idimage_name);  % id database info
meanface = idimage.meanface;
addpath('meanface');  % Add the folder "meanface" to the path 

%% LBP SETTING
addpath('lbp');       %lbp
mapping = getmapping(8,'u2'); %GETMAPPING returns a structure containing a mapping table for LBP codes. 'u2' for uniform lbp
mode = 'h';
fd = mapping.num;

%% face detect and alignment

%% im preprocessing
% addpath('normalize'); % for image preprocessing

label = []; % name of the subject ?
idfea = []; % type of feature ?
picfea = []; % feature ?

iddir = dir(fullfile(fparam.idDir,'*.png')); % read all the image 
for id = 1:2  %length(iddir) % process the image one by one
    fprintf('processing: %d , fix((id-1)/20)+1 : %d\n',id, fix((id-1)/20)+1);
    idimname = iddir(id).name; % retrive the name of the current image
    name = idimname(1:end-4); % remove '.jpg' ?
    
    % read id image 
    % generate imagelist
    idimname = fullfile(fparam.idDir,idimname); 
    % retrieve the 5 key points ( eyes, mouse extremties, nose )
    points = Get5Points(idimname,fparam.idDir);
    if isempty(points)
        facenotfound = facenotfound + 1;d
        fprintf(findex,'photonumber %d  idperson %d found %d\n',id, fix((id-1)/20)+1,0);
    else 
        facefound = facefound + 1;
        fprintf(findex,'photonumber %d  idperson %d found %d\n',id, fix((id-1)/20)+1,1);
%         imageNum = fread(fr, 1, 'int32');
%         pointNum = fread(fr, 1, 'int32');
%         assert(pointNum == 5);
%         valid = fread(fr, imageNum, 'int8');
%         assert(all(valid) == 1);

%         point = reshape(fread(fr, 2 * pointNum * imageNum, 'float64'), [2 * pointNum, imageNum]);
        for i=1:size(points,2)
%             tLine=fgetl(fb);
%             sArr=regexp(tLine,' ','split');
            fprintf(fw,'%d %f %f %f %f %f %f %f %f %f %f \n',fix((id-1)/20)+1, points(1,i),points(2,i),points(3,i),points(4,i),points(5,i),points(6,i),points(7,i),points(8,i),points(9,i),points(10,i));
        end
%         fclose(fb);
%         fclose(fr);
    end 
    idim = imread(idimname);
    if size(idim,3)>1
        idim = rgb2gray(idim);
    end
    h = figure;
    imshow(idim);
    hold on,scatter(points(1:2:end),points(2:2:end),'*','r');
    drawnow;
    close(h);
%     idimfea = FaceFea(idim,points,algparam,meanface,mapping,mode);
%     idfea = [idfea,idimfea];
%     
%     %read pic images
%     picdir = dir(fullfile(fparam.picDir,name,'*.jpg'));
%     for pici = 1:length(picdir)
%         picname = fullfile(fparam.picDir,name,picdir(pici).name);
%         picim = imread(picname);
%         [h,w,c] = size(picim);
%         if h<w && ~strcmp(name,'paulxiang')
%             npicim = uint8(zeros(w,h,c));
%             for c = 1:size(picim,3)
%                 npicim(:,:,c) = fliplr(picim(:,:,c)');
%             end
%             picim = uint8(npicim);
%             imwrite(picim,picname);%,'quality',95);
%         end
%         
% %         if true
% %             scale = max(150/h,150/w);
% %             picim = imresize(picim,scale);
% %             if ~isdir(fullfile(fparam.lowpicDir,name))
% %                 mkdir(fullfile(fparam.lowpicDir,name))
% %             end
% %             imwrite(picim,fullfile(fparam.lowpicDir,name,picdir(pici).name));%,'quality',95);
% %         end
% 
%         points = Get5Points(picname,fullfile(fparam.picDir,name));
%         
%         if size(picim,3)>1
%             picim = rgb2gray(picim);
%         end
%         h = figure;
%         imshow(picim);
%         if isempty(points)
%             continue;
%         end
%         hold on,scatter(points(1:2:end),points(2:2:end),'*','r');
%         drawnow;
%         picimfea = FaceFea(picim,points,algparam,meanface,mapping,mode);
%         picfea = [picfea,picimfea];
%         close(h);
%         label = [label;id];
%     end
    
end
fprintf(' ==============RESULT===============\n');
fprintf(' face found = %d , face not found = %d', facefound, facenotfound);
fclose(fw);


function imfea = FaceFea(im,landmark,algparam,meanface,mapping,mode)

patchSize = algparam.patchSize;
patchMesh = algparam.patchMesh;
centered = algparam.centered;
scale = algparam.scale;
olp = algparam.olp;
% 
%   figure,imshow(im);
%   hold on,scatter(landmark(1:2:end),landmark(2:2:end),'*','r'); 
    
[nim,nlandmark] = normalize_face(im,landmark,meanface);%*1.2
nlandmark = round(nlandmark);

%     H = fspecial('gaussian',5,1);
%     nim = imfilter(nim,H);

%     figure,imshow(nim);
%     hold on,scatter(nlandmark(1:2:end),nlandmark(2:2:end),'*','y'); 

imfea = [];
for s = 1:length(scale)
    tnim = imresize(nim,scale(s));
    tnlandmark = round(nlandmark*scale(s));

    if centered == 1
        patchFea = get_face_feature_s(tnim,tnlandmark,mapping,mode,patchMesh,patchSize);
    else
        patchFea = get_face_feature(tnim,tnlandmark,mapping,mode,patchMesh,patchSize,olp);
    end

    imfea = [imfea; patchFea];%      
end
imfea = reshape(imfea',size(imfea,1)*size(imfea,2),1);

% function to get 5 key points
function  points = Get5Points(idimname,imDir)

% imlistfid = fopen('imagelist.txt','wt');
% if imlistfid == -1
%     fprintf('reading image error');
% end
% fprintf(imlistfid,'%d\n',1);
% fprintf(imlistfid,'%s',idimname);
% fclose(imlistfid);
%cmd = 'FacePartDetect.exe code_face_data imagelist.txt bbox.txt'; % install wine if on mac and remove wine on windows
%system(cmd);
bboxfid = fopen('bbox.txt');
if bboxfid ==-1
    fprintf('error\n');
end
df = [];
while ~feof(bboxfid)
    bsline = fgetl(bboxfid);
    sdf = regexp(bsline, '\s+', 'split');
    if length(sdf)>2
        ndf = [str2num(sdf{2}),str2num(sdf{3}),str2num(sdf{4}),str2num(sdf{5})];
        df = [df;ndf];
    end
end
fclose(bboxfid);
if isempty(df)
    fprintf('can not find face in %s.\n',idimname);
    points = [];
    return;
end 

bboxfid = fopen('bbox.txt','wt');
if bboxfid ==-1
    fprintf('error\n');
end
[ig1,imn,imtype] = fileparts(idimname);
fprintf(bboxfid,'%s %d %d %d %d',[imn,imtype],df(1),df(2),df(3),df(4));
fclose(bboxfid);
disp('hello');
cmd = ['TestNet.exe bbox.txt ',imDir, ' Input result.bin'];
system(cmd);
% read 5 ps
fr=fopen('result.bin','rb');
imageNum = fread(fr, 1, 'int32');
pointNum = fread(fr, 1, 'int32');
assert(pointNum == 5);
valid = fread(fr, imageNum, 'int8');
assert(all(valid) == 1);
points = reshape(fread(fr, 2 * pointNum * imageNum, 'float64'), [2 * pointNum, imageNum]);
fclose(fr);

%     if ~isempty(df)
%         rectangle('Position',[df(1,1),df(1,3),df(1,2)-df(1,1),df(1,4)-df(1,3)],'Curvature',[0 0],'EdgeColor','g');
%     end
