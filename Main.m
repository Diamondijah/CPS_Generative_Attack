close all
clc

%% Options
use_generative_attack = false; % Activer ou désactiver l'attaque générative

%% Initialisation
initial_states = [0 -225 0 0];
initial_inputs = [0 12];

Lambo = Car(initial_states, initial_inputs, use_generative_attack);

N = 200; % Nombre d'itérations
win = 120;
way_points = generate_trajectory(0.05); % Générer la trajectoire

myTrajectory = Trajectory(way_points);

delay_time = 0;
filename = 'Zoomed.gif';

% Tableau pour enregistrer les positions
positions = zeros(N, 2); % [x, y]

%% Boucle de simulation
for i = 1:N
    h = figure(1);
    
    % Appliquer l'attaque générative si activée
    Lambo.apply_generative_attack();
    
    % Enregistrer la position actuelle
    [x, y, ~, ~] = Lambo.state_unpack;
    positions(i, :) = [x, y];
    
    % Continuer avec le reste de la simulation
    myTrajectory.nearest_points(Lambo);
    myTrajectory.poly_fit(Lambo);
    myTrajectory.compute_error;
    myTrajectory.show(Lambo);
    myTrajectory.cte;
    
    Lambo.show;
    Lambo.PID_Controller(myTrajectory.cte);
    Lambo.control_inputs(1);
    
    xlim([x - win x + win]);
    ylim([y - win y + win]);
    
    Lambo.update_state;
    grid on;
    
    %% Enregistrer le GIF
    frame = getframe(h);
    img = frame2im(frame);
    [AA, map] = rgb2ind(img, 256);
    if i == 1
        imwrite(AA, map, filename, 'gif', 'LoopCount', Inf, 'DelayTime', delay_time);
    else
        imwrite(AA, map, filename, 'gif', 'WriteMode', 'append', 'DelayTime', delay_time);
    end
end

%% Tracer la trajectoire
figure;
plot(positions(:, 1), positions(:, 2), 'b', 'LineWidth', 2);
hold on;
plot(way_points(:, 1), way_points(:, 2), 'r--', 'LineWidth', 1.5);
xlabel('x (m)');
ylabel('y (m)');
title('Trajectoire de la voiture');
legend('Trajectoire réelle', 'Trajectoire de référence');
grid on;

% Enregistrer la figure
saveas(gcf, 'trajectoire_finale.png');

% Enregistrer les positions dans un fichier .mat
% save('trajectoires_with_attack.mat', 'positions', 'way_points');
save('trajectoires_no_attack', 'positions', 'way_points');