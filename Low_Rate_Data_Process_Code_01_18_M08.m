%% This code is used to process the Low Rate Data
% GEL - EPFL - 2024
% Developed by Mohsen Talebkeikhah

%% cleanup first, set global parameters, and input initial values
clc
clear
close all

%% loading the low rate data (EC Probe + Pressure transducers + GDS pump)
% time in second, pressure in MPa, and opening in micrometer
% opening measurement system
T_W_Data = xlsread('Opening_Measurement_Output.xlsx');

% Pressure
LowRateData=readtable('162922.csv');

Time=LowRateData.Time;
Time=Time-Time(1);

Upstream_P=LowRateData.LFmeasurement3;
Downstream_P2=LowRateData.LFmeasurement2; % pressure transducer close to the wellbore - inside frame
Upstream_P=Upstream_P-mean(Upstream_P(1:1000)); % to remove the initial bias
Downstream_P2=Downstream_P2-mean(Downstream_P2(1:1000)); % to remove the initial bias

% pressure and volume of confinement stresses measured by GDS pump
GDS1P=LowRateData.Pump1Pressure;
GDS2P=LowRateData.Pump2Pressure;
GDS3P=LowRateData.Pump3Pressure;
GDS1V=LowRateData.Pump1Volume;
GDS2V=LowRateData.Pump2Volume;
GDS3V=LowRateData.Pump3Volume;

%% Read the data of top industry
fid1=fopen('TopIndustry_Pump_01.txt');
    a111=1;
    industrial_pump_data1=[];
    while ~feof(fid1)
        if a111==1
            industrial_pump_headers = split(fgetl(fid1),",")';
            a111=a111+1;
            continue;
        end
        tline=fgetl(fid1);
        newStr = split(tline,",")';
        time_calc_temp=str2double(newStr{2}(1:2))*3600+str2double(newStr{2}(4:5))*60+str2double(newStr{2}(7:8));
        industrial_pump_data1=[industrial_pump_data1; [time_calc_temp str2double(newStr{3}),...
                                                     str2double(newStr{4}),str2double(newStr{5}),str2double(newStr{6})]];
        
        a111=a111+1;
    end
fclose(fid1);

fid2=fopen('TopIndustry_Pump_02.txt');
    a111=1;
    industrial_pump_data2=[];
    while ~feof(fid2)
        if a111==1
            industrial_pump_headers = split(fgetl(fid2),",")';
            a111=a111+1;
            continue;
        end
        tline=fgetl(fid2);
        newStr = split(tline,",")';
        time_calc_temp=str2double(newStr{2}(1:2))*3600+str2double(newStr{2}(4:5))*60+str2double(newStr{2}(7:8));
        industrial_pump_data2=[industrial_pump_data2; [time_calc_temp str2double(newStr{3}),...
                                                     str2double(newStr{4}),str2double(newStr{5}),str2double(newStr{6})]];
        
        a111=a111+1;
    end
fclose(fid2);

% Display the extracted data
TopIndustry_matrix = [industrial_pump_data1;industrial_pump_data2];
TopIndustry_matrix=[TopIndustry_matrix(:,1)-TopIndustry_matrix(1,1),TopIndustry_matrix(:,2:end)];

base_TI_pump_pressure=mean(TopIndustry_matrix(1:30,4));

% from first injection point
TopIndustry_data=[TopIndustry_matrix(43:end,1)-TopIndustry_matrix(43,1),TopIndustry_matrix(43:end,2:3),...
                  (TopIndustry_matrix(43:end,4)-base_TI_pump_pressure)/10,TopIndustry_matrix(43:end,5)];

TopIndustry_data(TopIndustry_data(:,3)==13,:)=[];

%% sync timing
Time=Time+100;
TopIndustry_data=[TopIndustry_data(:,1)+140,TopIndustry_data(:,2:end)];

%% Remove time resonance in pressure data
matrix_P=[Time,Downstream_P2,Upstream_P];

sorted_matrix_P = sortrows(matrix_P, 1);

