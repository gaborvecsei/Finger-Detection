%Created by
%Vecsei Gábor
%vecseigabor.x@gmail.com
%https://gaborvecsei.wordpress.com/
%2016.04.10.

clc;
close all;
clear;
workspace;

%Get iformation about the cameras connected to the computer
vidInfo = imaqhwinfo;
%Initialize camera object
vid = videoinput('winvideo', 1);
%Open preview window
preview(vid);

%The user can choose to take a picture or load one
message = sprintf('Would you like to take a picture?');
reply = questdlg(message, 'Capture Image', 'Yes', 'No', 'Yes');
if strcmpi(reply, 'Yes')
    %Shoot a picture
    imgFromCam = getsnapshot(vid);
    I = imgFromCam;
else
    %Delete the camera object
    delete(vid);
    %Load the picture
    [filename, pathname] = ...
     uigetfile({'*.jpg';'*.png';'*.tif';'*.*'},'Select an Image file');
    fullFileName = fullfile(pathname, filename);
    I = imread(fullFileName);
end

%Delete the camera object and
%Close the preview window
delete(vid);

figure(1)
subplot(2,2,1)
imshow(I);

height = size(I,1);
width = size(I,2);

%We create a new image called O (original) so we can manipulate it later
O = I;
%New binary image filled with zeros
BW = zeros(height,width);

%For the skin detection we convert the image from RGB to YCbCr
%https://en.wikipedia.org/wiki/YCbCr
I_ycbcr = rgb2ycbcr(I);
Cb = I_ycbcr(:,:,2);
Cr = I_ycbcr(:,:,3);

figure(1)
subplot(2,2,2)
imshow(I_ycbcr);


%This is where we detect the skin pixels
[r,c,v] = find(Cb>=77 & Cb<=127 & Cr>=133 & Cr<=173);
numind = size(r,1);

for i=1:numind
    %On the original image we mark the skin pixels with red color
    O(r(i),c(i),:) = [255 0 0];
    %Fill the binary image with ones where we detect skin pixels
    BW(r(i),c(i)) = 1;
end

%Fill the little black holes
BW = imfill(BW, 'holes');
%Delete small areas on the image
BW = bwareaopen(BW,900);

se = strel('square',70);
%The fingers are smaller than the palm so we can "delete" them
%With simple morphology
BW2 = imerode(BW, se);
%Reconstruct the palm (or a little bigger than the original)
BW2 = imdilate(BW2,se);
%If we subtract the "only palm" image from the original one we will get the fingers only
BW3 = imsubtract(BW, BW2);
%"noise" reduction
BW3 = bwareaopen(BW3,9000);
BW = BW3;

figure(1)
subplot(2,2,3)
imshow(BW);

%Get the information about the contiguous areas
st = regionprops(BW, 'All');

fprintf(1,'Area #    Area\n');
for k = 1 : length(st)
    thisBB = st(k).BoundingBox;
    hold on
    rectangle('Position', [thisBB(1),thisBB(2),thisBB(3),thisBB(4)],...
      'EdgeColor','r','LineWidth',1 );
    hold off
    fprintf(1,'#%2d %16.1f\n',k,st(k).Area);
end

%Sort the areas
allAreas = [st.Area];
[sortedAreas, sortingIndexes] = sort(allAreas, 'descend');

%Count the areas and label them on the binary image
for k = 1 : length(st)
    centerX = st(sortingIndexes(k)).Centroid(1);
    centerY = st(sortingIndexes(k)).Centroid(2);
    text(centerX,centerY,num2str(k),'Color', 'b', 'FontSize', 14)
end


%Now we can detect what is on the picture
if sortingIndexes > 0
    if length(sortingIndexes) >= 3
        title('PAPER');
    elseif length(sortingIndexes) < 3 && length(sortingIndexes) >= 2
        title('SCISSORS');
    end
else
    title('ROCK');
end