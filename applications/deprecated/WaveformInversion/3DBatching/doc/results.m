%% 3D Frequency-domain FWI with batching: results
% 


%% CARP-CG
% Here we present some results of the Helmholtz solver on the overthrust
% model. The model and a wavefield for 2 Hz are shown below.

%
% read model
p = 4;
[v,n,d,o] = rsf_read_all(['../results/carpcg0/v_' num2str(p) '_1.rsf']);
[u,n,d,o] = rsf_read_all(['../results/carpcg0/u_' num2str(p) '_1.rsf']);
table0    = dlmread(['../results/carpcg0/table.dat'],',',1,0);

[z,x,y] = odn2grid(o,1e-3*d,n);

figure;h=slice(x,y,z,permute(v,[3 2 1]),mean(x),mean(y),mean(z));axis equal;
set(h(:),'linestyle','none');set(gca,'zdir','reverse');
xlabel('x [km]');ylabel('y [km]');zlabel('z [km]');

figure;h=slice(x,y,z,permute(real(u),[3 2 1]),mean(x),mean(y),mean(z));caxis([-1 1]*5e-5);colormap(gray);axis equal;
set(h(:),'linestyle','none');set(gca,'zdir','reverse');
xlabel('x [km]');ylabel('y [km]');zlabel('z [km]');

%%
% We compute the wavefield for various frequencies with a fixed number of
% gridpoints per wavelength. The convergence histories are shown below

figure;
color = {'k','r','b'};
i = 1;
for p = [16 8 4]
    res1 = dlmread(['../results/carpcg0/res_' num2str(p) '_1_1.dat']);
    semilogy(1:length(res1),res1,color{i});hold on;ylim([1e-6 1]); 
    lgs{i} = ['f = ' num2str(table0(i,1)) ' Hz.'];
    i = i + 1;
end
legend(lgs{:});xlabel('iteration');ylabel('residual');

%%
% We compute the wavefield for 1 Hz for 50 point-sources distributed
% randomly across the surface using various block-sizes in block-CG.
% The convergence histories are shown below

table1 = dlmread(['../results/carpcg1/table.dat'],',',1,0);

figure;
color = {'k','r','b','g'};
i = 1;
for bs = [1 2 5 50]
    res = dlmread(['../results/carpcg1/res_8_1_' num2str(bs) '.dat']);
    semilogy(1:size(res,1),mean(res,2),color{i});hold on;ylim([1e-6 1]); 
    lgs{i} = ['blocksize = ' num2str(50/bs)];
    i = i + 1;
end
legend(lgs{:});xlabel('iteration');ylabel('residual');



%%
% We compute the wavefield for 2 Hz using 1,2 or 4 processors. The
% convergence histories and speedup are plotted below

table2 = dlmread(['../results/carpcg2/table.dat'],',',1,0);

figure;
color = {'k','r','b'};
i = 1;
for np = [1 2 4]
    res = dlmread(['../results/carpcg2/res_4_' num2str(np) '_1.dat']);
    semilogy(1:length(res),res,color{i});hold on;ylim([1e-6 1]); 
    lgs{i} = ['np = ' num2str(np)];
    i = i + 1;
end
legend(lgs{:});xlabel('iteration');ylabel('residual');

figure; plot(table2(:,5),table2(1,9)./table2(:,9),table2(:,5),table2(:,5),'k--');
xlabel('np');ylabel('speedup'); legend('actual speedup','linear speedup')

%% FWI
% We present some examples on a simple 3D model depicted below


[m,n,d,o]  = rsf_read_all(['../data/edam_mt.rsf']);
[m1,n,d,o] = rsf_read_all(['../results/edam1/m1.rsf']);
[m2,n,d,o] = rsf_read_all(['../results/edam2/m1.rsf']);
[m3,n,d,o] = rsf_read_all(['../results/edam3/m1.rsf']);

[z,x,y]   = odn2grid(o,1e-3*d,n);

figure;
slice(z,x,y,permute(1./sqrt(m),[3 1 2]),.5,.5,.5);caxis([2.25 2.75])
xlabel('x [km]');ylabel('y [km]');zlabel('z [km]')

%%
% The results when using approximate PDE solves to compute the gradients
% are given below. We consider three scenario's
% 
% * fixed low accuracy \(\epsilon = 10^{-3}\)
% * gradually increasing accuracy \(\epsilon_k = (0.8)^k \cdot 10^{-3}\)
% * fixed high accuracy \(\epsilon = 10^{-6}\)

for k = 0:11
    mt     = dlmread(['../results/edam1/xm1/x_' num2str(k) '.dat']);
    e1(k+1) = norm(mt - m(:));
end

for k = 0:11
    mt     = dlmread(['../results/edam2/xm1/x_' num2str(k) '.dat']);
    e2(k+1) = norm(mt - m(:));
end

for k = 0:11
    mt     = dlmread(['../results/edam3/xm1/x_' num2str(k) '.dat']);
    e3(k+1) = norm(mt - m(:));
end

figure;
slice(z,x,y,permute(1./sqrt(m1),[3 1 2]),.5,.5,.5);caxis([2.25 2.75]);
xlabel('x [km]');ylabel('y [km]');zlabel('z [km]');
title('fixed low accuracy')

figure;
slice(z,x,y,permute(1./sqrt(m2),[3 1 2]),.5,.5,.5);caxis([2.25 2.75]);
xlabel('x [km]');ylabel('y [km]');zlabel('z [km]');
title('gradually increasing accuracy')

figure;
slice(z,x,y,permute(1./sqrt(m3),[3 1 2]),.5,.5,.5);caxis([2.25 2.75]);
xlabel('x [km]');ylabel('y [km]');zlabel('z [km]');
title('fixed high accuracy')

figure;
plot(0:11,e1/e1(1),0:11,e2/e2(1),0:11,e3/e3(1));
xlabel('iteration');ylabel('rel. model error')
legend('low','increasing','high');
