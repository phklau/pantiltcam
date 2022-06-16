%Berechnungen der Reglerparameter anhand Methode 2 Ziegler Nichols
TYPE = 'PI'
%Prozessparameter
K = 1.89;
T = 0.8;
DT = 0.15;
%T_t = DT/2; %Mindeste Totzeit, durch diskrete Abtastung
T_t = 2*DT; %Erfahrungswert aus Sprungantwort
%Prozess
P_s = tf([K], [T 1]);

%Reglerparameter
switch TYPE
    case 'PI'
    kp = (0.9/K)*(T/T_t)
    ki = kp/(3.33*T_t)
    kd = 0
    C_s = tf([kp ki],[1 0]);
    case 'PID'
    kp = (1.2/K)*(T/T_t)
    ki = kp/(3.33*T_t)
    kd = kp*0.5*T_t
    C_s = tf([kd kp ki], [1 0]);
end
%Regler


%Übertragungsfunktion offener Regelkreis
F_0 = C_s*P_s

%Führungsübertragungsfunktion
H_s = F_0/(1+F_0)
%Polstellen der Führungsübertagungsfunktion
%s_1 = (-(1+K*kp)+sqrt((1+K*kp)^2-4*T*K*ki))/(2*T)
%s_2 = (-(1+K*kp)-sqrt((1+K*kp)^2-4*T*K*ki))/(2*T)

%Stabilitätsreserven für Robustheit gegenüber der Totzeit
step(H_s);
[Gm, Pm, ~, ~] = margin(F_0);
%bode(H_s);

%Diskretisierung des Reglers
c2d(C_s, DT, 'tustin')




