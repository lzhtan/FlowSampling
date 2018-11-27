%FLow Sampling Programme
clear all;
close all;
format long %增加生成小数的位数到20位
%参数设置
RunTime = 10000000;%持续发包时间，34万个包相当于1G吞吐量的交换机50%负载工作1秒钟
%1000000000相当于1G交换机50分钟工作
ServerTime = 1000;%各个终端持续发包时间长度
LongFlowProportion = 0.1;%长流数量占比
PacketSize = 1500;%数据包规格
LongFlowThreshold = 15000;%长流判定阈值，意味着10个包
MaxFlowSize = 15000000;%最大流规格
ServerNumber = 10;%模拟终端个数
p=0.00001;
p_first=0.00001;%采样概率，初始阈值为50%

Switches_LongFlow_List=zeros(1,3);%交换机缓存
Controller_LongFlow_List=zeros(1,4);%控制器缓存
Controller_LongFlow_List_1=zeros(1,4);%控制器缓存镜像
LongFlowNumber=0;%长流总数量参数
HowLongController_LongFlow_List=zeros(1);%控制器缓存平均队列长度
TCPNumber=0;%与p相关的参数
SamplingNumber=zeros(1,1);%采样间隔
SamplingNum=0;%采样间隔计数器

%初始化(两种方法，利用FlowLaunch新创建，或者读取data中已经有的，对于需要比较的用读取方式)

FlowLauncher = FlowLaunch(ServerNumber,ServerTime,MaxFlowSize,LongFlowThreshold,LongFlowProportion);

%读取流量模型
%  for Initialization=1:ServerNumber
%     FlowLauncher{1,Initialization}=xlsread('data.xlsx',['Sheet',num2str(Initialization)],['A1:A',num2str(ServerTime)]);
%  end


%备份流数据
FlowLauncher_Copy=FlowLauncher;

%仿真流程
for i=1:RunTime
   %转发数据包
   
   SamplingNum=SamplingNum+1;
   Selection = unidrnd(ServerNumber);%随机处理客户端请求
   
   if sum(sum(FlowLauncher{1,Selection}))~=0; %判断矩阵不全为0
       
   flag = max(find(FlowLauncher{1,Selection}==0));
   flag = flag+1;
   if isempty(flag) == 1
       flag = 1;
   end
   if  FlowLauncher{1,Selection}(flag,1)>=1500
       TCPNumber=TCPNumber+1500;
       FlowLauncher{1,Selection}(flag,1) = FlowLauncher{1,Selection}(flag,1)-1500;
   else
       TCPNumber=TCPNumber+FlowLauncher{1,Selection}(flag,1);
       FlowLauncher{1,Selection}(flag,1) = FlowLauncher{1,Selection}(flag,1)-FlowLauncher{1,Selection}(flag,1);
   end
   
   
   
      %长流查询及注册（p与网络流量相关）
   LongFlow_Flag = find((Switches_LongFlow_List(:,1)==Selection&Switches_LongFlow_List(:,2)==flag)==1);
   if isempty(LongFlow_Flag) == 1   %若交换机缓存表中无对应长流数据，则按照概率p进行采样并记录
       
      if rand(1)<=p
      Switches_LongFlow_List=[Switches_LongFlow_List;Selection flag 1];
      SamplingNumber=[SamplingNumber;SamplingNum]; %记录采样间隔
      SamplingNum=0;
      
      %调整p值
       if rem(TCPNumber,1500)==0
           p=0.1*p+0.9*p_first;
           %p=1.01*p;
           TCPNumber=0;
       else
           p=0.9*p+0.1*p_first;
           %p=0.9*p_first;
           TCPNumber=0;
       end
       
       end
   elseif Switches_LongFlow_List(LongFlow_Flag,3)<10
       Switches_LongFlow_List(LongFlow_Flag,3)=Switches_LongFlow_List(LongFlow_Flag,3)+1;
   elseif Switches_LongFlow_List(LongFlow_Flag,3) == 10
       if isempty(find((Controller_LongFlow_List(:,1)==Selection&Controller_LongFlow_List(:,2)==flag)==1))==1
       Controller_LongFlow_List = [Controller_LongFlow_List;Switches_LongFlow_List(LongFlow_Flag,:) (FlowLauncher_Copy{1,Selection}(flag,1)-FlowLauncher{1,Selection}(flag,1))/1500 ];%长流统计并通告
       Controller_LongFlow_List_1 = [Controller_LongFlow_List_1;Switches_LongFlow_List(LongFlow_Flag,:) (FlowLauncher_Copy{1,Selection}(flag,1)-FlowLauncher{1,Selection}(flag,1))/1500 ];
       %镜像中失活长流删除
       if  isempty(Controller_LongFlow_List_1(:,1)==Selection&Controller_LongFlow_List_1(:,2)<flag-2)==0
            Controller_LongFlow_List_1(find(Controller_LongFlow_List_1(:,1)==Selection&Controller_LongFlow_List_1(:,2)<flag-2),:)=[];%删除相应记录
       end
       end
   end
   
   
   
   
   
   %长流查询及注册(等间隔采样)
