"""Teste l'attachement anticipe du debogueur, avec et sans flash.

Verifie que les chemins client attendent la correspondance image -> copie et
que les correspondances fournies par le client sont ignorees.
"""

import contextlib
import io
import os
from pathlib import Path
import runpy
import sys
import threading
import types
import unittest
from unittest.mock import Mock, patch


HOST = Path(__file__).resolve().parent.parent / 'Scripts' / '_shim' / 'debug_host.py'


class DebugHostPathsTest(unittest.TestCase):
    def test_early_attach_waits_for_flash_paths(self):
        for flash in (False, True):
            with self.subTest(flash=flash):
                debugpy = types.ModuleType('debugpy')
                debugpy.__path__ = []
                debugpy.configure = Mock()
                debugpy.listen = Mock()
                debugpy.wait_for_client = Mock()
                server = types.ModuleType('debugpy.server')
                server.__path__ = []
                api = types.ModuleType('debugpy.server.api')
                filtering = types.ModuleType('_pydevd_bundle.pydevd_filtering')
                filtering.FilesFiltering = type('FilesFiltering', (), {
                    '_get_default_library_roots': staticmethod(lambda: []),
                })
                bundle = types.ModuleType('_pydevd_bundle')
                bundle.__path__ = []
                file_utils = types.ModuleType('pydevd_file_utils')
                setup = Mock()
                file_utils.setup_client_server_paths = setup
                modules = {
                    'debugpy': debugpy, 'debugpy.server': server,
                    'debugpy.server.api': api, '_pydevd_bundle': bundle,
                    '_pydevd_bundle.pydevd_filtering': filtering,
                    'pydevd_file_utils': file_utils,
                }
                with patch.dict(sys.modules, modules), patch.dict(os.environ), patch.object(sys, 'path', sys.path[:]):
                    host = runpy.run_path(str(HOST))
                    host['start'](5860, 'debugpy-dir', 'shim-dir')
                    started = threading.Event()
                    finished = threading.Event()

                    def attach():
                        started.set()
                        file_utils.setup_client_server_paths([('client', 'ignored')])
                        finished.set()

                    thread = threading.Thread(target=attach)
                    thread.start()
                    try:
                        self.assertTrue(started.wait(2))
                        self.assertFalse(finished.wait(0.1))
                        source, copy = ('flash-source', 'flash-copy') if flash else ('', '')
                        with contextlib.redirect_stdout(io.StringIO()):
                            host['wait'](5860, source, copy)
                        self.assertTrue(finished.wait(2))
                        expected = [(os.path.abspath(source), os.path.abspath(copy))] if flash else []
                        self.assertEqual(setup.call_args_list, [unittest.mock.call(expected)] * 2)
                    finally:
                        host['start'].__globals__['_paths_ready'].set()
                        thread.join(2)
                        self.assertFalse(thread.is_alive())


if __name__ == '__main__':
    unittest.main()
