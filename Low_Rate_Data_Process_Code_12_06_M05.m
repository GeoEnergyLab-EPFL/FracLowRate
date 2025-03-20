%% This code is used to process the Low Rate Data
% GEL - EPFL - 2024
% Developed by Mohsen Talebkeikhah

%% cleanup first, set global parameters, and input initial values
clc
clear
close all

%% loading the low rate data (EC Probe + Pressure transducers + GDS pump + ISCO Pump)
% time in second, pressure in MPa, and opening in micrometer
% opening measurement system
T_W_Data = xlsread('Opening_Measurement_Output.xlsx');

% pressure of ISCO pump and pressure transducers in the injection line
LowRateData = readtable('183454.csv');

Time=LowRateData.Time;
Time=Time-Time(1);

Upstream_P=LowRateData.LFmeasurement3; % pump pressure
Downstream_P1=LowRateData.LFmeasurement2; % pressure transducer after valve and out of the frame
Downstream_P2=LowRateData.LFmeasurement1; % pressure transducer close to the wellbore - inside frame
Downstream_P1=Downstream_P1-mean(Downstream_P1(1:5000)); % to remove the initial bias
Downstream_P2=Downstream_P2-mean(Downstream_P2(1:5000)); % to remove the initial bias

% pressure and volume of confinement stresses measured by GDS pump
GDS1P=LowRateData.Pump1Pressure;
GDS2P=LowRateData.Pump2Pressure;
GDS3P=LowRateData.Pump3Pressure;
GDS1V=LowRateData.Pump1Volume;
GDS2V=LowRateData.Pump2Volume;
GDS3V=LowRateData.Pump3Volume;

%% Remove time resonance in pressure data
matrix_P=[Time,Downstream_P2,Downstream_P1,Upstream_P];

sorted_matrix_P = sortrows(matrix_P, 1);

% Remove rows where the first column value is equal to the previous one
cleaned_matrix_P = sorted_matrix_P([true; diff(sorted_matrix_P(:,1)) ~= 0], :);

%% Smoothing
time_smth=cleaned_matrix_P(1:5:end,1);
Downstream_P2_smth=smooth(time_smth,cleaned_matrix_P(1:5:end,2),0.0005);
Downstream_P1_smth=smooth(time_smth,cleaned_matrix_P(1:5:end,3),0.0005);
Upstream_P_smth=smooth(time_smth,cleaned_matrix_P(1:5:end,4),0.0005);

%% AE's counts
% close all
AEdata=readtable('catalog-AE-count-M05.csv');

AEsTime=3300+AEdata.relative_time;

figure
histogram(AEsTime,500)

%% Result plots
close all

figure
plot(Time,Upstream_P)
hold on;
plot(Time,Downstream_P1)
plot(Time,Downstream_P2)
yline(7,'k--','\sigma = 7 MPa')
xlabel('time (s)')
ylabel('Pressure (MPa)')
grid on;
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

t0=0:0.5:436;
q0=0*ones(1,numel(t0));

t1=436:0.5:982;
q1=3*ones(1,numel(t1));

t2=982:0.5:3395;
q2=0*ones(1,numel(t2));

t3=3395:0.5:3664;
q3=3*ones(1,numel(t3));

t4=3664:0.5:6748;
q4=0*ones(1,numel(t4));

t5=6748:0.5:7257;
q5=3*ones(1,numel(t5));

t6=7257:0.5:10000;
q6=0*ones(1,numel(t6));

T_Q=[[t0' q0'];[t1' q1'];[t2' q2'];[t3' q3'];[t4' q4'];[t5' q5'];[t6' q6']];

figure
subplot(2,1,1)
plot(T_W_Data(:,1),T_W_Data(:,2))
ylabel('w (\mum)', 'FontSize', 16)
xlim([0 12500])
set(gca, 'FontSize', 16);
grid on;

subplot(2,1,2)
yyaxis right;
xlabel('time (s)', 'FontSize', 16)
ylabel('Q_{0} (ml/min)', 'FontSize', 16)
grid on;
ylim([0 4])
set(gca, 'FontSize', 16);

yyaxis left;
plot(time_smth,Downstream_P2_smth,'k-')
yline(7,'k-','\sigma = 7 MPa', 'FontSize', 14)
xlabel('time (s)', 'FontSize', 16)
ylabel('Pressure (MPa)', 'FontSize', 16)
grid on;
set(gca, 'FontSize', 16);
xlim([0 12500])
% ylim([0 25])
% legend('P_{downstream2}')
xline(436,'k--','Q = 3 ml/min')
xline(982,'k--','1st shut-in')
xline(1920,'k--','save w data 2 time')
xline(2533,'k--','open valve')
xline(3395,'k--','Q = 3 ml/min')
xline(3664,'k--','2nd shut-in')
xline(5700,'k--','open valve')
xline(6420,'k--','Save w data - start from previous w')
xline(6540,'k--','set w')
xline(6600,'k--','save w')
xline(6748,'k--','Q = 3 ml/min')
xline(7257,'k--','3rd shut-in')
xline(7380,'k--','turn off pump')
xline(7560,'k--','open 2nd valve')
xline(10456,'k--','open 2nd valev')
xline(10500,'k--','open 1st valve')
xline(10680,'k--','save w data')
xline(11700,'k--','set w and save w data')

