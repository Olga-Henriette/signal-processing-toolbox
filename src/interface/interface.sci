// =========================================================================
// SYNCHRONISATION POSITIONS CORRIGÉE
// =========================================================================

function module_config = get_module_config(theme_key)
    global app_state;
    
    select theme_key
        case 'audio' then
            module_config = app_state.modules.audio;
        case 'image' then
            module_config = app_state.modules.image;
        case 'ecg' then
            module_config = app_state.modules.ecg;
        case 'radar' then
            module_config = app_state.modules.radar;
        case 'radio' then
            module_config = app_state.modules.radio;
        else
            error('Theme inconnu: ' + theme_key);
    end
endfunction

function create_main_interface()
    global app_state;
    
    close(winsid());
    
    if ~isfield(app_state, 'ui_elements') then
        app_state.ui_elements = struct();
    end
    
    app_state.layout = struct();
    app_state.layout.margin = 15;
    app_state.layout.padding = 0;
    app_state.layout.small_space = 8;
    app_state.layout.title_height = 45;
    app_state.layout.selector_height = 30;
    app_state.layout.button_height = 45;
    app_state.layout.interp_height = 60;
    app_state.layout.label_height = 25;
    app_state.layout.field_height = 28;
    app_state.layout.params_width = 300;
    
    config = app_state.ui_config;
    
    figure_handle = figure('figure_name', 'Plateforme Traitement Signal v2.0', ...
                 'position', [50, 50, config.width, config.height], ...
                 'background', config.background_color, ...
                 'resizefcn', 'resize_interface()');
    
    app_state.figure_interface = figure_handle;
    
    create_title_bar();
    create_theme_selector();
    create_parameters_panel();
    create_graphics_panel();
    create_generate_button();
    create_interpretation_zone();
    
    resize_interface();
    show_welcome_message();
    display_theme_parameters_dynamic(app_state.current_theme_key);
endfunction

function create_title_bar()
    global app_state;
    lay = app_state.layout;
    
    uicontrol(app_state.figure_interface, 'style', 'text', ...
              'string', 'PLATEFORME DE TRAITEMENT DE SIGNAL', ...
              'position', [lay.margin, 650, 1170, lay.title_height], ...
              'fontsize', 16, ...
              'fontweight', 'bold', ...
              'background', [0.2 0.4 0.7], ...
              'foreground', [1 1 1], ...
              'horizontalalignment', 'center', ...
              'tag', 'title_bar');
endfunction

function create_theme_selector()
    global app_state;
    lay = app_state.layout;
    
    x_start = lay.margin + lay.params_width + lay.margin;
    
    uicontrol(app_state.figure_interface, 'style', 'text', ...
              'string', '   Sélectionner un thème :', ...
              'position', [x_start, 600, 160, lay.selector_height], ...
              'fontsize', 11, ...
              'background', app_state.ui_config.background_color, ...
              'horizontalalignment', 'left', ...
              'tag', 'theme_label');
    
    popup_handle = uicontrol(app_state.figure_interface, 'style', 'popupmenu', ...
                        'string', app_state.theme_display_names, ...
                        'position', [x_start + 170, 600, 450, lay.selector_height], ...
                        'fontsize', 11, ...
                        'tag', 'popup_theme_selector', ...
                        'callback', 'event_theme_change()');
    
    app_state.ui_elements.popup_theme = popup_handle;
    
    uicontrol(app_state.figure_interface, 'style', 'pushbutton', ...
              'string', '?  Aide', ...
              'position', [1070, 600, 110, lay.selector_height], ...
              'fontsize', 10, ...
              'background', [0.9 0.9 0.9], ...
              'callback', 'show_help()', ...
              'tag', 'help_button');
endfunction

function create_parameters_panel()
    global app_state;
    lay = app_state.layout;
    
    h_frame = uicontrol(app_state.figure_interface, 'style', 'frame', ...
              'position', [lay.margin, 80, lay.params_width, 500], ...
              'background', [1 1 1], ...
              'tag', 'panel_parameters_frame');
              
    app_state.ui_elements.params_panel_frame = h_frame;
    
    uicontrol(app_state.figure_interface, 'style', 'text', ...
              'string', 'PARAMÈTRES', ...
              'position', [lay.margin + lay.padding, 545, lay.params_width - 2*lay.padding, 30], ...
              'fontsize', 12, ...
              'fontweight', 'bold', ...
              'background', [0.3 0.5 0.8], ...
              'foreground', [1 1 1], ...
              'horizontalalignment', 'center', ...
              'tag', 'params_title');
