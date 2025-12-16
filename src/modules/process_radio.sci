// =========================================================================
// Liaison radio OOK
// =========================================================================
function process_radio_module()
    global app_state;
    
    disp('Debut traitement liaison radio...');
        
    try
        module_config = app_state.modules.radio;
        parameters = module_config.default_params;
        
        sampling_frequency = 22050;
        sampling_period = 1/sampling_frequency;
        
        disp('Generation du message binaire...');
        transmitted_bits = round(rand(1, parameters.number_of_bits));
        
        disp('Modulation OOK...');
        modulation_duration = parameters.number_of_bits * parameters.bit_duration_s;
        modulation_time = 0:sampling_period:(modulation_duration - sampling_period);
        modulated_signal = zeros(1, length(modulation_time));
        carrier_frequency = parameters.carrier_freq_hz;
        
        for i = 1:parameters.number_of_bits
            bit_start_time = (i-1) * parameters.bit_duration_s;
            bit_end_time = i * parameters.bit_duration_s;
            bit_indices = find(modulation_time >= bit_start_time & modulation_time < bit_end_time);
            
            if transmitted_bits(i) == 1 then
                modulated_signal(bit_indices) = sin(2*%pi*carrier_frequency*modulation_time(bit_indices));
            end
        end
        
        disp('Ajout du bruit de canal...');
        signal_power = mean(modulated_signal.^2);
        
        if signal_power > 0 then
            noise_power = signal_power / (10^(parameters.snr_db/10));
        else
            noise_power = 0.01;
        end
        
        channel_noise = sqrt(noise_power) * rand(1, length(modulated_signal), 'normal');
        received_signal = modulated_signal + channel_noise;
        
        disp('Demodulation...');
        demodulated_signal = received_signal .* sin(2*%pi*carrier_frequency*modulation_time);
        
        // Filtre passe-bas simple dans le domaine fréquentiel
        disp('Filtrage passe-bas...');
        cutoff_frequency = 50;
        filtered_signal = lowpass_filter_fft(demodulated_signal, sampling_frequency, cutoff_frequency);
        
        disp('Decision binaire...');
        received_bits = zeros(1, parameters.number_of_bits);
        decision_threshold = max(filtered_signal) * 0.3;
        
        for i = 1:parameters.number_of_bits
            bit_start_time = (i-1) * parameters.bit_duration_s;
            bit_end_time = i * parameters.bit_duration_s;
            bit_indices = find(modulation_time >= bit_start_time & modulation_time < bit_end_time);
            sample_index = round(mean(bit_indices));
            
            if sample_index <= length(filtered_signal) & filtered_signal(sample_index) > decision_threshold then
                received_bits(i) = 1;
            end
        end
        
        // Calcul BER
        errors = sum(transmitted_bits ~= received_bits);
        bit_error_rate = errors / parameters.number_of_bits;
        
        disp('Affichage des graphiques...');
        show_radio_results(transmitted_bits, received_bits, modulated_signal, filtered_signal, modulation_time, parameters, bit_error_rate);
        
        // Interpretation
        if bit_error_rate == 0 then
            interpretation_text = sprintf('    Transmission parfaite ! Les %d bits ont été reçus sans erreur (BER = 0%%). SNR: %.1f dB.', ...
                            parameters.number_of_bits, parameters.snr_db);
        else
            interpretation_text = sprintf('    %d erreur(s) sur %d bits (BER = %.1f%%). Augmentez le SNR (actuellement %.1f dB) pour améliorer la transmission.', ...
                            errors, parameters.number_of_bits, bit_error_rate*100, parameters.snr_db);
        end
        
        update_interpretation_zone(interpretation_text);
        
        disp('Traitement liaison radio termine !');
        
    catch
        disp('ERREUR dans process_radio_module');
        err = lasterror();
        disp('Message : ' + err.message);
        disp('Details de l''erreur :');
        for i = 1:size(err.stack, 1)
            disp('  Ligne ' + string(err.stack(i).line) + ' dans ' + err.stack(i).name);
        end
        update_interpretation_zone('    Erreur lors du traitement radio. Voir console pour détails.');
    end
endfunction

function filtered_signal = lowpass_filter_fft(input_signal, sampling_frequency, cutoff_frequency)
    // Filtre passe-bas dans le domaine fréquentiel
    N = length(input_signal);
    X = fft(input_signal);
    freq = (0:N-1) * sampling_frequency / N;
    
    // Créer un masque fréquentiel
    mask = zeros(1, N);
    for i = 1:N
        if freq(i) <= cutoff_frequency then
            mask(i) = 1;
        elseif freq(i) >= (sampling_frequency - cutoff_frequency) then
            mask(i) = 1; // Fréquences négatives (miroir)
        end
    end
    
    // Appliquer le masque
    X_filtered = X .* mask;
    
    // IFFT
    filtered_signal = real(ifft(X_filtered));
endfunction
