// =========================================================================
// Detection de R-peaks
// =========================================================================
function process_ecg_module() 
    global app_state;
    
    disp('Debut traitement ECG...');
    
    try
        module_config = app_state.modules.ecg;
        parameters = module_config.default_params;
        
        sampling_frequency = 1000;
        sampling_period = 1/sampling_frequency;
        
        time_vector = 0:sampling_period:(parameters.duration_s - sampling_period);
        N = length(time_vector);
        
        disp('Generation ECG...');
        clean_ecg = generate_ecg_signal(time_vector, N, parameters.heart_rate_bpm);
        noisy_ecg = add_noise_to_ecg(clean_ecg, time_vector, N, parameters.noise_level_factor);
        
        disp('Filtrage ECG...');
        filtered_ecg = filter_ecg_signal_fft(noisy_ecg, sampling_frequency);
        
        disp('Detection R-peaks...');
        peak_positions = detect_r_peaks(filtered_ecg, sampling_frequency, parameters.detection_threshold);
        peak_times = peak_positions / sampling_frequency;
        
        disp('Calcul frequence cardiaque...');
        mean_heart_rate = calculate_mean_hr(peak_times);
        
        disp('Affichage resultats...');
        show_ecg_results(time_vector, noisy_ecg, filtered_ecg, peak_times, peak_positions, mean_heart_rate);
        
        disp('Calcul interpretation...');
        if length(peak_times) >= 2 then
            intervals_rr = diff(peak_times);
            mean_rr_interval_ms = mean(intervals_rr) * 1000;
            
            interpretation_text = sprintf('    Détection réussie ! %d battements détectés sur %.1f s. Fréquence cardiaque : %.1f BPM (cible : %d BPM). Intervalle RR moyen : %.0f ms.', ...
                            length(peak_positions), parameters.duration_s, mean_heart_rate, parameters.heart_rate_bpm, mean_rr_interval_ms);
        else
            interpretation_text = '    Détection insuffisante. Ajustez le seuil ou réduisez le bruit.';
        end
        update_interpretation_zone(interpretation_text);
        
        disp('Traitement ECG termine.');
        
    catch
        disp('ERREUR dans process_ecg_module');
        err = lasterror();
        disp('Message : ' + err.message);
        update_interpretation_zone('    Erreur lors du traitement ECG. Voir console pour détails.');
    end
endfunction

function ecg_signal = generate_ecg_signal(time_vector, N, heart_rate_bpm)
    ecg_signal = zeros(1, N);
    period_s = 60 / heart_rate_bpm;
    
    for i = 1:N
        phase = modulo(time_vector(i), period_s) / period_s;
        
        if phase < 0.2 then
            ecg_signal(i) = 0.2 * exp(-((phase - 0.1)/0.02)^2);
        elseif phase < 0.3 then
            ecg_signal(i) = 1.5 * exp(-((phase - 0.25)/0.01)^2);
        elseif phase < 0.4 then
            ecg_signal(i) = -0.5 * exp(-((phase - 0.35)/0.015)^2);
        elseif phase < 0.6 then
            ecg_signal(i) = 0.4 * exp(-((phase - 0.5)/0.08)^2);
        end
    end
endfunction

function noisy_ecg = add_noise_to_ecg(ecg_signal, time_vector, N, noise_factor)
    baseline_drift = 0.3 * sin(2*%pi*0.2*time_vector);
    random_noise = noise_factor * rand(1, N, 'normal');
    noisy_ecg = ecg_signal + baseline_drift + random_noise;
endfunction

function filtered_ecg = filter_ecg_signal_fft(ecg_signal, sampling_frequency)
    // Filtre passe-bande (5-15 Hz) dans le domaine fréquentiel
    N = length(ecg_signal);
    X = fft(ecg_signal);
    freq = (0:N-1) * sampling_frequency / N;
    
    f_low = 5;
    f_high = 15;
    
    // Créer masque
    mask = zeros(1, N);
    for i = 1:N
        if freq(i) >= f_low & freq(i) <= f_high then
            mask(i) = 1;
        elseif freq(i) >= (sampling_frequency - f_high) & freq(i) <= (sampling_frequency - f_low) then
            mask(i) = 1;
        end
    end
    
    // Appliquer masque
    X_filtered = X .* mask;
    filtered_ecg = real(ifft(X_filtered));
    
    // Normalisation
    filtered_ecg = filtered_ecg - mean(filtered_ecg);
    if max(abs(filtered_ecg)) > 0 then
        filtered_ecg = filtered_ecg / max(abs(filtered_ecg));
    end
endfunction

function positions = detect_r_peaks(signal, sampling_frequency, threshold_factor)
    N = length(signal);
    threshold = threshold_factor * max(signal);
    positions = [];
    i = 1;
    
    min_peak_distance_samples = round(0.3 * sampling_frequency);
    
    while i < N
        if signal(i) > threshold then
            j = i;
            while j < min(N, i + round(0.1*sampling_frequency)) & signal(j) > threshold
                j = j + 1;
            end
            
            segment = signal(i:j);
            [max_val, relative_index] = find_maximum(segment);
            
            positions = [positions, i + relative_index - 1];
            i = j + min_peak_distance_samples;
        else
            i = i + 1;
        end
    end
endfunction

function mean_hr = calculate_mean_hr(peak_times)
    if length(peak_times) >= 2 then
        intervals = diff(peak_times);
        mean_hr = mean(60 ./ intervals);
    else
        mean_hr = 0;
    end
endfunction