% Remove rows where the first column value is equal to the previous one
cleaned_matrix_P = sorted_matrix_P([true; diff(sorted_matrix_P(:,1)) ~= 0], :);

%% Smoothing
time_smth=cleaned_matrix_P(1:5:end,1);
Downstream_P2_smth=smooth(time_smth,cleaned_matrix_P(1:5:end,2),0.005);
Upstream_P_smth=smooth(time_smth,cleaned_matrix_P(1:5:end,3),0.005);
pump_TI_smth=smooth(TopIndustry_data(:,1),TopIndustry_data(:,4),0.005);

%% AE's counts
close all
AEdata=readtable('catalog-AE-count-M08.csv');

time_shift=246;

AEsTime=time_shift+AEdata.relative_time;

figure
histogram(AEsTime,500)

%% Result plots
close all

figure
plot(Time,Upstream_P)
hold on;
% plot(Time,Downstream_P1)
plot(Time,Downstream_P2)
% plot(Time,Downstream_P1-4.5,'r--')
yline(7,'k--','\sigma = 5 MPa')
% plot(Time,Downstream_P2)
% plot(Time,Noisy_P)
% plot(LF4)
% plot(LF5)
% plot(LF6)
% plot(LF7)
% plot(LF8)
% plot(LF9)
xlabel('time (s)')
ylabel('Pressure (MPa)')
grid on;
% ylim([0 25])
legend('P_{upstream}','P_{downstream1}','P_{downstream2}')

figure
plot(Time,GDS1P/1000);
hold on;
plot(Time,GDS2P/1000);
plot(Time,GDS3P/1000);
xlabel('time (s)', 'FontSize', 16)
ylabel('Pressure (MPa)', 'FontSize', 16)
legend('GDS-1','GDS-2','GDS-3', 'FontSize', 16);
set(gca, 'FontSize', 16);

figure
plot(Time,GDS1V);
hold on;
plot(Time,GDS2V);
plot(Time,GDS3V);
xlabel('time (s)', 'FontSize', 16)
ylabel('Volume (ml)', 'FontSize', 16)
legend('GDS-1','GDS-2','GDS-3', 'FontSize', 16);
set(gca, 'FontSize', 16);


% DATA_P=[Time+0 Upstream_P Downstream_P1 Downstream_P2];
% 
% xlswrite('Pressure_Data.xlsx',DATA_P)
% xlswrite('Opening_Data.xlsx',T_W_Data)

%
figure
subplot(2,1,1)
plot(T_W_Data(:,1),T_W_Data(:,2))
ylabel('\omega (\mum)', 'FontSize', 16)
set(gca, 'FontSize', 16);

subplot(2,1,2)
yyaxis right;
plot(TopIndustry_data(:,1),TopIndustry_data(:,2))
xlabel('time (s)', 'FontSize', 16)
ylabel('Q_{0} (ml/min)', 'FontSize', 16)
grid on;
ylim([0 3])
set(gca, 'FontSize', 16);

yyaxis left;
plot(TopIndustry_data(:,1),pump_TI_smth,'b-')
hold on;
plot(time_smth,Upstream_P_smth,'r-')
% plot(time_smth,Downstream_P1_smth,'m-')
plot(time_smth,Downstream_P2_smth,'k-')
yline(8,'k-','\sigma = 8 MPa', 'FontSize', 14)
xlabel('time (s)', 'FontSize', 16)
ylabel('Pressure (MPa)', 'FontSize', 16)
grid on;
set(gca, 'FontSize', 16);
xlim([0 30000])
legend('P_{pump}','P_{upstream}','P_{downstream2}')

figure
subplot(2,1,1)
yyaxis left;
plot(T_W_Data(:,1),T_W_Data(:,2),'LineWidth',1.5)
ylabel('$$w\;(\mu m)$$','Interpreter','latex', 'FontSize', 16)
set(gca, 'FontSize', 16);
grid on;

yyaxis right;
histogram(AEsTime,500)
ylabel('$$AEs \; Count$$', 'Interpreter', 'latex', 'FontSize', 16)
set(gca, 'FontSize', 16);
xlim([0 30000])

