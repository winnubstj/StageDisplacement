function CalcRotations()
clear; close all; clc;
plots = 1;

% Assumes at least 100 um translation between tiles
% I think the signs are correct but not 100% sure.


% 2015-07-11
ystagedisplacement = 401.22;
xstagedisplacement = 326.67;
parent = 'Z:\stitch\2015-07-11';
fnX = '2015-07-19-1044-1045.csv';
fnY = '2015-07-19-1022-1045.csv';
fnXZ = '2015-07-19-1044-1045_XZ.csv';
fnYZ = '2015-07-19-1044-1045_YZ.csv';


z_umperpix = 1;

[x_xpair, y_xpair] = getData(parent, fnX);
dx0 = findXscale(x_xpair, y_xpair, plots);

[x_ypair, y_ypair] = getData(parent, fnY);
dy0 = mean(y_ypair(:,2)-y_ypair(:,1));

x_umperpix = xstagedisplacement./dx0;
y_umperpix = ystagedisplacement./dy0;

[zrot_xpair, zrot_xpair_sd] = findZrot_xpair(x_xpair, y_xpair, x_umperpix, y_umperpix);
[zrot_ypair, zrot_ypair_sd] = findZrot_ypair(x_ypair, y_ypair, x_umperpix, y_umperpix);

[xy_shear, xy_shear_sd] = findYshear(-zrot_xpair, x_ypair, y_ypair, x_umperpix, y_umperpix, plots);
plotYpairs(x_ypair, y_ypair, dy0, plots);

disp(['Xscale: ' num2str(x_umperpix)]);
disp(['Yscale: ' num2str(y_umperpix)]);
disp(['Zscale: ' num2str(z_umperpix)]);
disp(' ');

if ~isempty(fnYZ)
    [y, z] = getData(parent, fnYZ);
    [xrot, sd] = findXrot(y, z, y_umperpix, z_umperpix, plots);
    disp(['X Rotation (y pairs in YZ projection) = ' num2str(xrot) ' degrees [+/- ' num2str(sd)   ']']);
end

if ~isempty(fnXZ)
    [x, z] = getData(parent, fnXZ);
    [yrot, sd] = findYrot(x, z, x_umperpix, z_umperpix, plots);
    disp(['Y Rotation (x pairs in XZ projection) = ' num2str(-1.*yrot) ' degrees [+/- ' num2str(sd)   ']']);
end

disp(['Z Rotation (all x pairs) = ' num2str(-1.*zrot_xpair) ' degrees [+/- ' num2str(zrot_xpair_sd) ']']);
disp(['Z Rotation (all y pairs) = ' num2str(-1.*zrot_ypair) ' degrees [+/- ' num2str(zrot_ypair_sd) ']']);
disp(' ');
disp(['X-Y shear  (all y pairs) = ' num2str(-1.*xy_shear)   ' degrees [+/- ' num2str(xy_shear_sd)   ']']); 











function plotYpairs(x_ypair, y_ypair, dy0, plots)
if ~plots
    return;
end

subplot(2,2,2);
plot(x_ypair(:,1), y_ypair(:,2)-y_ypair(:,1), 'k.');
xlabel('X position (pix)');
ylabel('Y feature displacement (pix)');
title('Tiles bordering in Y');

subplot(2,2,[3 4]); hold on;
plot(x_ypair(:,1), y_ypair(:,1), 'k.');
plot(x_ypair(:,2), y_ypair(:,2)-dy0, 'r.');

for i = 1:size(x_ypair,1)
    plot([x_ypair(i,1) x_ypair(i,2)], [y_ypair(i,1) y_ypair(i,2)-dy0], 'k-');
end
title('Tiles bordering in Y');
xlabel('X position (pix)');
ylabel('Y position in overlap region (pix)');


function [shear, sd] = findYshear(zrot, x, y, x_umperpix, y_umperpix, plots)
N = size(x,1);
shear = zeros(N, 1);
dx = zeros(N, 1);
dy = zeros(N, 1);
xest = zeros(N, 1);


for i = 1:N
    dx(i) = (x(i,2)-x(i,1)).*x_umperpix;
    dy(i) = (y(i,2)-y(i,1)).*y_umperpix;
    
    xest(i) = dy(i).*tan(zrot*pi/180);
    
    xdif = dx(i)-xest(i);
    shear(i) = xdif/dy(i);
    
end


sd = std(shear);
shear = mean(shear);

if plots
    edges = -10:0.2:10;
    [n, ~] = histc(dx, edges);
    [nWithRot, ~] = histc(dx-xest, edges);
    [nWithRotAndShear, ~] = histc(dx-xest+shear*dy, edges);
    
    figure; set(gcf, 'Units', 'Normalized', 'Position', [0.05 0.05 0.7 0.8]); 
    subplot(2,2,1); hold on;
    plot(edges, n, 'k', 'LineWidth', 2);
    plot(edges, nWithRot, 'r', 'LineWidth', 2);
    plot(edges, nWithRotAndShear, 'b', 'LineWidth', 2);
    
    xlabel('X displacement (um)');
    ylabel('Count');
    title('X-Y shear correction');
    legend('Original displacement', 'with z rotation', 'with z rotation and shear');
end


