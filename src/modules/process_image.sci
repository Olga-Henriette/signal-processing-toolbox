// =========================================================================
// Amélioration d'image - ERREUR CORRIGÉE
// =========================================================================
function process_image_module()
    global app_state;
    
    disp('Debut traitement image...');
    
    try
        // Récupérer la configuration du module IMAGE
        if ~isfield(app_state, 'modules') then
            error('app_state.modules non defini');
        end
        
        if ~isfield(app_state.modules, 'image') then
            error('app_state.modules.image non defini');
        end
        
        module_config = app_state.modules.image;
        
        if ~isfield(module_config, 'default_params') then
            error('module_config.default_params non defini');
        end
        
        parameters = module_config.default_params;
        
        disp('Generation image synthetique...');
        [original_image, noisy_image] = generate_test_image(parameters);
        
        disp('Application filtre median...');
        denoised_image = apply_median_filter(noisy_image, parameters.median_filter_size);
        
        disp('Accentuation de l''image...');
        sharpened_image = apply_sharpening_filter(denoised_image);
        
        disp('Calcul metriques...');
        mse_noisy = calculate_mse(original_image, noisy_image);
        mse_treated = calculate_mse(original_image, sharpened_image);
        
        if mse_noisy > 0 then
            improvement_percent = ((mse_noisy - mse_treated) / mse_noisy) * 100;
        else
            improvement_percent = 0;
        end
        
        disp('Affichage resultats...');
        show_image_results(original_image, noisy_image, denoised_image, sharpened_image);
        
        interpretation_text = sprintf('    Traitement réussi ! Amélioration de %.1f%% (MSE : %.1f -> %.1f). Le filtre médian a éliminé le bruit et l''accentuation a restauré les détails.', ...
                        improvement_percent, mse_noisy, mse_treated);
        update_interpretation_zone(interpretation_text);
        
        disp('Traitement image termine.');
        
    catch
        disp('ERREUR dans process_image_module');
        err = lasterror();
        disp('Message : ' + err.message);
        disp('Details de l''erreur :');
        for i = 1:size(err.stack, 1)
            disp('  Ligne ' + string(err.stack(i).line) + ' dans ' + err.stack(i).name);
        end
        update_interpretation_zone('    Erreur lors du traitement image. Voir console pour détails.');
    end
endfunction

function [original_image, noisy_image] = generate_test_image(parameters)
    rows = 200;
    cols = 200;
    original_image = zeros(rows, cols);
    
    // Rectangle
    original_image(50:150, 80:120) = 1;
    
    // Cercle
    [xx, yy] = ndgrid(1:rows, 1:cols);
    center = [100, 100];
    radius = 30;
    mask = ((xx - center(1)).^2 + (yy - center(2)).^2) <= radius^2;
    original_image(mask) = 1;
    original_image = uint8(original_image * 255);
    
    // Flou gaussien
    blur_sigma = parameters.blur_sigma;
    kernel_size = 2 * ceil(3 * blur_sigma) + 1;
    x_lin = linspace(-(kernel_size-1)/2, (kernel_size-1)/2, kernel_size);
    gaussian_kernel = exp(-(x_lin.^2) / (2 * blur_sigma^2));
    gaussian_kernel = gaussian_kernel' * gaussian_kernel;
    gaussian_kernel = gaussian_kernel / sum(gaussian_kernel);
    
    blurred_image = conv2(double(original_image), gaussian_kernel, 'same');
    blurred_image = uint8(blurred_image);
    
    // Bruit poivre et sel
    noisy_image = double(blurred_image);
    noise_prob = parameters.noise_level_factor;
    
    // Générer masque de bruit
    noise_mask = rand(rows, cols) < noise_prob;
    salt_mask = rand(rows, cols) > 0.5;
    
    // Appliquer bruit
    for i = 1:rows
        for j = 1:cols
            if noise_mask(i, j) then
                if salt_mask(i, j) then
                    noisy_image(i, j) = 255;
                else
                    noisy_image(i, j) = 0;
                end
            end
        end
    end
    
    noisy_image = uint8(noisy_image);
endfunction

function output_image = apply_median_filter(input_image, filter_size)
    [rows, cols] = size(input_image);
    output_image = input_image;
    half_size = floor(filter_size/2);
    
    double_input = double(input_image);
    
    for i = (1+half_size):(rows-half_size)
        for j = (1+half_size):(cols-half_size)
            neighborhood = double_input(i-half_size:i+half_size, j-half_size:j+half_size);
            output_image(i, j) = median(neighborhood(:));
        end
    end
    
    output_image = uint8(output_image);
endfunction

function output_image = apply_sharpening_filter(input_image)
    sharpen_mask = [0, -1, 0; -1, 5, -1; 0, -1, 0];
    
    output_image = conv2(double(input_image), sharpen_mask, 'same');
    
    // Clip et conversion
    output_image = max(0, min(255, output_image));
    output_image = uint8(output_image);
endfunction

function mse_value = calculate_mse(image1, image2)
    diff = double(image1) - double(image2);
    mse_value = mean(diff(:).^2);
endfunction
