// =========================================================================
// Gestion des evenements utilisateur
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

function set_module_config(theme_key, module_config)
    global app_state;
    
    select theme_key
        case 'audio' then
            app_state.modules.audio = module_config;
        case 'image' then
            app_state.modules.image = module_config;
        case 'ecg' then
            app_state.modules.ecg = module_config;
        case 'radar' then
            app_state.modules.radar = module_config;
        case 'radio' then
            app_state.modules.radio = module_config;
        else
            error('Theme inconnu: ' + theme_key);
    end
endfunction

function event_theme_change() 
    global app_state;
    
    try
        if ~isfield(app_state.ui_elements, 'popup_theme') then
            disp('Erreur : popup_theme non trouve');
            return;
        end
        
        popup_handle = app_state.ui_elements.popup_theme;
        selected_index = get(popup_handle, 'value');
        
        app_state.current_theme_key = app_state.theme_keys(selected_index); 
        
        display_theme_parameters_dynamic(app_state.current_theme_key);
        
        update_interpretation_zone('    Theme modifie. Ajustez les parametres puis cliquez sur GENERER.');
    catch
        disp('Erreur dans event_theme_change');
        err = lasterror();
        disp('Message : ' + err.message);
    end
endfunction

function event_generate_results()
    global app_state;
    
    try
        disp('=== DEBUG : Debut generation ===');
        current_key = app_state.current_theme_key;
        disp('Theme actuel : ' + current_key);
        
        // 1. Lire les paramètres
        read_interface_parameters(); 
        
        update_interpretation_zone('    Generation en cours...');
        
        // 2. Récupérer la configuration du module
        if ~isfield(app_state, 'modules') then
            error('app_state.modules non defini');
        end
        
        module_config = get_module_config(current_key);
        
        if ~isfield(module_config, 'process_function') then
            error('process_function non defini pour le module ' + current_key);
        end
        
        process_function_name = module_config.process_function;
        
        disp('Lancement traitement : ' + process_function_name + '()...');
        
        // 3. Exécuter le traitement
        execstr(process_function_name + '()'); 
        
        disp('=== DEBUG : Fin generation ===');
        
    catch
        error_message = 'Erreur lors de la generation. Verifiez vos parametres.';
        disp('');
        disp('=== ERREUR DETAILLEE ===');
        err = lasterror();
        disp('Message : ' + err.message);
        disp('Stack :');
        for i = 1:size(err.stack, 1)
            disp('  Ligne ' + string(err.stack(i).line) + ' dans ' + err.stack(i).name);
        end
        disp('======================');
        disp('');
        update_interpretation_zone('    ' + error_message);
        messagebox([error_message; ''; 'Voir console pour details'], 'Erreur', 'error');
    end
endfunction

function read_interface_parameters()
    global app_state;
    
    current_key = app_state.current_theme_key;
    
    module_config = get_module_config(current_key);
    
    current_params = module_config.default_params;
    
    param_names = fieldnames(current_params);
    
    for i = 1:size(param_names, 1)
        param_key = param_names(i);
        
        value = read_parameter_value(param_key); 
        
        execstr("module_config.default_params." + param_key + " = value;");
        
        if current_key == 'image' & param_key == 'salt_pepper_noise_percent' then
            noise_factor = value / 100;
            execstr("module_config.default_params.noise_level_factor = noise_factor;");
        end
    end
    
    set_module_config(current_key, module_config);
endfunction

function value = read_parameter_value(tag) 
    handle = findobj('tag', 'param_' + tag);
    if isempty(handle) then
        disp('Attention : parametre ' + tag + ' non trouve');
        value = 0;
    else
        try
            value = strtod(get(handle(1), 'string'));
        catch
            disp('Erreur lecture parametre ' + tag);
            value = 0;
        end
    end
endfunction

function update_interpretation_zone(text)
    global app_state;
    
    try
        zone_handle = app_state.ui_elements.interpretation_zone;
        if ~isempty(zone_handle) then
            set(zone_handle, 'string', text);
            drawnow(); 
        else
            disp('Interpretation : ' + text);
        end
    catch
        disp('Erreur mise a jour interpretation');
        disp('Texte : ' + text);
    end
endfunction
