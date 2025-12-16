clear; clc; close;

disp('=========================================');
disp('  Plateforme Traitement Signal   ');
disp('=========================================');
disp('');

// Fonction de nettoyage des fichiers temporaires
function cleanup_temp_files()
    temp_dir = TMPDIR;
    disp('Nettoyage des fichiers temporaires...');
    
    try
        // Lister et supprimer les fichiers .tmp
        temp_files = listfiles(temp_dir + '/*.tmp');
        if ~isempty(temp_files) then
            for i = 1:size(temp_files, 1)
                mdelete(temp_files(i));
            end
            disp(sprintf('  %d fichiers temporaires supprimes.', size(temp_files, 1)));
        end
    catch
        // Ignorer les erreurs (fichiers verrouillés, etc.)
    end
endfunction

// Appeler au début
cleanup_temp_files();

// Déterminer le chemin du dossier source
current_path = pwd();

// Vérifier si on est dans src
if ~isdir('config') then
    // On n'est pas dans src, essayer d'y aller
    if isdir('src') then
        cd('src');
        disp('Navigation vers src/');
    else
        error('Erreur : Impossible de trouver le dossier src. Lancez depuis le dossier Plateforme_Traitement_Signal ou src/');
    end
end
source_path = pwd();
disp('Chemin src : ' + source_path);
disp('');

disp('Chargement des modules de base...');

// 1. Configuration
disp('  -> config/config.sci');
exec('config\config.sci', -1);

// 2. Utilitaires
disp('  -> utils/math_utils.sci');
exec('utils\math_utils.sci', -1);
disp('  -> utils/signal_utils.sci');
exec('utils\signal_utils.sci', -1);

// 3. Interface utilisateur
disp('  -> interface/interface.sci');
exec('interface\interface.sci', -1);
disp('  -> interface/events.sci');
exec('interface\events.sci', -1);
disp('  -> interface/display.sci');
exec('interface\display.sci', -1);

// 4. Modules de traitement 
disp('Chargement des modules de traitement dynamiques (dossier modules/)...');
module_directory = 'modules\';

module_files = listfiles(module_directory + 'process_*.sci');

if isempty(module_files) then
    disp('ATTENTION : Aucun module de traitement trouvé dans ' + module_directory);
else
    for i = 1:size(module_files, 1)
        full_path = module_files(i);
        disp('  -> ' + full_path);
        exec(full_path, -1);
    end
end

disp('');
disp('Tous les modules chargés !');
disp('');

disp('Lancement de l''interface...');
create_main_interface();
disp('Application prete !');
disp('Selectionnez un theme et cliquez sur GENERER.');
disp('');
