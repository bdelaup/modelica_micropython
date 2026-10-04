# Client DAP minimal qui joue le role de VS Code pour les scenarios n°60 et
# n°62 : il s'attache au debugpy d'un MCU, pose un point d'arret, lit une
# variable, puis se detache. Avec "steps" (n°60), il fait aussi un pas
# par-dessus, un pas entrant, laisse le programme quelques secondes en pause
# et reprend jusqu'au passage suivant. Avec "stay" (n°62), il reprend sans se
# detacher et reste connecte jusqu'a la fin de la simulation, comme VS Code
# qu'on laisse ouvert. Compte rendu dans un fichier JSON lu par le .mos.
#
#   python dap_client.py <port> <programme.py> <ligne> <variable> <compte_rendu.json> [steps|stay]
#
# Lance en arriere-plan AVANT la simulation : il retente la connexion jusqu'a
# ce que le MCU ecoute (construction du modele).
import json, os, socket, sys, time

port, line, variable, report_path = int(sys.argv[1]), int(sys.argv[3]), sys.argv[4], sys.argv[5]
program = os.path.abspath(sys.argv[2])      # chemin absolu normalise, comme VS Code
mode = sys.argv[6] if len(sys.argv) > 6 else ''
report = {'connected': False}


def save():
    # Ecrit puis renomme : le .mos ne lit jamais un compte rendu a moitie ecrit.
    with open(report_path + '.tmp', 'w') as f:
        json.dump(report, f, indent=1)
    os.replace(report_path + '.tmp', report_path)


class Dap:
    def __init__(self, sock):
        self.sock = sock
        self.buf = b''
        self.seq = 0
        self.events = []
        self.responses = {}

    def send(self, command, **arguments):
        self.seq += 1
        body = json.dumps({'seq': self.seq, 'type': 'request', 'command': command,
                           'arguments': arguments}).encode()
        self.sock.sendall(b'Content-Length: %d\r\n\r\n' % len(body) + body)
        return self.seq

    def read(self):
        while b'\r\n\r\n' not in self.buf:
            self._fill()
        head, self.buf = self.buf.split(b'\r\n\r\n', 1)
        length = int(head.split(b':')[1])
        while len(self.buf) < length:
            self._fill()
        body, self.buf = self.buf[:length], self.buf[length:]
        return json.loads(body)

    def _fill(self):
        data = self.sock.recv(65536)
        if not data:
            raise EOFError
        self.buf += data

    def response(self, seq):
        while seq not in self.responses:
            self.keep(self.read())
        msg = self.responses.pop(seq)
        if not msg['success']:
            raise RuntimeError('%s: %s' % (msg['command'], msg.get('message')))
        return msg.get('body', {})

    def keep(self, msg):
        # Reponses et evenements arrivent dans n'importe quel ordre (la reponse
        # a attach precede l'evenement initialized) : rien n'est jete.
        if msg['type'] == 'response':
            self.responses[msg['request_seq']] = msg
        elif msg['type'] == 'event':
            self.events.append(msg)

    def request(self, command, **arguments):
        return self.response(self.send(command, **arguments))

    def event(self, name):
        for i, msg in enumerate(self.events):
            if msg['event'] == name:
                return self.events.pop(i)
        while True:
            msg = self.read()
            if msg['type'] == 'event' and msg['event'] == name:
                return msg
            self.keep(msg)


def top_frame(dap, thread_id):
    frames = dap.request('stackTrace', threadId=thread_id, startFrame=0, levels=1)['stackFrames']
    return frames[0]


def local(dap, frame_id, name):
    for scope in dap.request('scopes', frameId=frame_id)['scopes']:
        for var in dap.request('variables', variablesReference=scope['variablesReference'])['variables']:
            if var['name'] == name:
                return var['value']
    return None