function [xrot, sd] = findXrot(y, z, y_umperpix, z_umperpix, plots)
xrot = zeros(size(y,1), 1);
for i = 1:size(y,1)
    xrot(i) = 180/(pi)* atan(z_umperpix*(z(i,2)-z(i,1))./(y_umperpix*(y(i,2)-y(i,1))));
end

if plots
    figure;
    hist(z(:,1)-z(:,2), 100);
    xlabel('Z feature displacement (in pix, for rotation about X)');
    ylabel('Count');
end

sd = std(xrot);
xrot = mean(xrot);


function [yrot, sd] = findYrot(x, z, x_umperpix, z_umperpix, plots)
yrot = zeros(size(x,1), 1);
for i = 1:size(x,1)
    yrot(i) = 180/(pi)* atan(z_umperpix*(z(i,2)-z(i,1))./(x_umperpix*(x(i,2)-x(i,1))));
end

if plots
    figure;
    hist(z(:,1)-z(:,2), 100);
    xlabel('Z feature displacement (in pix, for rotation about Y)');
    ylabel('Count');
end

sd = std(yrot);
yrot = mean(yrot);


function [zrot_xpair, sd] = findZrot_xpair(x, y, x_umperpix, y_umperpix)
rot = zeros(size(y, 1), 1);
for i = 1:size(y,1)
    rot(i) = 180/(pi)* atan(y_umperpix*(y(i,2)-y(i,1))./(x_umperpix*(x(i,2)-x(i,1))));
end
zrot_xpair = mean(rot);
sd = std(rot);


function [zrot_ypair, sd] = findZrot_ypair(x, y, x_umperpix, y_umperpix)
rot = zeros(size(x, 1), 1);
for i = 1:size(y,1)
    rot(i) = 180/(pi)* atan(x_umperpix*(x(i,2)-x(i,1))./(y_umperpix*(y(i,2)-y(i,1))));
end
zrot_ypair = mean(rot);
sd = std(rot);


function d0 = findXscale(x, y, plots)
disp('Field curvature parameters (from x pairs):');
dist = (x(:,2)-x(:,1));

p = [850 1e-5 850];
pos = round(0:max(y(:,1)))';
out = nlinfit(y(:,1), dist, @model, p);
distmodel = out(3)-out(2)*((pos-out(1)).^2);

d0 = out(3);
xpixshift = (out(2)./out(3))*((y(:,1)-out(1)).^2);
scale = (1+xpixshift);

newx = scaleX(x, scale, 512);  %512 is midpoint in X

if plots
    figure; 
    set(gcf, 'Units', 'Normalized', 'Position', [0.05 0.1 0.7 0.8]); hold on;
    
    subplot(2,2,3); hold on;
    plot((x(:,2)-x(:,1)), y(:,1), 'k.');
    plot(distmodel, pos, 'r-');
    plot((newx(:,2)-newx(:,1)), y(:,1), 'b.');
    
    xlabel('X displacement (pix)');
    ylabel('Y position (pix)');
    title('Tiles bordering in X');
    legend('Before field curvature correction', 'Field curvature model', ...
        'After correction', 'Location', 'Best');    
    
    subplot(2,2,[2 4]); hold on
    plot(x(:,1), y(:,1), 'k.'); 
    plot(x(:,2)-d0, y(:,2), 'r.');
    for i = 1:size(x,1)
        plot([x(i,1) x(i,2)-d0], [y(i,1) y(i,2)], 'k-');
    end
    xlabel('X position in overlap region (pix)');
    ylabel('Y position (pix)');
    title('Tiles bordering in X');
    
    subplot(2,2,1); hold on;
    hist(y(:,2)-y(:,1), 100);
    xlabel('Y displacement (in pix, for rotation about Z)');
    ylabel('Count');
end

preErr = mean(abs(x(:,2)-x(:,1)-d0));
postErr = mean(abs(newx(:,2)-newx(:,1)-d0));

disp(['    ymidpt: ' num2str(out(1))]);
disp(['    scale: ' num2str(out(2))]);
disp(['    midFOV: ' num2str(out(3))]);
disp(['    x position mismatch reduced from ' num2str(preErr) ' to ' num2str(postErr) ' pixels by FC correction']);
disp(' ');


function newx = scaleX(x, scale, xmid)

newx = zeros(size(x));
for i = 1:size(x,1)
    xdif = x(i,:)-xmid;
    newxdif = xdif.*scale(i);
    newx(i,:) = xmid+newxdif;
end


function [x, y] = getData(parent, fn)
M = csvread(fullfile(parent, fn), 1,1);
id = unique(M(:,3));
if numel(id)~=2
    disp('Didnt find two sets');
end
ind1 = find(M(:,3)==id(1));
ind2 = find(M(:,3)==id(2));

if numel(ind1)~=numel(ind2)
    disp('Points dont corresond');
end
    
y(:,1) = M(ind1,2);
y(:,2) = M(ind2,2);
x(:,1) = M(ind1,1);
x(:,2) = M(ind2,1);

if mean(x(:,2)-x(:,1))<-100
    x = fliplr(x);
    y = fliplr(y);
end

if mean(y(:,2)-y(:,1))<-100
    x = fliplr(x);
    y = fliplr(y);
end


function fy = model(p, y)
fy = p(3) - p(2).*((y-p(1)).^2);




