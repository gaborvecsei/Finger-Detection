clc;    %Comman képerny? tisztítása
close all;  %Minden bezárása
clear;  %Meglév? változók "törlése"
workspace;  %WorkSpace jön el? a program indítása után

%**************WEBCAM STUFF*****************

%Információk az elérhet? képrögzít?kr?l
vidInfo = imaqhwinfo;
%Kamera objektum létrehozása
vid = videoinput('winvideo', 1);
%El?nézeti ablak megnyílik
preview(vid);

%Kérdés - Válasz annak érdekében, hogy csinálunk egy képet, vagy pedig
%betöltünk egyet a gépr?l
message = sprintf('Would you like to take a picture?');
reply = questdlg(message, 'Capture Image', 'Yes', 'No', 'Yes');
%Választás leellen?rzése
if strcmpi(reply, 'Yes')
    %Ha Igen akkor lövünk egy képet
    imgFromCam = getsnapshot(vid);
    I = imgFromCam;
else
    %Töröljük a kamera objektumot, hogy ne foglalja a memóriát
    delete(vid);
    %Kép beolvasása
    [filename, pathname] = ...
     uigetfile({'*.jpg';'*.png';'*.tif';'*.*'},'Select an Image file');
    fullFileName = fullfile(pathname, filename);
    I = imread(fullFileName);
end
%mindenképp töröljük az objektumot (így bezáródik a preview ablak is)
delete(vid);

%Ezzel a két sorral lehet kivágást csinálni ha akarunk
[I2, rect] = imcrop(I);
I = I2;

%*******************************************

figure(1)
subplot(2,2,1)
imshow(I);
  

%A méretek felvétele
height = size(I,1);
width = size(I,2);

%Az O-ra rajzolunk rá pirossal (azaz bejelöljük a b?rfelületet)
O = I;
BW = zeros(height,width);

%A képet RGB-b?l YCbCr-ba konvertáljuk
%https://en.wikipedia.org/wiki/YCbCr
I_ycbcr = rgb2ycbcr(I);
Cb = I_ycbcr(:,:,2);
Cr = I_ycbcr(:,:,3);

figure(1)
subplot(2,2,2)
imshow(I_ycbcr);


%B?r detektálása
[r,c,v] = find(Cb>=77 & Cb<=127 & Cr>=133 & Cr<=173);
numind = size(r,1);

%Megjelöli a "b?r pixeleket"
for i=1:numind
    %Az eredeti képen beszínezzük a b?rfelületeket (szemléltetés)
    O(r(i),c(i),:) = [255 0 0];
    %Az eddig csak 0-ból álló tömbbe a b?r helyét feltöltjük 1-esekkel
    BW(r(i),c(i)) = 1;
end

%A kis fekete helyeket a nagyban kitöltjük
BW = imfill(BW, 'holes');
%Eltünteti azt ami 300 pixelnél kissebb (zaj sz?rés)
%Egy már 1024 x 1024-es képen is kicsi az esélye, hogy 30x30 -nál kissebb
%legyen a kéz területe
BW = bwareaopen(BW,900);

%%%%%%%%% Csak az ujjak kellenek%%%%%%%%

%Structuring element létrehozása
se = strel('square',70);
%El?ször eltüntetjük az ujjakat a képr?l, mivel azok mindig kissebbek mint
%a tenyér
BW2 = imerode(BW, se);
%Visszaállítjuk a tenyér méretét
BW2 = imdilate(BW2,se);
%Az így kapott "csak a tenyér" képet kivonjuk az eredetib?l, így megkapjuk
%csak az ujjakat tartalmazó képet
BW3 = imsubtract(BW, BW2);
%30x30 pixelnél kissebb területeket eldobjuk
BW3 = bwareaopen(BW3,900);
%%Mivel csak azokat figyeljük amik nagyok a kivonás után azaz az ujjaink
BW3 = bwareaopen(BW3,9000);
BW = BW3;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure(1)
subplot(2,2,3)
imshow(BW);

st = regionprops(BW, 'All');

%Kiírjuk a workspace-n a területeket számszerüsítve
fprintf(1,'Terulet #    Area\n');
for k = 1 : length(st)
    %"Bedobozolás"
    thisBB = st(k).BoundingBox;
    hold on
    rectangle('Position', [thisBB(1),thisBB(2),thisBB(3),thisBB(4)],...
      'EdgeColor','r','LineWidth',1 );
    hold off
    fprintf(1,'#%2d %16.1f\n',k,st(k).Area);
end

%Rendezzük az elemeket csökken?be a területük szerint
allAreas = [st.Area];
[sortedAreas, sortingIndexes] = sort(allAreas, 'descend');

%Megszámozza a legnagyobbtól a legkissebbig
for k = 1 : length(st)
    centerX = st(sortingIndexes(k)).Centroid(1);
    centerY = st(sortingIndexes(k)).Centroid(2);
    text(centerX,centerY,num2str(k),'Color', 'b', 'FontSize', 14)
end


%Itt nézzük meg, hogy mit is kaptunk:
if sortingIndexes > 0
    if length(sortingIndexes) >= 3
        %Ha kett?nél több ujj van akkor tuti hogy nem olló
        title('PAPER');
    elseif length(sortingIndexes) < 3 && length(sortingIndexes) >= 2
        % Ha 2 akkor pedid tuti, hogy ollót mutatunk
        title('SCRISSORS');
    end
else
    %Minden egyéb esetben K? lesz
    title('ROCK');
end











%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%NEM KELL BELE:
%A második legnagyobb terület lesz a kéz (fej az els?)
% Ez a lépés nem szükséges, ha csak a kezet fotózzuk
%handIndex = sortingIndexes(1);
%Ha több terület van csak akkor kell tör?dni vele
%if length(sortingIndexes) > 1
%    handIndex = sortingIndexes(2);
%end
%Eltüntetünk mindent kivéve a kezét
%[labeledImage, numberOfAreas] = bwlabel(BW);
%HandImage = ismember(labeledImage, handIndex);

%Kivágjuk, hogy csak a kéz legyen a képen
%SubHandImage = imcrop(I, st(handIndex).BoundingBox);
%figure(1)
%subplot(2,2,4)
%imshow(SubHandImage);