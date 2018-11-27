function varargout = FlowLaunch(ServerNumber,ServerTime,MaxFlowSize,LongFlowThreshold,LongFlowProportion);

delete('data.xlsx');%将原来的data文件删除

FlowLauncher = cell(1,ServerNumber);%元胞数组存放
for Initialization = 1:ServerNumber
    FlowLauncher_Initialization = zeros(ServerTime,1);
    for i=1:ServerTime
    if rand(1)<=LongFlowProportion
        FlowLauncher_Initialization(i,1) = LongFlowThreshold+rand(1)*(MaxFlowSize-LongFlowThreshold);
    else
        FlowLauncher_Initialization(i,1) = rand(1)*LongFlowThreshold;
    end
    end
    FlowLauncher{1,Initialization} = FlowLauncher_Initialization;
end

%存储流量模型
for i=1:ServerNumber
   xlswrite('data.xlsx',FlowLauncher{1,i},['Sheet',num2str(i)]);
end

if nargout
    varargout{1} = FlowLauncher;
end