clc;    %Comman k�perny? tiszt�t�sa
close all;  %Minden bez�r�sa
clear;  %Megl�v? v�ltoz�k "t�rl�se"
workspace;  %WorkSpace j�n el? a program ind�t�sa ut�n

%K�p beolvas�sa
[filename, pathname] = ...
     uigetfile({'*.jpg';'*.png';'*.tif';'*.*'},'Select an Image file');
fullFileName = fullfile(pathname, filename);
I = imread(fullFileName);

figure(1)
subplot(2,2,1)
imshow(I);


%A m�retek felv�tele
height = size(I,1);
width = size(I,2);

%Az O-ra rajzolunk r� pirossal (azaz bejel�lj�k a b?rfel�letet)
O = I;
BW = zeros(height,width);

%A k�pet RGB-b?l YCbCr-ba konvert�ljuk
%https://en.wikipedia.org/wiki/YCbCr
I_ycbcr = rgb2ycbcr(I);
Cb = I_ycbcr(:,:,2);
Cr = I_ycbcr(:,:,3);

figure(1)
subplot(2,2,2)
imshow(I_ycbcr);


%B?r detekt�l�sa
[r,c,v] = find(Cb>=77 & Cb<=127 & Cr>=133 & Cr<=173);
numind = size(r,1);

%Mark Skin Pixels
for i=1:numind
    %Az eredeti k�pen besz�nezz�k a b?rfel�leteket (szeml�ltet�s)
    O(r(i),c(i),:) = [255 0 0];
    %Az eddig csak 0-b�l �ll� t�mbbe a b?r hely�t felt�ltj�k 1-esekkel
    BW(r(i),c(i)) = 1;
end

%A kis fekete helyeket a nagyban kit�ltj�k
BW = imfill(BW, 'holes');
%Elt�nteti azt ami 300 pixeln�l kissebb (zaj sz?r�s)
%Egy m�r 1024 x 1024-es k�pen is kicsi az es�lye, hogy 300-n�l kissebb
%legyen a k�z ter�lete
BW = bwareaopen(BW,300);

figure(1)
subplot(2,2,3)
imshow(BW);

st = regionprops(BW, 'All');

%Ki�rjuk a workspace-n a ter�leteket sz�mszer�s�tve
fprintf(1,'Terulet #    Area\n');
for k = 1 : length(st)
    %"Bedobozol�s"
    thisBB = st(k).BoundingBox;
    hold on
    rectangle('Position', [thisBB(1),thisBB(2),thisBB(3),thisBB(4)],...
      'EdgeColor','r','LineWidth',1 );
    hold off
    fprintf(1,'#%2d %16.1f\n',k,st(k).Area);
end

%Rendezz�k az elemeket cs�kken?be a ter�let�k szerint
allAreas = [st.Area];
[sortedAreas, sortingIndexes] = sort(allAreas, 'descend');

%Megsz�mozza a legnagyobbt�l a legkissebbig
for k = 1 : length(st)
    centerX = st(sortingIndexes(k)).Centroid(1);
    centerY = st(sortingIndexes(k)).Centroid(2);
    text(centerX,centerY,num2str(k),'Color', 'b', 'FontSize', 14)
end

%A m�sodik legnagyobb ter�let lesz a k�z (fej az els?)
% Ez a l�p�s nem sz�ks�ges, ha csak a kezet fot�zzuk
handIndex = sortingIndexes(1);
%Ha t�bb ter�let van csak akkor kell t�r?dni vele
if length(sortingIndexes) > 1
    handIndex = sortingIndexes(2);
end
%Elt�ntet�nk mindent kiv�ve a kez�t
[labeledImage, numberOfAreas] = bwlabel(BW);
HandImage = ismember(labeledImage, handIndex);

%Kiv�gjuk, hogy csak a k�z legyen a k�pen
HandImage = imcrop(I, st(handIndex).BoundingBox);
figure(1)
subplot(2,2,4)
imshow(HandImage);



