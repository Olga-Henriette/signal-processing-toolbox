// =========================================================================
// Positionnement CORRIGÉ avec graphiques DANS le conteneur
// =========================================================================

function clear_graphics_zone()
    global app_state;
    
    h = findobj(app_state.figure_interface, 'tag', 'graphics_placeholder');
    if ~isempty(h) then
        try
            delete(h);
        catch
        end
    end
    
    fig = app_state.figure_interface;
    children = get(fig, 'children');
    
    for i = 1:length(children)
        try
            if get(children(i), 'type') == 'Axes' then
                delete(children(i));
            end
        catch
        end
    end
    
    graphics_frame = app_state.ui_elements.graphics_frame;
    if ~isempty(graphics_frame) then
        set(graphics_frame, 'visible', 'off');
    end
endfunction

function axes_handle = create_subplot_in_zone(row, col, index, total_rows, total_cols)
    global app_state;
    
    // Position du frame graphique (ZONE GRISE)
    frame_pos = app_state.graphics_zone_position;
    
    // Dimensions de la figure
    fig = app_state.figure_interface;
    fig_pos = get(fig, 'position');
    fig_width = fig_pos(3);
    fig_height = fig_pos(4);
    
    // Marges intérieures au frame (en pixels)
    margin_h = 40;
    margin_v = 50;
    spacing_h = 30;
    spacing_v = 40;
    title_space = 35;  // Espace pour le titre "ZONE D'AFFICHAGE"
    
    // Calcul des dimensions disponibles DANS le frame
    available_width = frame_pos(3) - 2*margin_h - (total_cols-1)*spacing_h;
    available_height = frame_pos(4) - 2*margin_v - (total_rows-1)*spacing_v - title_space;
    
    // Dimensions d'un subplot (en pixels)
    subplot_width = available_width / total_cols;
    subplot_height = available_height / total_rows;
    
    // Position absolue en pixels (origine = bas-gauche du FRAME)
    x_pixel = frame_pos(1) + margin_h + (col-1)*(subplot_width + spacing_h);
    y_pixel = frame_pos(2) + margin_v + (total_rows - row)*(subplot_height + spacing_v);
    
    // CONVERSION EN COORDONNÉES NORMALISÉES [0, 1]
    x_norm = x_pixel / fig_width;
    y_norm = y_pixel / fig_height;
    width_norm = subplot_width / fig_width;
    height_norm = subplot_height / fig_height;
    
    // Créer l'axe avec coordonnées normalisées
    axes_handle = newaxes();
    axes_handle.axes_bounds = [x_norm, y_norm, width_norm, height_norm];
    axes_handle.background = [1 1 1];
    axes_handle.box = 'on';
    axes_handle.margins = [0.12, 0.12, 0.08, 0.12];
    
    sca(axes_handle);
endfunction

function show_audio_results(time, original_signal, noisy_signal, filtered_signal, freq_fft, fft_noisy, fft_filtered)
    global app_state;
    
    scf(app_state.figure_interface);
    clear_graphics_zone();
    
    ax1 = create_subplot_in_zone(1, 1, 1, 2, 2);
    plot(time, noisy_signal, 'b', 'LineWidth', 1.5);
    xlabel('Temps (s)', 'fontsize', 5);
    ylabel('Amplitude', 'fontsize', 5);
    title('Signal Audio Bruité', 'fontsize', 6);
    xgrid();
    
    ax2 = create_subplot_in_zone(1, 2, 2, 2, 2);
    plot(freq_fft, fft_noisy, 'b', 'LineWidth', 1);
    plot(freq_fft, fft_filtered, 'r', 'LineWidth', 1.5);
    xlabel('Fréquence (Hz)', 'fontsize', 5);
    ylabel('Amplitude FFT', 'fontsize', 5);
    title('Spectre: Bruité vs Filtré', 'fontsize', 6);
    legend(['Bruité'; 'Filtré'], 'fontsize', 5);
    xgrid();
    
    ax3 = create_subplot_in_zone(2, 1, 3, 2, 2);
    plot(time, filtered_signal, 'r', 'LineWidth', 1.5);
    xlabel('Temps (s)', 'fontsize', 5);
    ylabel('Amplitude', 'fontsize', 5);
    title('Signal Audio Filtré', 'fontsize', 6);
    xgrid();
    
    ax4 = create_subplot_in_zone(2, 2, 4, 2, 2);
    plot(time, original_signal, 'g', 'LineWidth', 1);
    xlabel('Temps (s)', 'fontsize', 5);
    ylabel('Amplitude', 'fontsize', 5);
    title('Signal Original', 'fontsize', 6);
    xgrid();
    
    drawnow();
