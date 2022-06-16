function [ki, kp] = getControllerParams(axis, TD)
    switch axis
        case 'pan'
            K = 1.89;
            T = 0.091;
        case 'tilt'
            K = 2.4;
            T = 0.07;
    end
    kp = (0.9/K)*(T/TD);
    ki = kp/(3.33*TD);
end