// =========================================================================
// Nettoyage audio
// =========================================================================
function process_audio_module()
    global app_state;
    
    disp('Debut traitement Audio...');
    
    try
        module_config = app_state.modules.audio;
        parameters = module_config.default_params;
        
        sampling_frequency = 44100;
        sampling_period = 1/sampling_frequency;
        
        time_vector = 0:sampling_period:(parameters.duration_s - sampling_period);
        N = length(time_vector);
        
        disp('Generation signal audio...');
        clean_audio = generate_speech_audio(time_vector);
        
        disp('Ajout des bruits...');
        noise_audio = generate_noise_audio(time_vector, N, parameters.fan_freq_hz, parameters.whistle_freq_hz, parameters.noise_level_factor);
        noisy_signal = clean_audio + noise_audio;
        
        disp('Filtrage des bruits...');
        filtered_signal = filter_audio_noise_simple(noisy_signal, sampling_frequency, parameters.fan_freq_hz, parameters.whistle_freq_hz);
        
        disp('Analyse frequentielle...');
        [freq_fft, fft_noisy] = calculate_fft_spectrum(noisy_signal, sampling_frequency);
        [freq_fft_filtered, fft_filtered] = calculate_fft_spectrum(filtered_signal, sampling_frequency);
        
        snr_noisy = calculate_snr(clean_audio, noisy_signal);
        snr_filtered = calculate_snr(clean_audio, filtered_signal);
        snr_improvement = snr_filtered - snr_noisy;
        
        disp('Affichage resultats...');
        show_audio_results(time_vector, clean_audio, noisy_signal, filtered_signal, freq_fft, fft_noisy, fft_filtered);
        
        interpretation_text = sprintf('    Traitement réussi ! SNR bruité : %.1f dB. SNR filtré : %.1f dB. Gain de %.1f dB. Les filtres ont éliminé les fréquences parasites (%.0f Hz et %.0f Hz).', ...
                        snr_noisy, snr_filtered, snr_improvement, parameters.fan_freq_hz, parameters.whistle_freq_hz);
        update_interpretation_zone(interpretation_text);
        
        disp('Traitement Audio termine.');
        
    catch
        disp('ERREUR dans process_audio_module');
        err = lasterror();
        disp('Message : ' + err.message);
        update_interpretation_zone('    Erreur lors du traitement audio. Voir console pour détails.');
    end
endfunction

function clean_audio = generate_speech_audio(time_vector)
    frequency_base = 400;
    amplitudes = (0.5 + 0.5 * sin(2*%pi*1.5*time_vector));
    clean_audio = amplitudes .* sin(2*%pi*frequency_base*time_vector);
    clean_audio = clean_audio * 0.8;
endfunction

function noise_audio = generate_noise_audio(time_vector, N, f_fan, f_whistle, noise_factor)
    fan_noise = 0.5 * cos(2*%pi*f_fan*time_vector);
    whistle_noise = 0.3 * sin(2*%pi*f_whistle*time_vector);
    white_noise = noise_factor * rand(1, N, 'normal');
    noise_audio = fan_noise + whistle_noise + white_noise;
endfunction

function filtered_signal = filter_audio_noise_simple(input_signal, sampling_frequency, f_fan, f_whistle)
    // Filtre passe-bande simple pour conserver la voix (200-3500 Hz)
    f_low = 200;
    f_high = 3500;
    
    // Calculer la FFT
    N = length(input_signal);
    X = fft(input_signal);
    freq = (0:N-1) * sampling_frequency / N;
    
    // Créer un masque fréquentiel (filtre idéal)
    mask = zeros(1, N);
    for i = 1:N
        if freq(i) >= f_low & freq(i) <= f_high then
            mask(i) = 1;
        elseif freq(i) >= (sampling_frequency - f_high) & freq(i) <= (sampling_frequency - f_low) then
            mask(i) = 1; // Fréquences négatives (miroir)
        end
        
        // Supprimer les fréquences spécifiques (notch)
        if abs(freq(i) - f_fan) < 20 then
            mask(i) = 0;
        end
        if abs(freq(i) - f_whistle) < 100 then
            mask(i) = 0;
        end
        if abs(freq(i) - (sampling_frequency - f_fan)) < 20 then
            mask(i) = 0;
        end
        if abs(freq(i) - (sampling_frequency - f_whistle)) < 100 then
            mask(i) = 0;
        end
    end
    
    // Appliquer le masque
    X_filtered = X .* mask;
    
    // IFFT pour revenir au domaine temporel
    filtered_signal = real(ifft(X_filtered));
endfunction
