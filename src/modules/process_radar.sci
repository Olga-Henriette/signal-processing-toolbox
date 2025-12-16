// =========================================================================
// Estimation de distance
// =========================================================================
function process_radar_module()
    global app_state;
    
    disp('Debut traitement Radar...');
    
    try
        module_config = app_state.modules.radar;
        parameters = module_config.default_params;
        
        speed_of_light = 3e8;
        
        sampling_frequency = 10000;
        sampling_period = 1/sampling_frequency;
        duration_s = 0.05;
        
        time_vector = 0:sampling_period:(duration_s - sampling_period);
        
        disp('Generation signal emis (Chirp)...');
        transmitted_signal = generate_chirp(time_vector, parameters.chirp_start_freq_hz, parameters.chirp_end_freq_hz, duration_s);
        
        target_distance = parameters.target_distance_m;
        time_delay_theo = 2 * target_distance / speed_of_light;
        
        disp(sprintf('Distance cible : %.0f m. Retard theorique : %.2e s.', target_distance, time_delay_theo));
        
        disp('Simulation canal et bruit...');
        received_signal = simulate_radar_reception(transmitted_signal, sampling_frequency, time_delay_theo);
        received_signal_noisy = add_gaussian_noise(received_signal, parameters.snr_db);
        
        disp('Corrélation croisée pour estimation du retard...');
        [correlation_vector, lag_vector] = calculate_cross_correlation(transmitted_signal, received_signal_noisy, sampling_frequency);
        
        [max_corr, max_index] = find_maximum(correlation_vector);
        estimated_delay = lag_vector(max_index);
        
        estimated_distance = estimated_delay * speed_of_light / 2;
        estimation_error = abs(estimated_distance - target_distance);
        
        disp('Affichage resultats...');
        show_radar_results(time_vector, transmitted_signal, received_signal_noisy, lag_vector, correlation_vector, estimated_delay, estimated_distance);
        
        interpretation_text = sprintf('    Estimation réussie ! Distance estimée : %.1f m. Retard : %.2e s. Erreur d''estimation : %.1f m.', ...
                        estimated_distance, estimated_delay, estimation_error);
        
        update_interpretation_zone(interpretation_text);
        
        disp('Traitement Radar termine.');
        
    catch
        disp('ERREUR dans process_radar_module');
        err = lasterror();
        disp('Message : ' + err.message);
        update_interpretation_zone('    Erreur lors du traitement radar. Voir console pour détails.');
    end
endfunction

function chirp_signal = generate_chirp(time_vector, f_start, f_end, duration_s)
    bandwidth = f_end - f_start;
    slope = bandwidth / duration_s;
    phase = 2 * %pi * (f_start * time_vector + 0.5 * slope * time_vector.^2);
    chirp_signal = cos(phase);
endfunction

function received_signal = simulate_radar_reception(transmitted_signal, sampling_frequency, time_delay)
    delay_samples = round(time_delay * sampling_frequency);
    
    if delay_samples < 0 then delay_samples = 0; end
    
    N = length(transmitted_signal);
    received_signal = zeros(1, N);
    
    attenuation_factor = 0.5;
    
    if delay_samples < N then
        received_signal(delay_samples + 1:N) = attenuation_factor * transmitted_signal(1:N - delay_samples);
    end
endfunction

function noisy_signal = add_gaussian_noise(input_signal, snr_db)
    signal_power = mean(input_signal.^2);
    
    if signal_power > 1e-10 then
        noise_power = signal_power / (10^(snr_db/10));
    else
        noise_power = 0.01;
    end
    
    noise = sqrt(noise_power) * rand(1, length(input_signal), 'normal');
    noisy_signal = input_signal + noise;
endfunction

function [correlation_vector, lag_vector] = calculate_cross_correlation(signal1, signal2, sampling_frequency)
    [correlation_vector, lag_index] = xcorr(signal1, signal2);
    lag_vector = lag_index / sampling_frequency;
endfunction