def run_steps(dap, thread_id):
    # Un pas par-dessus, puis un pas entrant sur led.toggle() : il doit
    # rester dans le programme, le shim etant exclu du pas a pas.
    dap.request('next', threadId=thread_id)
    dap.event('stopped')
    frame = top_frame(dap, thread_id)
    report['line_after_next'] = frame['line']
    report['value_after_next'] = local(dap, frame['id'], variable)
    dap.request('stepIn', threadId=thread_id)
    dap.event('stopped')
    frame = top_frame(dap, thread_id)
    report['line_after_step_in'] = frame['line']
    report['file_after_step_in'] = frame['source'].get('path')

    # Evaluation qui accede a une broche pendant la pause (panneau Espion) :
    # elle fait un vrai tour de synchro, sans bloquer ni le programme ni la
    # simulation.
    result = dap.request('evaluate', expression='led.value()', frameId=frame['id'], context='watch')
    report['evaluate_led'] = result.get('result')

    # Programme en pause : la simulation doit attendre, temps simule fige.
    time.sleep(2)

    # Second passage dans la boucle : le point d'arret est toujours la.
    dap.request('continue', threadId=thread_id)
    dap.event('stopped')
    frame = top_frame(dap, thread_id)
    report['value_second_break'] = local(dap, frame['id'], variable)


try:
    deadline = time.time() + 120
    while True:
        try:
            sock = socket.create_connection(('127.0.0.1', port), timeout=2)
            break
        except OSError:
            if time.time() > deadline:
                raise
            time.sleep(0.2)
    sock.settimeout(60)
    report['connected'] = True
    dap = Dap(sock)
    dap.request('initialize', adapterID='python', clientID='dap_client', linesStartAt1=True,
                columnsStartAt1=True, pathFormat='path')
    # pathMappings du modele "Remote Attach" de VS Code, tel qu'un eleve le
    # garde dans son launch.json : dossier de travail (ici Resources, parent
    # du programme et distinct du dossier de la simulation) -> "." (que pydevd
    # remplace par le dossier courant de la simulation). Le MCU doit l'ignorer,
    # sinon les points d'arret ne sont jamais atteints (defaut constate le
    # 2026-10-04 avec le vrai VS Code, simulation lancee par OMEdit).
    workspace = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    attach_seq = dap.send('attach', justMyCode=True,
                          pathMappings=[{'localRoot': workspace, 'remoteRoot': '.'}])
    dap.event('initialized')
    bp = dap.request('setBreakpoints', source={'path': program}, breakpoints=[{'line': line}])
    report['breakpoint_verified'] = bp['breakpoints'][0].get('verified')
    dap.request('configurationDone')
    dap.response(attach_seq)

    stopped = dap.event('stopped')
    thread_id = stopped['body']['threadId']
    frame = top_frame(dap, thread_id)
    report['stop_reason'] = stopped['body'].get('reason')
    report['stop_line'] = frame['line']
    report['stop_file'] = frame['source'].get('path')
    report['value_at_break'] = local(dap, frame['id'], variable)

    if mode == 'steps':
        run_steps(dap, thread_id)

    dap.request('setBreakpoints', source={'path': program}, breakpoints=[])
    if mode == 'stay':
        # On reprend sans se detacher : la simulation se termine VS Code
        # attache. Compte rendu ecrit avant, la fin pouvant etre immediate.
        dap.request('continue', threadId=thread_id)
        report['resumed'] = True
        save()
        try:
            dap.event('terminated')
            report['terminated_event'] = True
        except (EOFError, OSError):
            report['connection_closed'] = True
        save()
    else:
        # On se detache : le programme finit seul. Compte rendu ecrit AVANT le
        # detachement : la simulation se termine aussitot apres, et le .mos le
        # lit des qu'elle est finie.
        report['detached'] = True
        save()
        dap.request('disconnect', terminateDebuggee=False)
except Exception as e:
    report['error'] = '%s: %s' % (type(e).__name__, e)
    save()