figure
subplot(2,1,1)
yyaxis left;
plot(T_W_Data(:,1),T_W_Data(:,2),'LineWidth',1.5)
ylabel('$$w\;(\mu m)$$','Interpreter','latex', 'FontSize', 16)
set(gca, 'FontSize', 16);
xlim([0 12500])
ylim([-50 400]);

yyaxis right;
histogram(AEsTime,500)
ylabel('$$AEs \; Count$$', 'Interpreter', 'latex', 'FontSize', 16)
set(gca, 'FontSize', 16);

subplot(2,1,2)
yyaxis right;
plot(T_Q(:,1),T_Q(:,2),'LineWidth',1.5)
ylabel('$$Q\;(ml/min)$$','Interpreter','latex', 'FontSize', 16)
% grid on;
ylim([0 4])
set(gca, 'FontSize', 16);

yyaxis left;
plot(time_smth,Downstream_P1_smth,'k-','LineWidth',1.5)
yline(7,'k--','$$\sigma\;=\;7\;MPa$$','Interpreter','latex', 'FontSize', 16,'LineWidth',1.5)
xlabel('$$time\;(s)$$','Interpreter','latex', 'FontSize', 16)
ylabel('$$Pressure\;(MPa)$$','Interpreter','latex', 'FontSize', 16)
%grid on;
set(gca, 'FontSize', 16);
xlim([0 12500])

figure
subplot(2,1,1)
plot(T_W_Data(:,1),T_W_Data(:,2),'k-','LineWidth',1.5)
ylabel('$$w\;(\mu m)$$','Interpreter','latex', 'FontSize', 16)
set(gca, 'FontSize', 16);
xlim([0 12500])
ylim([-50 400]);

subplot(2,1,2)
yyaxis right;
plot(T_Q(:,1),T_Q(:,2),'LineWidth',1.5)
ylabel('$$Q\;(ml/min)$$','Interpreter','latex', 'FontSize', 16)
% grid on;
ylim([0 4])
set(gca, 'FontSize', 16);

yyaxis left;
plot(time_smth,Downstream_P1_smth,'LineWidth',1.5)
% yline(7,'k--','$$\sigma\;=\;7\;MPa$$','Interpreter','latex', 'FontSize', 16,'LineWidth',1.5)
xlabel('$$time\;(s)$$','Interpreter','latex', 'FontSize', 16)
ylabel('$$Pressure\;(MPa)$$','Interpreter','latex', 'FontSize', 16)
%grid on;
set(gca, 'FontSize', 16);
xlim([0 12500])

%% AEs, Time, Pressure, opening of each cycle's recession
% cycle 1
% (t=1020) -> (t=2550)
t_rec_begin=1022.5;
t_rec_end=2550;
Cy1_t_P_rec=[time_smth(time_smth<t_rec_end & time_smth>t_rec_begin),Downstream_P2_smth(time_smth<t_rec_end & time_smth>t_rec_begin)]; 
Cy1_t_w_rec=[T_W_Data(T_W_Data(:,1)<t_rec_end & T_W_Data(:,1)>t_rec_begin,1),T_W_Data(T_W_Data(:,1)<t_rec_end & T_W_Data(:,1)>t_rec_begin,2)];

% cycle 2
% (t=3721) -> (t=5366)
t_rec_begin=3721;
t_rec_end=5366;
Cy2_t_P_rec=[time_smth(time_smth<t_rec_end & time_smth>t_rec_begin),Downstream_P2_smth(time_smth<t_rec_end & time_smth>t_rec_begin)]; 
Cy2_t_w_rec=[T_W_Data(T_W_Data(:,1)<t_rec_end & T_W_Data(:,1)>t_rec_begin,1),T_W_Data(T_W_Data(:,1)<t_rec_end & T_W_Data(:,1)>t_rec_begin,2)];

% cycle 3
% (t=7310) -> (t=10447)
t_rec_begin=7310;
t_rec_end=10447;
Cy3_t_P_rec=[time_smth(time_smth<t_rec_end & time_smth>t_rec_begin),Downstream_P2_smth(time_smth<t_rec_end & time_smth>t_rec_begin)]; 
Cy3_t_w_rec=[T_W_Data(T_W_Data(:,1)<t_rec_end & T_W_Data(:,1)>t_rec_begin,1),T_W_Data(T_W_Data(:,1)<t_rec_end & T_W_Data(:,1)>t_rec_begin,2)];

%% Pressure Analyze & Sunset Solution
clc
close all

% 1st cycle
% t_reccession = 482;
% w_reccesion = 161.5;
% 
% Outputs1 = ClosureAnalysis1(Cy1_t_P_rec,Cy1_t_w_rec,t_reccession,w_reccesion);

% 2st cycle
% t_reccession = 283;
% w_reccesion = 223;
% 
% Outputs2 = ClosureAnalysis2(Cy2_t_P_rec,Cy2_t_w_rec,t_reccession,w_reccesion);

% 3st cycle
t_reccession = 509;
w_reccesion = 345;

Outputs3 = ClosureAnalysis3(Cy3_t_P_rec,Cy3_t_w_rec,t_reccession,w_reccesion);

%% End