subplot(2,1,2)
yyaxis right;
plot(TopIndustry_data(:,1),TopIndustry_data(:,2),'LineWidth',1.5)
ylabel('$$Q_{0}\;(ml/min)$$','Interpreter','latex', 'FontSize', 16)
grid on;
ylim([0 2.5])
set(gca, 'FontSize', 16);

yyaxis left;
plot(time_smth,Downstream_P2_smth,'k-','LineWidth',1.5)
yline(8,'k--','$$\sigma_{3}\;=\;8\;MPa$$','Interpreter','latex', 'FontSize', 16,'LineWidth',1.5)
xlabel('$$time\;(s)$$','Interpreter','latex', 'FontSize', 16)
ylabel('$$Pressure\;(MPa)$$','Interpreter','latex', 'FontSize', 16)
grid on;
set(gca, 'FontSize', 16);
xlim([0 30000])
ylim([0 40])

figure
subplot(2,1,1)
plot(T_W_Data(:,1),T_W_Data(:,2),'k-','LineWidth',1.5)
ylabel('$$w\;(\mu m)$$','Interpreter','latex', 'FontSize', 16)
set(gca, 'FontSize', 16);
grid on;

subplot(2,1,2)
yyaxis right;
plot(TopIndustry_data(:,1),TopIndustry_data(:,2),'LineWidth',1.5)
ylabel('$$Q_{0}\;(ml/min)$$','Interpreter','latex', 'FontSize', 16)
grid on;
ylim([0 3])
set(gca, 'FontSize', 16);

yyaxis left;
plot(time_smth,Downstream_P2_smth,'LineWidth',1.5)
% yline(8,'k--','$$\sigma_{3}\;=\;8\;MPa$$','Interpreter','latex', 'FontSize', 16,'LineWidth',1.5)
xlabel('$$time\;(s)$$','Interpreter','latex', 'FontSize', 16)
ylabel('$$Pressure\;(MPa)$$','Interpreter','latex', 'FontSize', 16)
grid on;
set(gca, 'FontSize', 16);
xlim([0 30000])
ylim([0 40])

%% Time, Pressure, opening of each cycle's recession
% cycle 1
% (t=926) -> (t=1773)
t_rec_begin=926;
t_rec_end=1773;
Cy1_t_P_rec=[time_smth(time_smth<t_rec_end & time_smth>t_rec_begin),Downstream_P2_smth(time_smth<t_rec_end & time_smth>t_rec_begin)]; 
Cy1_t_w_rec=[T_W_Data(T_W_Data(:,1)<t_rec_end & T_W_Data(:,1)>t_rec_begin,1),T_W_Data(T_W_Data(:,1)<t_rec_end & T_W_Data(:,1)>t_rec_begin,2)];

% cycle 2
% (t=2334) -> (t=3986)
t_rec_begin=2334;
t_rec_end=3986;
Cy2_t_P_rec=[time_smth(time_smth<t_rec_end & time_smth>t_rec_begin),Downstream_P2_smth(time_smth<t_rec_end & time_smth>t_rec_begin)]; 
Cy2_t_w_rec=[T_W_Data(T_W_Data(:,1)<t_rec_end & T_W_Data(:,1)>t_rec_begin,1),T_W_Data(T_W_Data(:,1)<t_rec_end & T_W_Data(:,1)>t_rec_begin,2)];

% cycle 3
% (t=4772) -> (t=7941)
t_rec_begin=4772;
t_rec_end=7941;
Cy3_t_P_rec=[time_smth(time_smth<t_rec_end & time_smth>t_rec_begin),Downstream_P2_smth(time_smth<t_rec_end & time_smth>t_rec_begin)]; 
Cy3_t_w_rec=[T_W_Data(T_W_Data(:,1)<t_rec_end & T_W_Data(:,1)>t_rec_begin,1),T_W_Data(T_W_Data(:,1)<t_rec_end & T_W_Data(:,1)>t_rec_begin,2)];

