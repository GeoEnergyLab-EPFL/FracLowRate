function  t_tsqrt_G_P_w = ClosureAnalysis6(t_P_org,t_w_org,t_reccession,w_reccesion)

%% filtering the curve
    % Assuming t_P_org and t_w_org are [time, value] matrices
    time_P = t_P_org(:, 1); % Extract time column for pressure
    pressure = t_P_org(:, 2); % Extract pressure column
    
    time_w = t_w_org(:, 1); % Extract time column for opening
    opening = t_w_org(:, 2); % Extract opening column
    
    % Define a common time vector with 1000 uniform time steps
    common_time = (linspace(max([min(time_P),min(time_w)]), min([max(time_P),max(time_w)]), 2000))';
    
    % Interpolate pressure and opening data to the common time vector
    t_P_corr = [common_time, interp1(time_P, pressure, common_time, 'linear')]; % Pressure time series
    t_w_corr = [common_time, interp1(time_w, opening, common_time, 'linear')]; % Opening time series

    % Assuming t_P_corr and t_w_corr are your input matrices
    Pressure = t_P_corr(:, 2);
    opening = t_w_corr(:, 2);

    % Low-pass filter the opening data
    cutoff_freq = 50; % Adjust cutoff frequency as needed
    fs = 1500; % Sampling frequency (assumed, adjust as appropriate)
    [b, a] = butter(4, cutoff_freq / (fs / 2), 'low'); % 4th-order Butterworth low-pass filter
    filtered_opening = filtfilt(b, a, opening); % Apply filter with zero phase distortion
    
    % Plot opening vs pressure
    figure;
    plot(Pressure,opening, 'b-', 'DisplayName', 'Original Data'); % Original data in blue
    hold on;   
    % Plot the filtered opening vs pressure
    plot(Pressure,filtered_opening, 'r--', 'DisplayName', 'Lowpass Filtered');
    xlabel('Pressure');
    ylabel('Opening');
    legend('show','Location','northwest');
    grid on;
    title('Opening vs Pressure with Lowpass Filter');
    hold off;

%% Stiffness curve
    t_w = [common_time, filtered_opening];
    t_P = [common_time, Pressure];

    figure;
    yyaxis right;
    plot(t_P(:,2), t_w(:,2),'LineWidth',1, 'DisplayName', 'Original Data');
    ylabel('$$w\;(\mu m)$$', 'Interpreter', 'latex', 'FontSize', 16)
    set(gca, 'FontSize', 16);

    yyaxis left;
    plot(t_P(1:end-1,2),diff(t_P(:,2))./diff(t_w(:,2)))
    xlabel('$$p\;(MPa)$$', 'Interpreter', 'latex', 'FontSize', 16)
    ylabel('$$dp/dw\;(MPa/\mu m)$$', 'Interpreter', 'latex', 'FontSize', 16)
    set(gca, 'FontSize', 16);
    ylim([0 3])

