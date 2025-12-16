// =========================================================================
// Fonctions mathématiques génériques
// =========================================================================

function [max_value, max_index]=find_maximum(vector)
    // Retourne la valeur maximale et l'index de la première occurrence
    max_value = max(vector);
    max_index = find(vector == max_value, 1);
endfunction

function output=modulo(a, b)
    // Calcule le modulo
    output = a - b * floor(a/b);
endfunction

function mse=calculate_mse(img1, img2) 
    // Mean Squared Error (Erreur Quadratique Moyenne)
    diff_img = double(img1) - double(img2);
    mse = mean(diff_img.^2);
endfunction

function snr_db=calculate_snr(clean_signal, noisy_signal)
    // Calcul du rapport Signal sur Bruit (SNR) en dB
    
    // Erreur (Bruit) = Signal Bruité - Signal Propre
    noise = noisy_signal - clean_signal;
    
    // Puissance du signal propre
    signal_power = mean(clean_signal.^2);
    
    // Puissance du bruit
    noise_power = mean(noise.^2);
    
    if signal_power > 1e-10 & noise_power > 1e-10 then
        snr_db = 10 * log10(signal_power / noise_power);
    else
        snr_db = 999; // Valeur très haute si pas de bruit ou pas de signal
    end
endfunction
