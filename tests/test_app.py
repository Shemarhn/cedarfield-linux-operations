import importlib.util
import json
import secrets
import sqlite3
import tempfile
import threading
import unittest
import urllib.error
import urllib.request
from pathlib import Path

spec = importlib.util.spec_from_file_location('server', Path(__file__).parents[1] / 'app/server.py')
app = importlib.util.module_from_spec(spec)
spec.loader.exec_module(app)


class AppTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.db = str(Path(self.tmp.name) / 'jobs.sqlite')
        self.token = secrets.token_urlsafe(32)
        self.server = app.make_server(self.db, self.token, 0)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        self.url = 'http://127.0.0.1:' + str(self.server.server_port)

    def tearDown(self):
        self.server.shutdown()
        self.thread.join()
        self.server.server_close()
        self.tmp.cleanup()

    def request(self, route, data=None, authorized=False):
        headers = {'Content-Type': 'application/json'}
        if authorized:
            headers['Authorization'] = 'Bearer ' + self.token
        req = urllib.request.Request(self.url + route, data=json.dumps(data).encode() if data is not None else None, headers=headers)
        return urllib.request.urlopen(req)

    def test_health_and_synthetic_dataset(self):
        with self.request('/health') as res:
            self.assertEqual(json.load(res), {'health': 'ok'})
        with self.request('/api/jobs') as res:
            self.assertEqual(len(json.load(res)['jobs']), 3)

    def test_authorized_write_and_html_escaping(self):
        with self.request('/api/jobs', {'customer': '<script>', 'issue': 'Test', 'status': 'Ready'}, True) as res:
            self.assertEqual(res.status, 201)
        with self.request('/') as res:
            page = res.read().decode()
            self.assertIn('&lt;script&gt;', page)
            self.assertNotIn('<script>', page)

    def test_unauthorized_write(self):
        with self.assertRaises(urllib.error.HTTPError) as ctx:
            self.request('/api/jobs', {'customer': 'X', 'issue': 'X', 'status': 'Ready'})
        self.assertEqual(ctx.exception.code, 401)

    def test_invalid_payload(self):
        for data in ([], {'customer': 'X', 'issue': 'X', 'status': 'Unknown'}, {'customer': '', 'issue': 'X', 'status': 'Ready'}):
            with self.assertRaises(urllib.error.HTTPError) as ctx:
                self.request('/api/jobs', data, True)
            self.assertEqual(ctx.exception.code, 400)

    def test_persistence_and_integrity(self):
        with self.request('/api/jobs', {'customer': 'C-104', 'issue': 'Persistence check', 'status': 'Ready'}, True):
            pass
        app.initialize(self.db)
        with sqlite3.connect(self.db) as conn:
            self.assertEqual(conn.execute('SELECT COUNT(*) FROM jobs').fetchone()[0], 4)
            self.assertEqual(conn.execute('PRAGMA integrity_check').fetchone()[0], 'ok')

    def test_short_token_rejected(self):
        with self.assertRaises(ValueError):
            app.make_server(self.db, '', 0)
