classdef Car < handle
    properties
        % States of the Model
        states; % [x,y,phi,velocity]
        augmented_states;
        control_inputs; %[steering_angle, acceleration]
        
        % Geometry of the car
        track = 2057 / 100; %meter
        wheel_base = 2665 / 100; %meter
        wheel_diameter = 66.294 / 10;
        wheel_width = 25.908 / 10;
        
        % Time step for the simulation
        ts = 0.1;
        
        % Model limits
        steering_angle_limit = deg2rad(33.75);
        max_velocity = 98.3488; % m/s
        
        % PID Errors
        old_cte;
        cte_intergral;

        % Generative attack properties
        vae; % Modèle VAE pour l'attaque générative
        use_generative_attack; % Option pour activer/désactiver l'attaque
    end
    
    methods
        %% Constructeur
        function obj = Car(states, control_inputs, use_generative_attack)
            % Initialisation des états et des entrées de contrôle
            if (states(4) > obj.max_velocity)
                states(4) = obj.max_velocity;
            end
            obj.states = states;
            obj.control_inputs = control_inputs;
            obj.old_cte = 0;
            obj.cte_intergral = 0;

            % Initialiser le VAE si l'attaque est activée
            obj.use_generative_attack = use_generative_attack;
            if obj.use_generative_attack
                obj.vae = VAE();
            end
        end
        
        %% Appliquer l'attaque générative
        function obj = apply_generative_attack(obj)
            if obj.use_generative_attack
                % Préparer les entrées pour le VAE
                inputs = [obj.control_inputs, obj.states(1:2)]; % [angle, accélération, x, y]
                
                % Générer la perturbation
                perturbation = obj.vae.generate_perturbation(inputs);
                
                % Appliquer la perturbation aux entrées de contrôle
                obj.control_inputs = obj.control_inputs + perturbation;
                
                % Normaliser l'angle de braquage
                obj.control_inputs(1) = atan2(sin(obj.control_inputs(1)), cos(obj.control_inputs(1)));
                
                % Vérifier les limites de l'angle de braquage
                if (obj.control_inputs(1) > obj.steering_angle_limit)
                    obj.control_inputs(1) = obj.steering_angle_limit;
                elseif (obj.control_inputs(1) < -obj.steering_angle_limit)
                    obj.control_inputs(1) = -obj.steering_angle_limit;
                end
            end
        end
        
        %% Plot My car
        function show(obj)
            % Plot the Body of the Car
            pc1 = [-obj.wheel_base/2; obj.track/2; 1];
            pc2 = [obj.wheel_base/2; obj.track/2; 1];
            pc3 = [obj.wheel_base/2; -obj.track/2; 1];
            pc4 = [-obj.wheel_base/2; -obj.track/2; 1];
            pc = [pc1 pc2 pc3 pc4];
            
            pw1 = [-obj.wheel_diameter/2; obj.wheel_width/2; 1];
            pw2 = [obj.wheel_diameter/2; obj.wheel_width/2; 1];
            pw3 = [obj.wheel_diameter/2; -obj.wheel_width/2; 1];
            pw4 = [-obj.wheel_diameter/2; -obj.wheel_width/2; 1];
            pwheel = [pw1 pw2 pw3 pw4];
            
            [x, y, ~, ~] = state_unpack(obj);
            % Plot the center of the car
            plot(x, y, 'o', 'Markersize', 10, 'Markerface', 'b')
            hold on
            
            R_car_world = carf_to_wf(obj);
            pcw = R_car_world * pc;
            
            plot([pcw(1,1) pcw(1,2)], [pcw(2,1) pcw(2,2)], 'b', 'Linewidth', 2)
            plot([pcw(1,2) pcw(1,3)], [pcw(2,2) pcw(2,3)], 'b', 'Linewidth', 2)
            plot([pcw(1,3) pcw(1,4)], [pcw(2,3) pcw(2,4)], 'b', 'Linewidth', 2)
            plot([pcw(1,4) pcw(1,1)], [pcw(2,4) pcw(2,1)], 'b', 'Linewidth', 2)
            
            % Plot the Back wheels
            % Plot the Front wheels
            [si, ~] = control_inputs_unpack(obj);
            for i = 2:3
                R_wheel_to_car = wheel_frame_to_car(pc(:,i), si);
                pwheel = R_car_world * R_wheel_to_car * pwheel;
                plot([pwheel(1,1) pwheel(1,2)], [pwheel(2,1) pwheel(2,2)], 'Color', 'red', 'Linewidth', 2)
                plot([pwheel(1,2) pwheel(1,3)], [pwheel(2,2) pwheel(2,3)], 'Color', 'red', 'Linewidth', 2)
                plot([pwheel(1,3) pwheel(1,4)], [pwheel(2,3) pwheel(2,4)], 'Color', 'red', 'Linewidth', 2)
                plot([pwheel(1,4) pwheel(1,1)], [pwheel(2,4) pwheel(2,1)], 'Color', 'red', 'Linewidth', 2)
                pwheel = [pw1 pw2 pw3 pw4];
            end

            for i = 1:3:4
                R_wheel_to_car = wheel_frame_to_car(pc(:,i), 0);
                pwheel = R_car_world * R_wheel_to_car * pwheel;
                plot([pwheel(1,1) pwheel(1,2)], [pwheel(2,1) pwheel(2,2)], 'Color', 'red', 'Linewidth', 2)
                plot([pwheel(1,2) pwheel(1,3)], [pwheel(2,2) pwheel(2,3)], 'Color', 'red', 'Linewidth', 2)
                plot([pwheel(1,3) pwheel(1,4)], [pwheel(2,3) pwheel(2,4)], 'Color', 'red', 'Linewidth', 2)
                plot([pwheel(1,4) pwheel(1,1)], [pwheel(2,4) pwheel(2,1)], 'Color', 'red', 'Linewidth', 2)
                pwheel = [pw1 pw2 pw3 pw4];
            end
            set(gca, 'units', 'centimeters')
            hold off
        end
        
        %% Get the transformation matrix from car coordinate system to world coordinate system
        function R = carf_to_wf(obj)
            [x, y, phi, ~] = state_unpack(obj);
            R = [cos(phi) -sin(phi) x; sin(phi) cos(phi) y; 0 0 1];
        end
        
        %% Unpack the states
        function [x, y, phi, v] = state_unpack(obj)
            x = obj.states(1);
            y = obj.states(2);
            phi = obj.states(3);
            v = obj.states(4);
        end
        
        %% Unpack control_inputs
        function [si, acc] = control_inputs_unpack(obj)
            si = obj.control_inputs(1);
            acc = obj.control_inputs(2);
        end
        
        %% The dynamics of the car
        function obj = update_state(obj)
            [x, y, phi, v] = state_unpack(obj);
            [si, acc] = control_inputs_unpack(obj);
            
            x_next = x + v * cos(phi) * obj.ts;
            y_next = y + v * sin(phi) * obj.ts;
            phi_next = phi + v / (obj.wheel_base) * si * obj.ts;
            v_next = v + acc * obj.ts;
            
            % Check not to exceed the speed limit
            if (v_next > obj.max_velocity)
                v_next = obj.max_velocity;
            end
            
            obj.states = [x_next y_next phi_next v_next];
        end
        
        %% A simple setter function
        function obj = update_input(obj, control_inputs)
            % Normalize the steering angle
            control_inputs(1) = atan2(sin(control_inputs(1)), cos(control_inputs(1)));
            
            % Check that the steering angle is not exceeding the limit
            if (control_inputs(1) > obj.steering_angle_limit)
                control_inputs(1) = obj.steering_angle_limit;
            elseif (control_inputs(1) < -obj.steering_angle_limit)
                control_inputs(1) = -obj.steering_angle_limit;
            end
            
            obj.control_inputs = control_inputs;
        end
        
        %% PID Controller
        function PID_Controller(obj, cte)
            kp = 0.02;
            kd = 0.25;
            ki = 0.00005;
            
            dcte = cte - obj.old_cte;
            obj.cte_intergral = obj.cte_intergral + cte;
            obj.old_cte = cte;
            
            steering = kp * cte + kd * dcte + ki * obj.cte_intergral;
            [~, a] = obj.control_inputs_unpack;
            control_signal = [steering, a];
            
            obj.update_input(control_signal);
        end
    end
end

%% Helper Functions
function R = wheel_frame_to_car(pc, si)
    % Cette fonction calcule la matrice de transformation pour les roues
    % pc : Position de la roue dans le repère de la voiture
    % si : Angle de braquage
    R = [cos(si) -sin(si) pc(1); 
         sin(si)  cos(si) pc(2); 
         0        0       1];
end