endfunction

function create_graphics_panel()
    global app_state;
    lay = app_state.layout;
    
    x_graph_start = lay.margin + lay.params_width + lay.margin;
    
    frame_x = x_graph_start - 15;
    frame_y = 80 - 10;  
    frame_w = 850 + 24;
    frame_h = 500;
    
    h_frame = uicontrol(app_state.figure_interface, 'style', 'frame', ...
              'position', [frame_x, frame_y, frame_w, frame_h], ...
              'background', [0.92 0.92 0.92], ...
              'relief', 'sunken', ...
              'tag', 'panel_graphics_zone');
    
    app_state.ui_elements.graphics_frame = h_frame;
    
    app_state.graphics_zone_position = [frame_x, frame_y, frame_w, frame_h];
    
    uicontrol(app_state.figure_interface, 'style', 'text', ...
              'string', 'ZONE D''AFFICHAGE DES GRAPHIQUES', ...
              'position', [frame_x + lay.padding, 545, frame_w - 2*lay.padding, 30], ...
              'fontsize', 12, ...
              'fontweight', 'bold', ...
              'background', [0.3 0.5 0.8], ...
              'foreground', [1 1 1], ...
              'horizontalalignment', 'center', ...
              'tag', 'graphics_title_text');
    
    h_msg = uicontrol(app_state.figure_interface, 'style', 'text', ...
              'string', 'Les graphiques s''afficheront ici...', ...
              'position', [frame_x + 50, 300, frame_w - 100, 40], ...
              'fontsize', 12, ...
              'background', [0.92 0.92 0.92], ...
              'foreground', [0.5 0.5 0.5], ...
              'horizontalalignment', 'center', ...
              'tag', 'graphics_placeholder');
    
    app_state.ui_elements.graphics_placeholder = h_msg;
endfunction

function create_generate_button()
    global app_state;
    lay = app_state.layout;
    
    button_handle = uicontrol(app_state.figure_interface, 'style', 'pushbutton', ...
                      'string', 'GÉNÉRER LES GRAPHIQUES', ...
                      'position', [lay.margin + lay.padding, 95, lay.params_width - 2*lay.padding, lay.button_height], ...
                      'fontsize', 12, ...
                      'fontweight', 'bold', ...
                      'background', [0.2 0.7 0.3], ...
                      'foreground', [1 1 1], ...
                      'tag', 'button_generate', ...
                      'callback', 'event_generate_results()');
    
    app_state.ui_elements.button_generate = button_handle;
endfunction

function create_interpretation_zone()
    global app_state;
    lay = app_state.layout;
    
    x_start = lay.margin + lay.params_width + lay.margin;
    width = 850;
    
    uicontrol(app_state.figure_interface, 'style', 'text', ...
              'string', 'INTERPRÉTATION DES RÉSULTATS', ...
              'position', [x_start, 65, width, 18], ...
              'fontsize', 10, ...
              'fontweight', 'bold', ...
              'background', app_state.ui_config.background_color, ...
              'horizontalalignment', 'center', ...
              'tag', 'interp_title');
    
    zone_handle = uicontrol(app_state.figure_interface, 'style', 'text', ...
                       'string', '    Sélectionnez un thème et cliquez sur GÉNÉRER pour voir les résultats...', ...
                       'position', [x_start, lay.margin, width, lay.interp_height - 5], ...
                       'fontsize', 10, ...
                       'background', [1 1 0.9], ...
                       'tag', 'interpretation_zone_text', ...
                       'horizontalalignment', 'left');
    
    app_state.ui_elements.interpretation_zone = zone_handle;
endfunction