endfunction

function show_image_results(img_orig, img_noisy, img_denoised, img_sharpened)
    global app_state;
    
    scf(app_state.figure_interface);
    clear_graphics_zone();
    
    ax1 = create_subplot_in_zone(1, 1, 1, 2, 3);
    Matplot(img_orig');
    colormap(graycolormap(256));
    title('Image Originale', 'fontsize', 6);
    a = gca();
    a.isoview = 'on';
    a.tight_limits = 'on';
    
    ax2 = create_subplot_in_zone(1, 2, 2, 2, 3);
    Matplot(img_noisy');
    colormap(graycolormap(256));
    title('Image Floue et Bruitée', 'fontsize', 6);
    a = gca();
    a.isoview = 'on';
    a.tight_limits = 'on';
    
    ax3 = create_subplot_in_zone(1, 3, 3, 2, 3);
    histplot(256, double(img_noisy(:)));
    title('Histogramme Bruitée', 'fontsize', 6);
    xlabel('Niveau gris', 'fontsize', 6);
    
    ax4 = create_subplot_in_zone(2, 1, 4, 2, 3);
    Matplot(img_denoised');
    colormap(graycolormap(256));
    title('Après Filtre Médian', 'fontsize', 6);
    a = gca();
    a.isoview = 'on';
    a.tight_limits = 'on';
    
    ax5 = create_subplot_in_zone(2, 2, 5, 2, 3);
    Matplot(img_sharpened');
    colormap(graycolormap(256));
    title('Image Finale Accentuée', 'fontsize', 6);
    a = gca();
    a.isoview = 'on';
    a.tight_limits = 'on';
    
    ax6 = create_subplot_in_zone(2, 3, 6, 2, 3);
    histplot(256, double(img_sharpened(:)));
    title('Histogramme Traitée', 'fontsize', 6);
    xlabel('Niveau gris', 'fontsize', 5);
    
    drawnow();
endfunction

function show_ecg_results(time_vector, noisy_ecg, filtered_ecg, peak_times, peak_positions, mean_hr)
    global app_state;
    
    scf(app_state.figure_interface);
    clear_graphics_zone();
    
    ax1 = create_subplot_in_zone(1, 1, 1, 2, 1);
    plot(time_vector, noisy_ecg, 'b', 'LineWidth', 1);
    xlabel('Temps (s)', 'fontsize', 5);
    ylabel('Amplitude', 'fontsize', 5);
    title('ECG Bruité Original', 'fontsize', 6);
    xgrid();
    
    ax2 = create_subplot_in_zone(2, 1, 2, 2, 1);
    plot(time_vector, filtered_ecg, 'g', 'LineWidth', 1.5);
    if ~isempty(peak_positions) & length(peak_positions) <= length(filtered_ecg) then
        plot(peak_times, filtered_ecg(peak_positions), 'ro', 'MarkerSize', 7);
    end
    xlabel('Temps (s)', 'fontsize', 5);
    ylabel('Amplitude', 'fontsize', 5);
    title(sprintf('ECG Filtré avec R-Peaks - FC: %.1f BPM', mean_hr), 'fontsize', 6);
    xgrid();
    
    drawnow();
endfunction

function show_radar_results(time_vector, transmitted_signal, received_signal_noisy, lag_vector, correlation_vector, estimated_delay, estimated_distance)
    global app_state;
    
    scf(app_state.figure_interface);
    clear_graphics_zone();
    
    ax1 = create_subplot_in_zone(1, 1, 1, 3, 1);
    plot(time_vector, transmitted_signal, 'b', 'LineWidth', 1.5);
    xlabel('Temps (s)', 'fontsize', 5);
    ylabel('Amplitude', 'fontsize', 5);
    title('Signal Émis (Chirp)', 'fontsize', 6);
    xgrid();
    
    ax2 = create_subplot_in_zone(2, 1, 2, 3, 1);
    plot(time_vector, received_signal_noisy, 'r', 'LineWidth', 1);
    xlabel('Temps (s)', 'fontsize', 5);
    ylabel('Amplitude', 'fontsize', 5);
    title('Signal Reçu Bruité', 'fontsize', 6);
    xgrid();
    
    ax3 = create_subplot_in_zone(3, 1, 3, 3, 1);
    plot(lag_vector, correlation_vector, 'g', 'LineWidth', 1.5);
    
    [max_value_plot, idx_max] = find_maximum(correlation_vector);
    plot(estimated_delay, max_value_plot, 'ro', 'MarkerSize', 9);
    
    xlabel('Retard (s)', 'fontsize', 5);
    ylabel('Corrélation', 'fontsize', 5);
    title(sprintf('Intercorrélation - Distance: %.0f m', estimated_distance), 'fontsize', 6);
    xgrid();
    
    drawnow();
endfunction

function show_radio_results(transmitted_bits, received_bits, modulated_signal, filtered_signal, modulation_time, parameters, ber)
    global app_state;
    
    scf(app_state.figure_interface);
    clear_graphics_zone();
    
    ax1 = create_subplot_in_zone(1, 1, 1, 4, 1);
    plot(1:parameters.number_of_bits, transmitted_bits, 'b-o', 'LineWidth', 1.5, 'MarkerSize', 3);
    title('Bits Émis', 'fontsize', 6);
    xlabel('Index du bit', 'fontsize', 5);
    ylabel('Valeur', 'fontsize', 5);
    a = gca();
    a.data_bounds = [0, -0.2; parameters.number_of_bits+1, 1.2];
    xgrid();
    
    ax2 = create_subplot_in_zone(2, 1, 2, 4, 1);
    plot(modulation_time, modulated_signal, 'b', 'LineWidth', 1);
    xlabel('Temps (s)', 'fontsize', 5);
    ylabel('Amplitude', 'fontsize', 5);
    title('Signal Modulé (OOK)', 'fontsize', 6);
    xgrid();
    
    ax3 = create_subplot_in_zone(3, 1, 3, 4, 1);
    plot(modulation_time, filtered_signal, 'r', 'LineWidth', 1.5);
    xlabel('Temps (s)', 'fontsize', 5);
    ylabel('Amplitude', 'fontsize', 5);
    title('Signal Démodulé et Filtré', 'fontsize', 6);
    xgrid();
    
    ax4 = create_subplot_in_zone(4, 1, 4, 4, 1);
    plot(1:parameters.number_of_bits, received_bits, 'g-o', 'LineWidth', 1.5, 'MarkerSize', 3);
    
    error_indices = find(transmitted_bits ~= received_bits);
    if ~isempty(error_indices) then
        plot(error_indices, received_bits(error_indices), 'ro', 'MarkerSize', 6);
    end
    
    title(sprintf('Bits Reçus - BER: %.1f%%', ber*100), 'fontsize', 6);
    xlabel('Index du bit', 'fontsize', 5);
    ylabel('Valeur', 'fontsize', 5);
    a = gca();
    a.data_bounds = [0, -0.2; parameters.number_of_bits+1, 1.2];
    xgrid();
    
    drawnow();
endfunction
