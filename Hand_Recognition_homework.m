clc;    %Comman k�perny? tiszt�t�sa
close all;  %Minden bez�r�sa
clear;  %Megl�v? v�ltoz�k "t�rl�se"
workspace;  %WorkSpace j�n el? a program ind�t�sa ut�n

%**************WEBCAM STUFF*****************

%Inform�ci�k az el�rhet? k�pr�gz�t?kr?l
vidInfo = imaqhwinfo;
%Kamera objektum l�trehoz�sa
vid = videoinput('winvideo', 1);
%El?n�zeti ablak megny�lik
preview(vid);

%K�rd�s - V�lasz annak �rdek�ben, hogy csin�lunk egy k�pet, vagy pedig
%bet�lt�nk egyet a g�pr?l
message = sprintf('Would you like to take a picture?');
reply = questdlg(message, 'Capture Image', 'Yes', 'No', 'Yes');
%V�laszt�s leellen?rz�se
if strcmpi(reply, 'Yes')
    %Ha Igen akkor l�v�nk egy k�pet
    imgFromCam = getsnapshot(vid);
    I = imgFromCam;
else
    %T�r�lj�k a kamera objektumot, hogy ne foglalja a mem�ri�t
    delete(vid);
    %K�p beolvas�sa
    [filename, pathname] = ...
     uigetfile({'*.jpg';'*.png';'*.tif';'*.*'},'Select an Image file');
    fullFileName = fullfile(pathname, filename);
    I = imread(fullFileName);
end
%mindenk�pp t�r�lj�k az objektumot (�gy bez�r�dik a preview ablak is)
delete(vid);

%Ezzel a k�t sorral lehet kiv�g�st csin�lni ha akarunk
[I2, rect] = imcrop(I);
I = I2;

%*******************************************

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

%Megjel�li a "b?r pixeleket"
for i=1:numind
    %Az eredeti k�pen besz�nezz�k a b?rfel�leteket (szeml�ltet�s)
    O(r(i),c(i),:) = [255 0 0];
    %Az eddig csak 0-b�l �ll� t�mbbe a b?r hely�t felt�ltj�k 1-esekkel
    BW(r(i),c(i)) = 1;
end

%A kis fekete helyeket a nagyban kit�ltj�k
BW = imfill(BW, 'holes');
%Elt�nteti azt ami 300 pixeln�l kissebb (zaj sz?r�s)
%Egy m�r 1024 x 1024-es k�pen is kicsi az es�lye, hogy 30x30 -n�l kissebb
%legyen a k�z ter�lete
BW = bwareaopen(BW,900);

%%%%%%%%% Csak az ujjak kellenek%%%%%%%%

%Structuring element l�trehoz�sa
se = strel('square',70);
%El?sz�r elt�ntetj�k az ujjakat a k�pr?l, mivel azok mindig kissebbek mint
%a teny�r
BW2 = imerode(BW, se);
%Vissza�ll�tjuk a teny�r m�ret�t
BW2 = imdilate(BW2,se);
%Az �gy kapott "csak a teny�r" k�pet kivonjuk az eredetib?l, �gy megkapjuk
%csak az ujjakat tartalmaz� k�pet
BW3 = imsubtract(BW, BW2);
%30x30 pixeln�l kissebb ter�leteket eldobjuk
BW3 = bwareaopen(BW3,900);
%%Mivel csak azokat figyelj�k amik nagyok a kivon�s ut�n azaz az ujjaink
BW3 = bwareaopen(BW3,9000);
BW = BW3;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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


%Itt n�zz�k meg, hogy mit is kaptunk:
if sortingIndexes > 0
    if length(sortingIndexes) >= 3
        %Ha kett?n�l t�bb ujj van akkor tuti hogy nem oll�
        title('PAPER');
    elseif length(sortingIndexes) < 3 && length(sortingIndexes) >= 2
        % Ha 2 akkor pedid tuti, hogy oll�t mutatunk
        title('SCRISSORS');
    end
else
    %Minden egy�b esetben K? lesz
    title('ROCK');
end











%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%NEM KELL BELE:
%A m�sodik legnagyobb ter�let lesz a k�z (fej az els?)
% Ez a l�p�s nem sz�ks�ges, ha csak a kezet fot�zzuk
%handIndex = sortingIndexes(1);
%Ha t�bb ter�let van csak akkor kell t�r?dni vele
%if length(sortingIndexes) > 1
%    handIndex = sortingIndexes(2);
%end
%Elt�ntet�nk mindent kiv�ve a kez�t
%[labeledImage, numberOfAreas] = bwlabel(BW);
%HandImage = ismember(labeledImage, handIndex);

%Kiv�gjuk, hogy csak a k�z legyen a k�pen
%SubHandImage = imcrop(I, st(handIndex).BoundingBox);
%figure(1)
%subplot(2,2,4)
%imshow(SubHandImage);