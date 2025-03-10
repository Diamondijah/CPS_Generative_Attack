function way_points = generate_trajectory(step)
    theta = 0:step:2*pi;
    x = 200 * cos(theta'); % Colonne des x
    y = 200 * sin(theta'); % Colonne des y
    way_points = [x, y]; % Tableau à deux colonnes [x, y]
end