function display_theme_parameters_dynamic(theme_key)
    global app_state;
    lay = app_state.layout;
    
    clear_parameter_zone();
    
    module_config = get_module_config(theme_key);
    default_params = module_config.default_params;
    
    panel_position = get(app_state.ui_elements.params_panel_frame, 'position');
    
    y_start = panel_position(2) + panel_position(4) - 50;
    step = lay.field_height + lay.small_space;
    
    param_names = fieldnames(default_params);
    current_y = y_start;
    
    for i = 1:size(param_names, 1)
        param_key = param_names(i);
        execstr("param_value = default_params." + param_key + ";");
        
        label_text = get_param_label(theme_key, param_key);
        create_parameter_field(label_text, param_key, current_y, param_value);
        
        current_y = current_y - step;
    end
endfunction

function create_parameter_field(label, tag, y_pos, value)
    global app_state;
    lay = app_state.layout;
    
    x_base = lay.margin + lay.padding;
    label_width = 170;
    field_width = 80;
    
    uicontrol(app_state.figure_interface, 'style', 'text', ...
              'string', label + ' :', ...
              'position', [x_base, y_pos, label_width, lay.label_height], ...
              'horizontalalignment', 'left', ...
              'fontsize', 10, ...
              'background', [1 1 1], ...
              'tag', 'param_label_' + tag);
    
    uicontrol(app_state.figure_interface, 'style', 'edit', ...
              'string', string(value), ...
              'position', [x_base + label_width + 5, y_pos, field_width, lay.field_height], ...
              'fontsize', 10, ...
              'background', [0.98 0.98 1], ...
              'tag', 'param_' + tag);
endfunction

function clear_parameter_zone()
    global app_state;
    
    h_all = findobj(app_state.figure_interface);
    
    for i = 1:length(h_all)
        try
            if get(h_all(i), 'type') == 'uicontrol' then
                tag_val = get(h_all(i), 'tag');
                
                if strncmp(tag_val, 'param_', 6) | strncmp(tag_val, 'param_label_', 12) then
                    delete(h_all(i));
                end
            end
        catch
        end
    end
endfunction

function resize_interface()
    global app_state;
    
    if isempty(app_state.figure_interface) then return; end
    
    lay = app_state.layout;
    fig = app_state.figure_interface;
    fig_pos = get(fig, 'position');
    fig_w = fig_pos(3);
    fig_h = fig_pos(4);
    
    y_top = fig_h - lay.margin - lay.title_height;
    y_selector = y_top;
    y_panels_top = y_selector - lay.selector_height - lay.small_space;
    y_panels_bottom = lay.margin + lay.interp_height + lay.margin;
    panels_height = y_panels_top - y_panels_bottom;
    
    // TITRE
    h = findobj(fig, 'tag', 'title_bar');
    if ~isempty(h) then
        set(h(1), 'position', [0, y_top + 13, fig_w, lay.title_height]);
    end
    
    x_graph_start = lay.margin + lay.params_width + lay.margin;
    
    // SÉLECTEUR
    h = findobj(fig, 'tag', 'theme_label');
    if ~isempty(h) then
        set(h(1), 'position', [x_graph_start - 15, y_selector - 23, 160, lay.selector_height]);
    end
    
    if ~isempty(app_state.ui_elements.popup_theme) then
        set(app_state.ui_elements.popup_theme, 'position', [x_graph_start + 170, y_selector - 23, 450, lay.selector_height]);
    end
    
    h = findobj(fig, 'tag', 'help_button');
    if ~isempty(h) then
        set(h(1), 'position', [fig_w - lay.margin - 110, y_selector - 23, 120, lay.selector_height]);
    end
    
    // PANNEAU PARAMÈTRES
    if ~isempty(app_state.ui_elements.params_panel_frame) then
        set(app_state.ui_elements.params_panel_frame, 'position', [5, y_panels_bottom - 85, lay.params_width, panels_height + 100]);
    end
    
    h = findobj(fig, 'tag', 'params_title');
    if ~isempty(h) then
        set(h(1), 'position', [5, y_selector - 23, lay.params_width - 4*lay.padding, 30]);
    end
    
    if ~isempty(app_state.ui_elements.button_generate) then
        set(app_state.ui_elements.button_generate, 'position', [5, y_panels_bottom - 5, lay.params_width - 4*lay.padding, lay.button_height]);
    end
    
    // ZONE GRAPHIQUE
    graph_width = fig_w - x_graph_start - lay.margin;
    
    frame_x = x_graph_start - 15;
    frame_y = y_panels_bottom - 10;
    frame_w = graph_width + 24;
    frame_h = panels_height;
    
    // Mettre à jour le frame UI
    if ~isempty(app_state.ui_elements.graphics_frame) then
        set(app_state.ui_elements.graphics_frame, 'position', [frame_x, frame_y, frame_w, frame_h]);
    end
    
    // SYNCHRONISATION : Utiliser EXACTEMENT la même position pour les graphiques
    app_state.graphics_zone_position = [frame_x, frame_y, frame_w, frame_h];
    
    h = findobj(fig, 'tag', 'graphics_title_text');
    if ~isempty(h) then
        set(h(1), 'position', [x_graph_start + lay.padding - 15, y_panels_bottom + panels_height - 23, graph_width + 24, 30]);
    end
    
    // INTERPRÉTATION
    h = findobj(fig, 'tag', 'interp_title');
    if ~isempty(h) then
        set(h(1), 'position', [x_graph_start - 15, y_panels_bottom - 32, graph_width + 24, 18]);
    end
    
    if ~isempty(app_state.ui_elements.interpretation_zone) then
        set(app_state.ui_elements.interpretation_zone, 'position', [x_graph_start - 15, 2, graph_width + 24, lay.interp_height - 5]);
    end
