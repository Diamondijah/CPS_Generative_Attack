% Charger les données sans attaque
load('trajectoires_no_attack.mat'); % Charge positions et way_points

% Renommer les variables pour la clarté
positions_no_attack = positions;
way_points_no_attack = way_points;

% Charger les données avec attaque
load('trajectoires_with_attack.mat'); % Charge positions et way_points

% Renommer les variables pour la clarté
positions_with_attack = positions;
way_points_with_attack = way_points;

% Vérifier que les variables sont bien chargées
disp('Variables chargées :');
disp('positions_no_attack :'); disp(size(positions_no_attack));
disp('positions_with_attack :'); disp(size(positions_with_attack));
disp('way_points_no_attack :'); disp(size(way_points_no_attack));
disp('way_points_with_attack :'); disp(size(way_points_with_attack));

% Tracer les deux trajectoires
figure;
plot(positions_no_attack(:, 1), positions_no_attack(:, 2), 'b', 'LineWidth', 2);
hold on;
plot(positions_with_attack(:, 1), positions_with_attack(:, 2), 'r', 'LineWidth', 2);
plot(way_points_no_attack(:, 1), way_points_no_attack(:, 2), 'k--', 'LineWidth', 1.5);
xlabel('x (m)');
ylabel('y (m)');
title('Comparaison des trajectoires');
legend('Sans attaque', 'Avec attaque', 'Trajectoire de référence');
grid on;

% Enregistrer la figure
saveas(gcf, 'comparaison_trajectoires.png');