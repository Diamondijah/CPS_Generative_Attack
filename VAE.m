classdef VAE < handle
    properties
        latent_dim = 2; % Dimension de l'espace latent
        encoder_weights;
        decoder_weights;
    end
    
    methods
        %% Constructeur
        function obj = VAE()
            % Initialiser les poids du VAE (simplifié pour l'exemple)
            obj.encoder_weights = randn(4, obj.latent_dim); % 4 entrées : [angle, accélération, x, y]
            obj.decoder_weights = randn(obj.latent_dim, 2); % 2 sorties : [perturbation_angle, perturbation_accélération]
        end
        
        %% Encoder
        function z = encode(obj, inputs)
            % Encoder les entrées dans l'espace latent
            z = inputs * obj.encoder_weights;
        end
        
        %% Decoder
        function outputs = decode(obj, z)
            % Decoder l'espace latent en perturbations
            outputs = z * obj.decoder_weights;
        end
        
        %% Générer une perturbation
        function perturbation = generate_perturbation(obj, inputs)
            % Encoder les entrées
            z = obj.encode(inputs);
            
            % Ajouter un bruit dans l'espace latent
            z_noisy = z + 0.1 * randn(size(z)); % Bruit Gaussien
            
            % Decoder pour obtenir la perturbation
            perturbation = obj.decode(z_noisy);
        end
    end
end