%    LongFlow_Flag = find((Switches_LongFlow_List(:,1)==Selection&Switches_LongFlow_List(:,2)==flag)==1);
%    
%    if isempty(LongFlow_Flag) == 1   %若交换机缓存表中无对应长流数据，则按照概率p进行采样并记录
%       if rand(1)<=p;
%       Switches_LongFlow_List=[Switches_LongFlow_List;Selection flag 1];
%       SamplingNumber=[SamplingNumber;SamplingNum]; %记录采样间隔
%       SamplingNum=0;
%        end
%    elseif Switches_LongFlow_List(LongFlow_Flag,3)<10
%        Switches_LongFlow_List(LongFlow_Flag,3)=Switches_LongFlow_List(LongFlow_Flag,3)+1;
%    elseif Switches_LongFlow_List(LongFlow_Flag,3) == 10
%        if isempty(find((Controller_LongFlow_List(:,1)==Selection&Controller_LongFlow_List(:,2)==flag)==1))==1
%        Controller_LongFlow_List = [Controller_LongFlow_List;Switches_LongFlow_List(LongFlow_Flag,:) (FlowLauncher_Copy{1,Selection}(1,flag)-FlowLauncher{1,Selection}(1,flag))/1500 ];%长流统计并通告
%        Controller_LongFlow_List_1 = [Controller_LongFlow_List_1;Switches_LongFlow_List(LongFlow_Flag,:) (FlowLauncher_Copy{1,Selection}(1,flag)-FlowLauncher{1,Selection}(1,flag))/1500 ];
%        %镜像中失活长流删除
%        if  isempty(Controller_LongFlow_List_1(:,1)==Selection&Controller_LongFlow_List_1(:,2)<flag-2)==0
%             Controller_LongFlow_List_1(find(Controller_LongFlow_List_1(:,1)==Selection&Controller_LongFlow_List_1(:,2)<flag-2),:)=[];%删除相应记录
%        end
%        end
%    end
    
   %控制器缓存队列长度查询
   if  rem(i,500) == 0 %间隔10000次查询一次控制器缓存队列长度
   HowLongController_LongFlow_List=[HowLongController_LongFlow_List;size(Controller_LongFlow_List_1,1)];
   end
   
   
   
   
   end%判断矩阵不全为0
end


%结果
%漏检率
ControllerLongFlowNumber = size(Controller_LongFlow_List,1)-1;%已捕获长流数量（减去第1行全0）
for i=1:ServerNumber
    LongFlowNumber=LongFlowNumber+size(find(FlowLauncher_Copy{1,i}>LongFlowThreshold),1);
end
RatioofFalsePositive=1-ControllerLongFlowNumber/LongFlowNumber%漏检率
%平均流检测所需数据包个数
MaxController_LongFlow = max(Controller_LongFlow_List(2:size(Controller_LongFlow_List,1),4));%最大所需数据包个数
MinController_LongFlow = min(Controller_LongFlow_List(2:size(Controller_LongFlow_List,1),4));%最小所需数据包个数
MedianController_LongFlow = median(Controller_LongFlow_List(2:size(Controller_LongFlow_List,1),4));%中位数
MeanController_LongFlow = mean(Controller_LongFlow_List(2:size(Controller_LongFlow_List,1),4));%均值
VarController_LongFlow = var(Controller_LongFlow_List(2:size(Controller_LongFlow_List,1),4));%方差
%队列长度记录
HowLongController_LongFlow_List;%记录队列长度
%平均采样间隔
Mean_SamplingNumber = mean(SamplingNumber(2:size(SamplingNumber),1));%平均采样间隔
Size_SamplingNumber = size(SamplingNumber)-1;%采样总次数



