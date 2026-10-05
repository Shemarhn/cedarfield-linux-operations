"""Synthetic service-job register. Standard-library workload for the operations lab."""
import hmac
import html
import json
import logging
import os
import sqlite3
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


def connect(path):
    conn = sqlite3.connect(path)
    conn.execute('PRAGMA journal_mode=WAL')
    return conn


def initialize(path):
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    with connect(path) as conn:
        conn.execute('CREATE TABLE IF NOT EXISTS jobs (id INTEGER PRIMARY KEY, customer TEXT NOT NULL, issue TEXT NOT NULL, status TEXT NOT NULL)')
        if conn.execute('SELECT COUNT(*) FROM jobs').fetchone()[0] == 0:
            conn.executemany('INSERT INTO jobs(customer,issue,status) VALUES(?,?,?)', [
                ('C-101', 'Printer maintenance', 'Received'),
                ('C-102', 'Workstation setup', 'In progress'),
                ('C-103', 'Laptop service', 'Ready'),
            ])


def make_server(db_path, token, port=8090):
    if len(token) < 24:
        raise ValueError('APP_TOKEN must contain at least 24 characters')
    initialize(db_path)

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, fmt, *args):
            # Exclude Authorization, query parameters, addresses and request bodies.
            logging.info('request method=%s route=%s', self.command, self.path.split('?')[0])

        def reply(self, status, data, content_type='application/json'):
            body = data.encode() if isinstance(data, str) else json.dumps(data).encode()
            self.send_response(status)
            self.send_header('Content-Type', content_type + '; charset=utf-8')
            self.send_header('Content-Length', str(len(body)))
            self.send_header('X-Content-Type-Options', 'nosniff')
            self.send_header('Cache-Control', 'no-store')
            self.send_header('Content-Security-Policy', "default-src 'none'; style-src 'unsafe-inline'; frame-ancestors 'none'")
            self.end_headers()
            self.wfile.write(body)

        def do_GET(self):
            try:
                with connect(db_path) as conn:
                    if self.path == '/health':
                        conn.execute('SELECT 1 FROM jobs LIMIT 1').fetchone()
                        return self.reply(200, {'health': 'ok'})
                    rows = conn.execute('SELECT id,customer,issue,status FROM jobs ORDER BY id').fetchall()
                if self.path == '/api/jobs':
                    return self.reply(200, {'jobs': [dict(zip(('id', 'customer', 'issue', 'status'), row)) for row in rows]})
                if self.path == '/':
                    items = ''.join('<tr>' + ''.join('<td>' + html.escape(str(v)) + '</td>' for v in row) + '</tr>' for row in rows)
                    page = '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Cedarfield service register</title><style>body{font:18px/1.6 system-ui;margin:48px;color:#16323c;background:#f6f8f5}h1{font-size:42px}table{border-collapse:collapse;width:100%;background:white}th,td{text-align:left;padding:16px;border-bottom:1px solid #c9d6d7}small{color:#086d70}</style><small>SYNTHETIC OPERATIONS LAB</small><h1>Cedarfield Service Register</h1><p>Service jobs for a fictional local business. Access through an administrator SSH tunnel.</p><table><caption>Persistent synthetic job records</caption><thead><tr><th>ID</th><th>Customer alias</th><th>Issue</th><th>Status</th></tr></thead><tbody>' + items + '</tbody></table><p>Application health available at /health. All customer data is synthetic.</p></html>'
                    return self.reply(200, page, 'text/html')
                return self.reply(404, {'error': 'not found'})
            except sqlite3.Error:
                logging.exception('database operation failed')
                self.reply(503, {'health': 'unavailable'})

        def do_POST(self):
            if self.path != '/api/jobs':
                return self.reply(404, {'error': 'not found'})
            if not hmac.compare_digest(self.headers.get('Authorization', ''), 'Bearer ' + token):
                return self.reply(401, {'error': 'unauthorized'})
            try:
                length = int(self.headers.get('Content-Length', '0'))
                if not 1 <= length <= 4096:
                    raise ValueError()
                data = json.loads(self.rfile.read(length))
                if not isinstance(data, dict):
                    raise ValueError()
                values = tuple(data.get(k) for k in ('customer', 'issue', 'status'))
                if any(not isinstance(v, str) or not v.strip() or len(v) > 200 for v in values):
                    raise ValueError()
                if values[2] not in ('Received', 'In progress', 'Ready'):
                    raise ValueError()
                with connect(db_path) as conn:
                    job_id = conn.execute('INSERT INTO jobs(customer,issue,status) VALUES(?,?,?)', values).lastrowid
                self.reply(201, {'id': job_id})
            except (ValueError, TypeError, json.JSONDecodeError):
                self.reply(400, {'error': 'invalid job'})
            except sqlite3.Error:
                self.reply(503, {'error': 'database unavailable'})

    return ThreadingHTTPServer(('127.0.0.1', port), Handler)


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO, format='%(levelname)s %(message)s')
    server = make_server(os.environ.get('APP_DB', '/var/lib/cedarfield/jobs.sqlite'), os.environ['APP_TOKEN'])
    logging.info('service started')
    server.serve_forever()
