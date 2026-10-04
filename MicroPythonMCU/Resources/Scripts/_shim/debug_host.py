# Hote du debogueur (debugpy) d'un microcontroleur - cf. requirements.md,
# decision "Debogage du programme (debugpy + VS Code)".
#
# Execute par le worker (pyruntime_module.c, worker_init) dans un module
# propre, _mcu_debug, quand MCU.debugEnabled est vrai. Trois temps :
#   start() AVANT le shim : debugpy est importe tant que time est encore le
#           vrai module (pydevd refuse un time sans mktime, et ses attentes
#           doivent etre de vraies attentes, pas des sleep() simules) ;
#   wait()  au premier tour du worker (t=0), une fois tous les composants du
#           modele construits (worker_main) : la copie de la flash existe, on
#           pose la correspondance des chemins, puis on attend VS Code ;
#   stop()  en fin de simulation, avant Py_EndInterpreter : les threads de
#           pydevd doivent etre arretes, sinon le sous-interpreteur ne peut
#           pas etre termine.
import os, sys, time as _host_time   # vrai time : importe avant le shim

DEBUGPY_DIR = None          # lu par le shim (_fs_mount) : jamais cloisonne
_port = 0


def start(port, debugpy_dir, shim_dir):
    global DEBUGPY_DIR, _port
    DEBUGPY_DIR = debugpy_dir
    _port = port
    # Modules geles de la stdlib : pydevd avertit qu'il pourrait y manquer
    # des points d'arret - sans objet, on ne debogue que le programme.
    os.environ['PYDEVD_DISABLE_FILE_VALIDATION'] = '1'
    sys.path.insert(0, debugpy_dir)
    import debugpy
    import debugpy.server.api      # met pydevd (vendore par debugpy) dans sys.path
    # Le pas a pas n'entre pas dans le shim : son dossier est declare racine de
    # bibliotheque, que justMyCode (reglage par defaut de VS Code) saute. Pas
    # PYDEVD_FILTERS : l'attachement les remplace par les "rules" du client.
    # LIBRARY_ROOTS remplace les racines par defaut, d'ou leur reprise.
    from _pydevd_bundle.pydevd_filtering import FilesFiltering
    roots = FilesFiltering._get_default_library_roots() + [shim_dir]
    os.environ['LIBRARY_ROOTS'] = os.pathsep.join(roots)
    if os.environ.get('MCU_DEBUGPY_LOG'):
        debugpy.log_to(os.environ['MCU_DEBUGPY_LOG'])
    debugpy.configure(subProcess=False)
    # Adaptateur DAP dans le process : le mode par defaut lancerait
    # sys.executable, ici l'executable de simulation.
    debugpy.listen(('127.0.0.1', port), in_process_debug_adapter=True)


def wait(port, fs_source, fs_copy):
    import debugpy
    import pydevd_file_utils
    # Seule correspondance de chemins : image de la flash -> copie horodatee
    # (les programmes de la flash s'executent depuis la copie, l'eleve ouvre
    # l'image). Les pathMappings du client sont IGNORES : VS Code et la
    # simulation sont sur le meme poste (ecoute sur 127.0.0.1), ils n'ont
    # jamais lieu d'etre. Le modele "Remote Attach" de VS Code en met un
    # ({workspaceFolder} -> "."), que pydevd resout vers le dossier courant
    # de la simulation (celui d'OMEdit) : aucun point d'arret n'etait plus
    # atteint. pydevd les applique a l'attachement par
    # setup_client_server_paths, d'ou son remplacement.
    paths = [(os.path.abspath(fs_source), os.path.abspath(fs_copy))] if fs_source and fs_copy else []
    setup = pydevd_file_utils.setup_client_server_paths

    def setup_ignoring_client(client_paths):
        setup(paths)

    pydevd_file_utils.setup_client_server_paths = setup_ignoring_client
    setup(paths)
    print('Debugger: waiting for VS Code on port %d (Run and Debug > attach to localhost:%d)' % (port, port))
    sys.stdout.flush()
    debugpy.wait_for_client()
    print('Debugger: VS Code attached')


def stop():
    import socket, threading
    # pydevd.stoptrace() arrete les threads de pydevd, sauf celui qui attend
    # une (nouvelle) connexion de VS Code, bloque dans accept() : sous Windows,
    # fermer la socket depuis un autre thread ne le reveille pas, et il
    # empecherait de terminer le sous-interpreteur. On lui demande de
    # s'arreter, puis une connexion locale factice le debloque.
    for t in list(threading._active.values()):
        if type(t).__name__ == '_WaitForConnectionThread' and t.is_alive():
            t._kill_received = True
            try:
                socket.create_connection(('127.0.0.1', _port), timeout=0.5).close()
            except OSError:
                pass
            t.join(0.5)
    try:
        import pydevd
        reader = getattr(pydevd.get_global_debugger(), 'reader', None)
        # Envoie "terminated" a VS Code (qui ferme alors la session) et arrete
        # les threads de pydevd...
        pydevd.stoptrace()
        # ... sauf le lecteur, qui attend que VS Code ferme la connexion. S'il
        # ne l'a pas fait (client lent, ou en attente d'un arret qui ne
        # viendra plus), on la coupe : sous Windows, rien d'autre ne le
        # reveille.
        if reader is not None and reader.is_alive():
            try:
                reader.sock.shutdown(socket.SHUT_RDWR)
            except OSError:
                pass
            reader.join(0.5)
    except Exception:
        pass
