function [x, info] = inv_RM_mul(m0, Q, P, b, model, inv_para)

if not(isfield(inv_para,'opts'))
    inv_para.opts = [];
end
if not(isfield(inv_para,'params'))
    inv_para.params = [];
end

% global parameters
iter = inv_para.iter;
nf_full = length(model.freq);
nf = inv_para.nf_batchsize;
ns_grid = length(model.xsrc);
ns = inv_para.ns_batchsize;
nrec = length(model.xrec);

innerloop = 0;
outerloop = 0;
success = 0;
infi_loop = 0;
innerloop_list=zeros(iter,1);
residual_list=zeros(2*iter,1);
tau_list=zeros(2*iter,1);
lambda_list=zeros(2*iter,1);

% make subsampling operator
fidx_full = randperm(nf_full);
fidx = sort(fidx_full(1:nf),'ascend');
opFreqSub = opRestriction(nf_full,fidx);

source_encoding_mat = make_encoding_mat(ns_grid,ns,inv_para.encoding_type);
opSourceSub = opRightMulMat([1,ns_grid], source_encoding_mat);

% inversion
while (innerloop < iter) && (not(success)) && (not(infi_loop))
    % re-make subsampling operator if using renrewal
    if inv_para.f_renewal
        fidx_full = randperm(nf_full);
        fidx = sort(fidx_full(1:nf),'ascend');
        opFreqSub = opRestriction(nf_full,fidx);
    end
    if inv_para.s_renewal
        source_encoding_mat = make_encoding_mat(ns_grid,ns,inv_para.encoding_type);
        opSourceSub = opRightMulMat([1,ns_grid], source_encoding_mat);
    end
    
    opSub_Q = oppKron2Lo(opFreqSub, opKron(opSourceSub,opDirac(ns_grid)));
    opSub_b = oppKron2Lo(opFreqSub, opKron(opSourceSub,opDirac(nrec)));

    % subsample Born operator
    Q_sub = opSub_Q*Q;
    Q_sub = invvec(Q_sub, [ns_grid, ns, nf]);
    P_sub = opSub_Q*P;
    P_sub = invvec(P_sub, [ns_grid, ns, nf]);
    QmP_sub = Q_sub-P_sub;
    
    model_sub = model;
    model_sub.freq = transpose(opFreqSub*vec(model.freq));
    
    opBornQmP = oppDF_old(m0(:),QmP_sub,model_sub);
    
    scale_op = inv_para.scale_op;
    opModelMute = inv_para.opModelMute;
    opGetReal = inv_para.opGetReal;
    C = inv_para.C;
    A = scale_op*opBornQmP*opModelMute*opGetReal*C;
    % subsample data
    b_sub = opSub_b*b;
    
    params.nu = inv_para.nu;
    params.hub = inv_para.hub;
    params.rho = inv_para.rho;
    
    % sparse inversion
    [x,~,~,info] = spgl1(A, b_sub, inv_para.tau, inv_para.sigma, ...
                         inv_para.x0, inv_para.opts, params);
    
    outerloop = outerloop + 1;
    innerloop = innerloop + info.iter;
    innerloop_list(outerloop) = info.iter;
    residual_list(innerloop-info.iter+1:innerloop) = info.rNorm2;
    tau_list(innerloop-info.iter+1:innerloop) = info.xNorm1;
    lambda_list(innerloop-info.iter+1:innerloop) = info.lambda;
    inv_para.x0 = x;
    inv_para.tau = norm(x, 1);
    success = ((info.stat >= 1)&&(info.stat <= 4))||(info.stat == 7);
    infi_loop = isequal(info.iter,0);
end

% summerize renewal info
info.innerloop_list=innerloop_list(1:outerloop);
info.residual_list=residual_list(1:innerloop);
info.tau_list=tau_list(1:innerloop);
info.lambda_list=lambda_list(1:innerloop);

if innerloop >= iter
    info.quitStat = 'full_iter';
elseif success == 1
    info.quitStat = 'BP or subOpBP solution found';
elseif infi_loop ==1
    info.quitStat = 'Trapped in infinite loop.';
end