%% p - sqrt{delta t} & Compliance and Tangent method
 
    % G function
    deltatD = (common_time-common_time(1))/(t_reccession);
    gdeltatD = 4/3*((1+deltatD).^1.5-(deltatD).^1.5);
    GdtD = 4/pi*(gdeltatD-4/3);

    % dp/dG - G
    figure
    yyaxis left;
    plot(GdtD, Pressure)
    ylabel('$$p\;(MPa)$$', 'Interpreter', 'latex', 'FontSize', 16)

    yyaxis right;
    plot(GdtD(1:end-1),abs(diff(Pressure)./diff(GdtD)))
    hold on
    plot(GdtD(1:end-1),smooth(abs(diff(Pressure)./diff(GdtD)),0.01),'k--')
    xlabel('$$G$$', 'Interpreter', 'latex', 'FontSize', 16)
    ylabel('$$|dp/dG|$$', 'Interpreter', 'latex', 'FontSize', 16)
    set(gca, 'FontSize', 16);

    x = GdtD;
    [x_click, ~] = ginput(1);
    [~, index] = min(abs(x - x_click)); 
    format shortG
    disp([GdtD(index);common_time(index);Pressure(index);filtered_opening(index)]);
    xline(x(index), 'k--', 'LineWidth', 1.5);

    % G.dp/dG - G
    figure
    yyaxis left;
    plot(GdtD, Pressure)
    ylabel('$$p\;(MPa)$$', 'Interpreter', 'latex', 'FontSize', 16)

    yyaxis right;
    plot(GdtD(1:end-1),smooth(abs(GdtD(1:end-1).*diff(Pressure)./diff(GdtD))))
    hold on;
    plot(GdtD(1:end-1),smooth(abs(GdtD(1:end-1).*diff(Pressure)./diff(GdtD)),0.1),'k--')
    xlabel('$$G$$', 'Interpreter', 'latex', 'FontSize', 16)
    ylabel('$$|Gdp/dG|$$', 'Interpreter', 'latex', 'FontSize', 16)
    set(gca, 'FontSize', 16);

    x = GdtD;
    [x_click, ~] = ginput(1);
    [~, index] = min(abs(x - x_click)); 
    format shortG
    disp([GdtD(index);common_time(index);Pressure(index);filtered_opening(index)]);
    xline(x(index), 'k--', 'LineWidth', 1.5);


    % p - sqrt{delta t}
    figure
    yyaxis left;
    plot(sqrt(common_time-common_time(1)), Pressure)
    ylabel('$$p\;(MPa)$$', 'Interpreter', 'latex', 'FontSize', 16)

    yyaxis right;
    plot(sqrt(common_time(2:end)-common_time(1)), diff(Pressure)./diff(sqrt(common_time)))
    xlabel('$$\sqrt{t\;-\;t_{s}}\;(\sqrt{s})$$', 'Interpreter', 'latex', 'FontSize', 16)
    ylabel('$$\frac{\partial p}{\partial \sqrt{\Delta t}}\;(MPa/\sqrt{s})$$', 'Interpreter', 'latex', 'FontSize', 16)
    set(gca, 'FontSize', 16);
    
    x = sqrt(common_time(2:end)-common_time(1));
    [x_click, ~] = ginput(1);
    [~, index] = min(abs(x - x_click)); 
    format shortG
    disp([common_time(index);Pressure(index);filtered_opening(index)]);
    xline(x(index), 'k--', 'LineWidth', 1.5);

%% sunset solution at selected point
    t_selected = common_time(74);

    % w-t'
    t_w_under_tc = [common_time(common_time<t_selected),filtered_opening(common_time<t_selected)];
    t_p_under_tc = [common_time(common_time<t_selected),Pressure(common_time<t_selected)];
    
    w_r = t_w_under_tc(:,2)/t_w_under_tc(1,2);
    t_r = (t_w_under_tc(end,1)-t_w_under_tc(:,1));
    
    p1 = polyfit(t_r(end-8:end),w_r(end-8:end),1);
    xx=min(t_r):0.001:max(t_r);
    yy=polyval(p1,xx);

    figure
    plot(t_r,w_r,'LineWidth',1.5)
    hold on
    plot(xx,yy,'r--','LineWidth',1.5)
    xlabel('$$t^{\prime}=t_{c}-t$$', 'Interpreter', 'latex', 'FontSize', 16)
    ylabel('$$w(0,t)/w(0,t_{r})$$',  'Interpreter', 'latex', 'FontSize',16)
    set(gca, 'FontSize', 16);
    gtext([sprintf('%.1e', p1(1)) '$$\; t^{\prime} + \;$$' num2str(round(p1(2),3))], 'Interpreter', 'latex', 'FontSize',16)

    Leakoff_sunset = p1(1)*sqrt((t_selected-common_time(1))+t_reccession)*w_reccesion*10^(-6)

    % p-t'
    p_r = t_p_under_tc(:,2)/t_p_under_tc(1,2);
    t_r = (t_p_under_tc(end,1)-t_p_under_tc(:,1));

    p2=polyfit(sqrt(t_r(end-2:end)),p_r(end-2:end),1);
    xx=min(t_r):0.0001:max(t_r);
    yy=polyval(p2,sqrt(xx));

    figure
    plot(sqrt(t_r),p_r,'LineWidth',1.5)
    hold on
    plot(sqrt(xx),yy,'r--','LineWidth',1.5)
    xlabel('$$t^{\prime 1/2}=\left(t_{c}-t\right)^{1/2}$$', 'Interpreter', 'latex', 'FontSize', 16)
    ylabel('$$p(0,t)/p(0,t_{r})$$',  'Interpreter', 'latex', 'FontSize',16)
    % grid on;
    set(gca, 'FontSize', 16);
    gtext([sprintf('%.1e', p2(1)) '$$\; t^{\prime 1/2} + $$' num2str(round(p2(2),3))], 'Interpreter', 'latex', 'FontSize',16)