endfunction

function show_welcome_message()
    msg = ['Bienvenue sur la Plateforme v2.0 !'; ...
           ''; ...
           'Sélectionnez un thème pour commencer.'];
    messagebox(msg, 'Bienvenue', 'info');
endfunction

function show_help()
    msg = ['AIDE - Plateforme v2.0'; ...
           ''; ...
           '1. Sélectionnez un thème dans la liste'; ...
           '2. Ajustez les paramètres selon vos besoins'; ...
           '3. Cliquez sur GÉNÉRER pour voir les résultats'; ...
           ''; ...
           'Thèmes disponibles :'; ...
           '• Audio : Filtrage de bruits parasites'; ...
           '• Image : Restauration netteté d''images'; ...
           '• ECG : Détection des battements cardiaques'; ...
           '• Radar : Estimation de distance par corrélation'; ...
           '• Radio : Communication numérique OOK'];
    messagebox(msg, 'Aide', 'info');
endfunction

function label_text = get_param_label(theme_key, param_key)
    select theme_key
        case 'audio' then
            select param_key
                case 'duration_s' then label_text = 'Durée du signal (s)';
                case 'fan_freq_hz' then label_text = 'Fréq. ventilateur (Hz)';
                case 'whistle_freq_hz' then label_text = 'Fréq. sifflement (Hz)';
                case 'noise_level_factor' then label_text = 'Niveau bruit (0-1)';
                else label_text = param_key;
            end
            
        case 'image' then
            select param_key
                case 'blur_sigma' then label_text = 'Intensité du flou';
                case 'salt_pepper_noise_percent' then label_text = 'Bruit poivre/sel (%)';
                case 'median_filter_size' then label_text = 'Taille filtre médian';
                else label_text = param_key;
            end
            
        case 'ecg' then
            select param_key
                case 'duration_s' then label_text = 'Durée (s)';
                case 'heart_rate_bpm' then label_text = 'Fréq. cardiaque (BPM)';
                case 'noise_level_factor' then label_text = 'Niveau bruit (0-1)';
                case 'detection_threshold' then label_text = 'Seuil détection (0-1)';
                else label_text = param_key;
            end
            
        case 'radar' then
            select param_key
                case 'target_distance_m' then label_text = 'Distance cible (m)';
                case 'snr_db' then label_text = 'SNR (dB)';
                case 'chirp_start_freq_hz' then label_text = 'Fréq chirp début (Hz)';
                case 'chirp_end_freq_hz' then label_text = 'Fréq chirp fin (Hz)';
                else label_text = param_key;
            end
            
        case 'radio' then
            select param_key
                case 'number_of_bits' then label_text = 'Nombre de bits';
                case 'bit_duration_s' then label_text = 'Durée par bit (s)';
                case 'carrier_freq_hz' then label_text = 'Fréq porteuse (Hz)';
                case 'snr_db' then label_text = 'SNR (dB)';
                else label_text = param_key;
            end
            
        else
            label_text = param_key;
    end
endfunction
