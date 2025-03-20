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
LowRateData=readtable('154842-1-2.xlsx');

Time=LowRateData.Time;
Time=Time-Time(1);

Upstream_P=LowRateData.LFmeasurement3; % one of other pressure transducer 
Downstream_P1=LowRateData.LFmeasurement0; % pressure transducer after valve and out of the frame
Downstream_P2=LowRateData.LFmeasurement2; % pressure transducer close to the wellbore - inside frame
Upstream_P=Upstream_P-mean(Upstream_P(1:5000)); % to remove the initial bias
Downstream_P1=Downstream_P1-mean(Downstream_P1(1:5000)); % to remove the initial bias
Downstream_P2=Downstream_P2-mean(Downstream_P2(1:5000)); % to remove the initial bias

% pressure and volume of confinement stresses measured by GDS pump
GDS1P=LowRateData.Pump1Pressure;
GDS2P=LowRateData.Pump2Pressure;
GDS3P=LowRateData.Pump3Pressure;
GDS1V=LowRateData.Pump1Volume;
GDS2V=LowRateData.Pump2Volume;
GDS3V=LowRateData.Pump3Volume;

%% Read the data of top industry
fid1=fopen('Top_Industry_Pump10.txt');
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

fid2=fopen('Top_Industry_Pump11.txt');
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

base_TI_pump_pressure=mean(TopIndustry_matrix(1:1500,4));

% from first injection point
TopIndustry_data=[TopIndustry_matrix(1999:end,1)-TopIndustry_matrix(1999,1),TopIndustry_matrix(1999:end,2:3),...
                  (TopIndustry_matrix(1999:end,4)-base_TI_pump_pressure)/10,TopIndustry_matrix(1999:end,5)];

TopIndustry_data(TopIndustry_data(:,3)==13,:)=[];

%% sync timing
% Sync pressure transducers + GDS times with EC probe
Time=Time+859;

% Sync pressure Top Industry pump time with EC probe
TopIndustry_data=[TopIndustry_data(:,1)+1134,TopIndustry_data(:,2:end)];

%% Remove time resonance in pressure data
matrix_P=[Time,Downstream_P2,Downstream_P1,Upstream_P];

sorted_matrix_P = sortrows(matrix_P, 1);

% Remove rows where the first column value is equal to the previous one
cleaned_matrix_P = sorted_matrix_P([true; diff(sorted_matrix_P(:,1)) ~= 0], :);

%% Smoothing
time_smth=cleaned_matrix_P(1:5:end,1);
Downstream_P2_smth=smooth(time_smth,cleaned_matrix_P(1:5:end,2),0.005);
Downstream_P1_smth=smooth(time_smth,cleaned_matrix_P(1:5:end,3),0.005);
Upstream_P_smth=smooth(time_smth,cleaned_matrix_P(1:5:end,4),0.005);

%% AE's counts
close all
AEdata=readtable('catalog-AE-count-M04-V02.csv');

time_shift=1592; % 859+12*60+13

AEsTime=time_shift+AEdata.relative_time;
histogram(AEsTime,200)

%% Result plots
close all

figure
plot(Time,Upstream_P)
hold on;
plot(Time,Downstream_P1)
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

%
figure
subplot(2,1,1)
plot(T_W_Data(:,1),T_W_Data(:,2))
ylabel('\omega (\mum)', 'FontSize', 16)
set(gca, 'FontSize', 16);

xline(860,'k--','NI Rec starts');
xline(920,'k--','Top Ind. Pump Rec starts');
xline(1119,'k--','Q = 5');
xline(1295,'k--','Q = 3');
xline(1603,'k--','Shut-in');
xline(2055,'k--','Q = 3');
xline(2259,'k--','Shut-in');
xline(2840,'k--','Q = 3');
xline(2976,'k--','Shut-in');
xline(3303,'k--','Stop Passive Rec');
xline(4357,'k--','Valve opened');
xline(4563,'k--','Stop NI Rec');
xline(4743,'k--','Stop Top Ind. Pump Rec');
xline(5194,'k--','depressurized TB stress');
xline(5338,'k--','depressurized NS stress');
xline(5470,'k--','depressurized EW stress');

subplot(2,1,2)
yyaxis right;
plot(TopIndustry_data(:,1),TopIndustry_data(:,2))
xlabel('time (s)', 'FontSize', 16)
ylabel('Q_{0} (ml/min)', 'FontSize', 16)
grid on;
ylim([0 6])
set(gca, 'FontSize', 16);

yyaxis left;
plot(TopIndustry_data(:,1),TopIndustry_data(:,4),'b-')
hold on;
plot(time_smth,Upstream_P_smth,'r-')
plot(time_smth,Downstream_P1_smth,'m-')
plot(time_smth,Downstream_P2_smth,'k-')
yline(5,'k-','\sigma = 5 MPa', 'FontSize', 14)
xlabel('time (s)', 'FontSize', 16)
ylabel('pressure (MPa)', 'FontSize', 16)
grid on;
set(gca, 'FontSize', 16);
xlim([0 6000])
legend('P_{pump}','P_{upstream}','P_{downstream1}','P_{downstream2}')

figure
subplot(2,1,1)
% yyaxis left;
plot(T_W_Data(:,1),T_W_Data(:,2),'LineWidth',1.5)
ylabel('$$w\;(\mu m)$$','Interpreter','latex', 'FontSize', 16)
set(gca, 'FontSize', 16);
grid on;
ylim([0 120])