%Figure
figure(1)%流分布
for i = 1: ServerNumber
    figure_1(i,:)= FlowLauncher_Copy{1,i};
    for j = 1:10
    figure_1_StatisticalValue(1,j) = length(find(figure_1>0.1*(j-1)*MaxFlowSize&figure_1<0.1*j*MaxFlowSize));
    figure_1_StatisticalSumValue = find(figure_1>=0.1*(j-1)*MaxFlowSize&figure_1<0.1*j*MaxFlowSize);
    figure_1_StatisticalSum(1,j)= sum(figure_1(figure_1_StatisticalSumValue));
    end
end
c = figure_1(1,1:1000);sz =35;
scatter(1:1000,figure_1(1,1:1000),sz,c,'square','filled')
axis([-10 1010 0 1600000]);
set(gcf, 'Color', [1,1,1]);
xlabel('Flow Sequence','FontName','Times New Roman','FontSize',15);
ylabel('Flow Size(KB)','FontName','Times New Roman','FontSize',15);

figure(2)%控制器队列长度
plot(1:(size(HowLongController_LongFlow_List,1)-19),HowLongController_LongFlow_List(20:size(HowLongController_LongFlow_List),1),'color',[0 0 0],'LineWidth',1)
hold on;
line([1,(size(HowLongController_LongFlow_List,1)-19)],[max(HowLongController_LongFlow_List(20:size(HowLongController_LongFlow_List),1)),max(HowLongController_LongFlow_List(2:size(HowLongController_LongFlow_List),1))],'linestyle',':','color',[20/255  68/255 106/255],'LineWidth',1)
hold on;
line([1,(size(HowLongController_LongFlow_List,1)-19)],[min(HowLongController_LongFlow_List(20:size(HowLongController_LongFlow_List),1)),min(HowLongController_LongFlow_List(20:size(HowLongController_LongFlow_List),1))],'linestyle',':','color',[69/255  39/255 39/255],'LineWidth',1)
% hold on;
% line([1,(size(HowLongController_LongFlow_List,1)-1)],[mean(HowLongController_LongFlow_List(2:size(HowLongController_LongFlow_List),1)),mean(HowLongController_LongFlow_List(2:size(HowLongController_LongFlow_List),1))],'linestyle','--','color',[131/255  175/255 155/255],'LineWidth',1)
text(50,0.65+max(HowLongController_LongFlow_List(2:size(HowLongController_LongFlow_List),1)),'Maximum queue length','FontName','Times New Roman','FontSize',13)
text(620,-0.65+min(HowLongController_LongFlow_List(100:size(HowLongController_LongFlow_List),1)),'Minimum queue length','FontName','Times New Roman','FontSize',13)
%text(1,0.25+mean(HowLongController_LongFlow_List(2:size(HowLongController_LongFlow_List),1)),'Average queue length','FontName','Times New Roman','FontSize',10)
xlabel('Simulation Time(s)','FontName','Times New Roman','FontSize',15);
ylabel('Controller Queue Length','FontName','Times New Roman','FontSize',15);
axis([0 size(HowLongController_LongFlow_List,1) 0.7*min(HowLongController_LongFlow_List(2:size(HowLongController_LongFlow_List,1))) max(HowLongController_LongFlow_List)*1.2]);



figure(2)%控制器队列长度
plot(1:1200,HowLongController_LongFlow_List(20:1219,1),'color',[0 0 0],'LineWidth',1)
% line([1,(size(HowLongController_LongFlow_List,1)-1)],[mean(HowLongController_LongFlow_List(2:size(HowLongController_LongFlow_List),1)),mean(HowLongController_LongFlow_List(2:size(HowLongController_LongFlow_List),1))],'linestyle','--','color',[131/255  175/255 155/255],'LineWidth',1)
xlabel('Simulation time(s)','FontName','Times New Roman','FontSize',15);
ylabel('Length of queue','FontName','Times New Roman','FontSize',15);
axis([1 1200 0.7*min(HowLongController_LongFlow_List(2:size(HowLongController_LongFlow_List,1))) max(HowLongController_LongFlow_List)*1.2]);




figure(3)%采样间隔
plot(1:50,SamplingNumber(1:50),'color',[0 0 0],'LineWidth',1)
xlabel('Number of Samples','FontName','Times New Roman','FontSize',15);
ylabel('Sample Interval Packet Number','FontName','Times New Roman','FontSize',15);
%axis([0 size(SamplingNumber,1) 0.7*min(HowLongController_LongFlow_List(2:size(HowLongController_LongFlow_List,1))) max(HowLongController_LongFlow_List)*1.2]);