% cycle 4
% (t=8993) -> (t=12058)
t_rec_begin=8993;
t_rec_end=12058;
Cy4_t_P_rec=[time_smth(time_smth<t_rec_end & time_smth>t_rec_begin),Downstream_P2_smth(time_smth<t_rec_end & time_smth>t_rec_begin)]; 
Cy4_t_w_rec=[T_W_Data(T_W_Data(:,1)<t_rec_end & T_W_Data(:,1)>t_rec_begin,1),T_W_Data(T_W_Data(:,1)<t_rec_end & T_W_Data(:,1)>t_rec_begin,2)];

% cycle 5
% (t=12936) -> (t=17121)
t_rec_begin=12944;
t_rec_end=16700;
Cy5_t_P_rec=[time_smth(time_smth<t_rec_end & time_smth>t_rec_begin),Downstream_P2_smth(time_smth<t_rec_end & time_smth>t_rec_begin)]; 
Cy5_t_w_rec=[T_W_Data(T_W_Data(:,1)<t_rec_end & T_W_Data(:,1)>t_rec_begin,1),T_W_Data(T_W_Data(:,1)<t_rec_end & T_W_Data(:,1)>t_rec_begin,2)];

% cycle 6
% (t=17185) -> (t=20950)
t_rec_begin=17220;
t_rec_end=20950;
Cy6_t_P_rec=[time_smth(time_smth<t_rec_end & time_smth>t_rec_begin),Downstream_P2_smth(time_smth<t_rec_end & time_smth>t_rec_begin)]; 
Cy6_t_w_rec=[T_W_Data(T_W_Data(:,1)<t_rec_end & T_W_Data(:,1)>t_rec_begin,1),T_W_Data(T_W_Data(:,1)<t_rec_end & T_W_Data(:,1)>t_rec_begin,2)];

% cycle 7
% (t=21174) -> (t=25168)
t_rec_begin=21210;
t_rec_end=25168;
Cy7_t_P_rec=[time_smth(time_smth<t_rec_end & time_smth>t_rec_begin),Downstream_P2_smth(time_smth<t_rec_end & time_smth>t_rec_begin)]; 
Cy7_t_w_rec=[T_W_Data(T_W_Data(:,1)<t_rec_end & T_W_Data(:,1)>t_rec_begin,1),T_W_Data(T_W_Data(:,1)<t_rec_end & T_W_Data(:,1)>t_rec_begin,2)];

%% Pressure Analyze & Sunset Solution
clc
close all

% 1st cycle
% t_reccession = 494;
% w_reccesion = 52.5;
% 
% Outputs1 = ClosureAnalysis1(Cy1_t_P_rec,Cy1_t_w_rec,t_reccession,w_reccesion);

% 2st cycle
% t_reccession = 517;
% w_reccesion = 49.7;
% 
% Outputs2 = ClosureAnalysis2(Cy2_t_P_rec,Cy2_t_w_rec,t_reccession,w_reccesion);

% 3st cycle
% t_reccession = 718;
% w_reccesion = 94.3;
% 
% Outputs3 = ClosureAnalysis3(Cy3_t_P_rec,Cy3_t_w_rec,t_reccession,w_reccesion);

% 4st cycle
% t_reccession = 551;
% w_reccesion = 81.9;
% 
% Outputs4 = ClosureAnalysis4(Cy4_t_P_rec,Cy4_t_w_rec,t_reccession,w_reccesion);

% 5st cycle
% t_reccession = 604;
% w_reccesion = 76.8;
% 
% Outputs5 = ClosureAnalysis5(Cy5_t_P_rec,Cy5_t_w_rec,t_reccession,w_reccesion);

% 6st cycle
% t_reccession = 37;
% w_reccesion = 71.91;
% 
% Outputs6 = ClosureAnalysis6(Cy6_t_P_rec,Cy6_t_w_rec,t_reccession,w_reccesion);

% 7st cycle
t_reccession = 102;
w_reccesion = 79.4;

Outputs7 = ClosureAnalysis7(Cy7_t_P_rec,Cy7_t_w_rec,t_reccession,w_reccesion);

%% End