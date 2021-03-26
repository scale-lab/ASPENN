e = [0.608, 0.206, 0.115, 0.106];

X = categorical({'MLP: MAC','SNN: CSA','ASPEN: Exact','ASPEN: Approx'});
X = reordercats(X,{'MLP: MAC','SNN: CSA','ASPEN: Exact','ASPEN: Approx'});

figure;
bar(X,e, 'FaceColor',[0 0 .985],'EdgeColor',[0 0 .4],'LineWidth',2);
ylabel('Energy [\muJ]')
title('Network Energy per Inference')