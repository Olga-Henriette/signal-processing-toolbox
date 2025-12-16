// =========================================================================
// Fonctions utilitaires pour le traitement de signal
// =========================================================================

function [frequencies, spectrum] = calculate_fft_spectrum(signal, sampling_frequency)
    // Calcule le spectre FFT d'un signal
    N = length(signal);
    
    // Calcul de la FFT
    Y = fft(signal);
    
    // Calcul de l'amplitude (Module)
    P2 = abs(Y);
    
    // On ne prend que la moitié (Spectre à simple face, de 0 à fe/2)
    P1 = P2(1:floor(N/2)+1);
    
    // Multiplier par 2 pour les fréquences non nulles (théorème de Parseval)
    P1(2:(end-1)) = 2 * P1(2:(end-1));

    
    // Normalisation par la longueur du signal
    spectrum = P1 / N;
    
    // Vecteur Fréquence
    frequencies = sampling_frequency * (0:floor(N/2)) / N;
endfunction

// On pourrait ajouter ici d'autres fonctions comme 'apply_filter', 'time_to_samples', etc.