yyaxis right;
histogram(AEsTime,300)
ylabel('$$AEs \; Count$$', 'Interpreter', 'latex', 'FontSize', 16)
set(gca, 'FontSize', 16);

subplot(2,1,2)
yyaxis right;
plot(TopIndustry_data(:,1),TopIndustry_data(:,2),'LineWidth',1.5)
ylabel('$$Q_{0}\;(ml/min)$$','Interpreter','latex', 'FontSize', 16)
grid on;
ylim([0 6])
set(gca, 'FontSize', 16);

yyaxis left;
plot(time_smth,Downstream_P2_smth,'k-','LineWidth',1.5)
yline(5,'k--','$$\sigma_{3}\;=\;5\;MPa$$','Interpreter','latex', 'FontSize', 16,'LineWidth',1.5)
xlabel('$$time\;(s)$$','Interpreter','latex', 'FontSize', 16)
ylabel('$$pressure\;(MPa)$$','Interpreter','latex', 'FontSize', 16)
grid on;
set(gca, 'FontSize', 16);
xlim([0 6000])
ylim([0 50])
% legend('P_{downstream2}')

figure
subplot(2,1,1)
plot(T_W_Data(:,1)-1120,T_W_Data(:,2),'k-','LineWidth',1.5)
ylabel('$$w\;(\mu m)$$','Interpreter','latex', 'FontSize', 16)
set(gca, 'FontSize', 16);
grid on;
ylim([0 120])
xlim([0 5000])

subplot(2,1,2)
yyaxis right;
plot(TopIndustry_data(:,1)-1120,TopIndustry_data(:,2),'LineWidth',1.5)
ylabel('$$Q_{0}\;(ml/min)$$','Interpreter','latex', 'FontSize', 16)
grid on;
ylim([0 6])
set(gca, 'FontSize', 16);

yyaxis left;
plot(time_smth-1120,Downstream_P2_smth,'-','LineWidth',1.5)
% yline(5,'k--','$$\sigma_{3}\;=\;5\;MPa$$','Interpreter','latex', 'FontSize', 16,'LineWidth',1.5)
xlabel('$$time\;(s)$$','Interpreter','latex', 'FontSize', 16)
ylabel('$$pressure\;(MPa)$$','Interpreter','latex', 'FontSize', 16)
grid on;
set(gca, 'FontSize', 16);
xlim([0 5000])
ylim([0 50])
% legend('P_{downstream2}')

%% Create an Excel file of opening and pressure
xlswrite('Opening_Measurement_Output.xlsx',[T_W_Data(:,1),T_W_Data(:,2)]);

%% Main Pressure Data
time_smth=cleaned_matrix_P(1:5:end,1);
Downstream_P2_smth=smooth(time_smth,cleaned_matrix_P(1:5:end,2),0.005);

%% Time, Pressure, opening of each cycle's recession
% cycle 1
% (t=1629) -> (t=2070)
t_rec_begin=1629;
t_rec_end=2070;
Cy1_t_P_rec=[time_smth(time_smth<t_rec_end & time_smth>t_rec_begin),Downstream_P2_smth(time_smth<t_rec_end & time_smth>t_rec_begin)]; 
Cy1_t_w_rec=[T_W_Data(T_W_Data(:,1)<t_rec_end & T_W_Data(:,1)>t_rec_begin,1),T_W_Data(T_W_Data(:,1)<t_rec_end & T_W_Data(:,1)>t_rec_begin,2)];

% cycle 2
% (t=2286) -> (t=2855)
t_rec_begin=2286;
t_rec_end=2855;
Cy2_t_P_rec=[time_smth(time_smth<t_rec_end & time_smth>t_rec_begin),Downstream_P2_smth(time_smth<t_rec_end & time_smth>t_rec_begin)]; 
Cy2_t_w_rec=[T_W_Data(T_W_Data(:,1)<t_rec_end & T_W_Data(:,1)>t_rec_begin,1),T_W_Data(T_W_Data(:,1)<t_rec_end & T_W_Data(:,1)>t_rec_begin,2)];

% cycle 3
% (t=3006) -> (t=4368)
t_rec_begin=3006;
t_rec_end=4368;
Cy3_t_P_rec=[time_smth(time_smth<t_rec_end & time_smth>t_rec_begin),Downstream_P2_smth(time_smth<t_rec_end & time_smth>t_rec_begin)]; 
Cy3_t_w_rec=[T_W_Data(T_W_Data(:,1)<t_rec_end & T_W_Data(:,1)>t_rec_begin,1),T_W_Data(T_W_Data(:,1)<t_rec_end & T_W_Data(:,1)>t_rec_begin,2)];

%% Pressure Analyze & Sunset Solution
clc
close all

% 1st cycle
% t_reccession = 474.5;
% w_reccesion = 109.5;
% 
% Outputs1 = ClosureAnalysis1(Cy1_t_P_rec,Cy1_t_w_rec,t_reccession,w_reccesion);

% 2st cycle
% t_reccession = 203.2;
% w_reccesion = 63.9;
% 
% Outputs2 = ClosureAnalysis2(Cy2_t_P_rec,Cy2_t_w_rec,t_reccession,w_reccesion);

% 3st cycle
t_reccession = 138.4;
w_reccesion = 70;

Outputs3 = ClosureAnalysis3(Cy3_t_P_rec,Cy3_t_w_rec,t_reccession,w_reccesion);

%% End