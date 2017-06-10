function mapping()
    addpath('kmeans');

    % settings
    do_printEdges = 1;
    do_textured_plot = 0;
    do_scatterplot = 0;
    do_clustered_scatterplot = 0;
    do_mesh = 0;

    n_objects = 2;

    % choose right directory of images
    path = uigetdir;
    % and texture file (image with everything in focus)
    [txtname, txtpath] = uigetfile;
    texture_image = B = rot90(imread( fullfile(txtpath, txtname) ), -1);
    
    imshow(texture_image)

    fnames = dir([path '\*.JPG']);
    numfids = length(fnames);

    for K = 1:numfids
        pic = imread([ path, '\', fnames(K).name ]);
        pic = rgb2gray(pic);
        % pic = imgaussfilt(pic, 7);
        [BW,threshOut] = edge(pic, 'sobel', 0.05);

        % a peek at the edges
        if do_printEdges
            figure(1);
            imshow(BW);
            xlabel('X'); ylabel('Y'); zlabel('Z');
        end
        imgEdge(:,:,K) = BW;
    end

    imgEdge = flipdim(imgEdge, 1);
    [x,y,z] = ind2sub(size(imgEdge),find(imgEdge == 1));


    if do_textured_plot
        % add texture
        flat_z = zeros(size(BW));
        for i = 1:numfids
            flat_z = flat_z.*((flat_z - double(imgEdge(:,:,i)))>0);
        end

        xmin = min(x);
        xmax = max(x);
        ymin = min(y);
        ymax = max(y);
        F = TriScatteredInterp(x(:),y(:),z(:)*100);  %# Create interpolant
        N = 500;  %# Number of y values in uniform grid
        M = 500;  %# Number of x values in uniform grid
        xu = linspace(xmin,xmax,M);      %# Uniform x-coordinates
        yu = linspace(ymin,ymax,N);      %# Uniform y-coordinates
        [X,Y] = meshgrid(xu,yu);         %# Create meshes for xu and yu
        Z = F(X,Y);                      %# Evaluate interpolant (N-by-M matrix)
        figure(2);
        h = surf(X,Y,Z,texture_image,...  %# Plot surface
                 'FaceColor','texturemap',...
                 'EdgeColor','none');
        axis equal
        view(90,-88);
    end


    % from pixel to mm
    x = x/(min(size(BW)))*70;
    y = y/(max(size(BW)))*105;
    z = z*8;

    if do_scatterplot
        % scatter with no grouping
        figure(3)
        scatter3(x, y, z, [])
        view(90, -90)
        xlabel('X'); ylabel('Y'); zlabel('Z');
        axis equal
    end

    % cluster points
    X = [x.'; y.'; z.'];
    group = kmeans(X,n_objects);
    
    if do_clustered_scatterplot
        figure(4)
        scatter3(x, y, z, [], group)
        view(90, -90)
        xlabel('X'); ylabel('Y'); zlabel('Z');
        axis equal
    end

    % put points into groups
    object(1).x = [];
    object(2).x = [];
    object(3).x = [];

    object(1).y = [];
    object(2).y = [];
    object(3).y = [];

    object(1).z = [];
    object(2).z = [];
    object(3).z = [];

    for ii = 1:length(group);
        object(group(ii)).x = [object(group(ii)).x x(ii)];
        object(group(ii)).y = [object(group(ii)).y y(ii)];
        object(group(ii)).z = [object(group(ii)).z z(ii)];
    end


    if do_mesh
        figure(5)
        hold on
        for o = 1:n_objects
            DT = delaunayTriangulation(object(o).x', object(o).y', object(o).z');
            [K,v] = convexHull(DT);
            trisurf(K, DT.Points(:,1), DT.Points(:,2), fliplr(DT.Points(:,3)), 'Facecolor', 'red', 'FaceAlpha', 0.1)
        end
        view(90, -90)
        xlabel('Y'); ylabel('X'); zlabel('Z');
        hold off
        axis equal
    end
end