%% Late time - sunset solution shape
    % w - t'
    w_r = filtered_opening/filtered_opening(1);
    t_r = common_time(end)-common_time;
    
    p1=polyfit(t_r(end-100:end),w_r(end-100:end),1);
    xx=min(t_r):0.001:max(t_r);
    yy=polyval(p1,xx);

    figure
    plot(t_r,w_r,'LineWidth',1.5)
    hold on
    plot(xx,yy,'r--','LineWidth',1.5)
    xlabel('$$t^{\prime}=t_{c}-t$$', 'Interpreter', 'latex', 'FontSize', 16)
    ylabel('$$w(0,t)/w(0,t_{r})$$',  'Interpreter', 'latex', 'FontSize',16)
    set(gca, 'FontSize', 16);
    gtext([sprintf('%.1e', p1(1)) '$$\; t^{\prime} + \;$$' num2str(round(p1(2),3))], 'Interpreter', 'latex', 'FontSize',16)

    % p-t'
    p_r = Pressure/Pressure(1);
    t_r = common_time(end)-common_time;

    p2=polyfit(sqrt(t_r(end-100:end)),p_r(end-100:end),1);
    xx=min(t_r):0.0001:max(t_r);
    yy=polyval(p2,sqrt(xx));

    figure
    plot(sqrt(t_r),p_r,'LineWidth',1.5)
    hold on
    plot(sqrt(xx),yy,'r--','LineWidth',1.5)
    xlabel('$$t^{\prime 1/2}=\left(t_{c}-t\right)^{1/2}$$', 'Interpreter', 'latex', 'FontSize', 16)
    ylabel('$$p(0,t)/p(0,t_{r})$$',  'Interpreter', 'latex', 'FontSize',16)
    % grid on;
    set(gca, 'FontSize', 16);
    gtext([sprintf('%.1e', p2(1)) '$$\; t^{\prime 1/2} + $$' num2str(round(p2(2),3))], 'Interpreter', 'latex', 'FontSize',16)

%% Leakoff asymptote calculation at late time
    CCCC=[];
    aaa=1;

    for i22=102:1:numel(common_time)-50
    
        delta_T = common_time(i22)-common_time(1);
        
        % w-t'
        t_w_under_tc = [common_time(common_time<common_time(1)+delta_T,:),filtered_opening(common_time<common_time(1)+delta_T,:)];
        
        w_r = t_w_under_tc(:,2)/t_w_under_tc(1,2);
        t_r = (t_w_under_tc(end,1)-t_w_under_tc(:,1));
        
        p1 = polyfit(t_r(end-100:end),w_r(end-100:end),1);

        zz = p1(1)*sqrt(delta_T+t_reccession)*w_reccesion*10^(-6);

        CCCC(aaa,:) = [common_time(i22),zz];
        aaa=aaa+1;
    end
    
    xCp = CCCC(:,1)/common_time(1);
    yCp = CCCC(:,2);
    save M03-C1_Cp_x_y.mat xCp yCp

    figure;
    plot(CCCC(:,1)-common_time(1),CCCC(:,2))
    ylabel('$$C^{\prime} \;(m/\sqrt{t})$$', 'Interpreter', 'latex', 'FontSize', 16)
    xlabel('$$t_{c}-t_{s}\;(s)$$', 'Interpreter', 'latex', 'FontSize', 16)
    yline(mean(CCCC(end-10:end,2)),'k--',['$$C^{\prime} = ' num2str(mean(CCCC(end-10:end,2))) '$$'],'LabelHorizontalAlignment','left','Interpreter','latex')
    set(gca, 'FontSize', 16);

    figure;
    plot(CCCC(:,1),CCCC(:,2))
    ylabel('$$C^{\prime} \;(m/\sqrt{t})$$', 'Interpreter', 'latex', 'FontSize', 16)
    xlabel('$$t\;(s)$$', 'Interpreter', 'latex', 'FontSize', 16)
    yline(mean(CCCC(end-100:end,2)),'k--',['$$C^{\prime} = ' num2str(mean(CCCC(end-100:end,2))) '$$'],'LabelHorizontalAlignment','left','Interpreter','latex')
    set(gca, 'FontSize', 16);

%% Data creation
    t_tsqrt_G_P_w = [common_time, sqrt(common_time-common_time(1)), GdtD, Pressure, filtered_opening];


end


