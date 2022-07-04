%Berechnungen der Reglerparameter anhand Methode 2 Ziegler Nichols
TYPE = 'PI'
%Prozessparameter
%Pan Theoretisch
%K = 1.895;
%Tilt Theoretisch
K = 2.5714
%K = 2.57;
T = 0.15;
DT = 0.15;
s = tf('s');
%T_t = DT/2; %Mindeste Totzeit, durch diskrete Abtastung
T_t = 0.4; %Erfahrungswert aus Sprungantwort
%Prozess ohne Totzeit
P_s = tf([K], [T 1]);
%Prozess mit Totzeit
P_st = K/(T*s+1) * exp(-20*s);

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
F_0t = C_s*P_st;

%Führungsübertragungsfunktion
H_s = F_0/(1+F_0)
H_st = F_0t/(1+F_0t)
H_2dof = (K*ki)/(T*s*s + K*kp*s + (K*ki+1))
%Polstellen der Führungsübertagungsfunktion
%s_1 = (-(1+K*kp)+sqrt((1+K*kp)^2-4*T*K*ki))/(2*T)
%s_2 = (-(1+K*kp)-sqrt((1+K*kp)^2-4*T*K*ki))/(2*T)

%Stabilitätsreserven für Robustheit gegenüber der Totzeit
step(H_s);
[Gm,Pm,Wcg,Wcp] = margin(F_0t)
%bode(F_0);

%Diskretisierung des Reglers
c2d(C_s, DT, 'tustin')




