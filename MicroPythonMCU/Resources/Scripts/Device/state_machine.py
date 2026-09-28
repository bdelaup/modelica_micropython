# ---------------------------------------------------------------------------
# State-machine peripheral script (Examples.Uart.StateMachinePy).
#
# The device only accepts a read if it has been started, and counts the
# reads served. This is precisely what the command table cannot do: a
# table maps a command to a reply, without memory. Here, the reply
# to READ depends on what happened BEFORE.
#
#   START -> OK             (ERR if already started)
#   READ  -> VAL=<v1> N=<n> if started, ERR otherwise
#   STOP  -> OK
#   other -> ERR
#
# The state lives in module variables: the script is run only once,
# when the component is built, and these variables persist from one call
# to the next. Each received line is delivered only once to on_receive, even if
# the simulation evaluates the same instant several times: a transition is
# therefore never replayed.
# ---------------------------------------------------------------------------

state = 'STOPPED'
reads = 0


def on_receive(line, t, v):
    global state, reads
    if line == b'START':
        if state == 'RUNNING':
            return b'ERR already started\r\n'
        state = 'RUNNING'
        print('started at t =', round(t, 4))
        return b'OK\r\n'
    if line == b'STOP':
        state = 'STOPPED'
        return b'OK\r\n'
    if line == b'READ':
        if state != 'RUNNING':
            return b'ERR stopped\r\n'
        reads += 1
        return 'VAL=%.2f N=%d\r\n' % (v[0], reads)
    return b'ERR command\r\n'


def outputs():
    # valueOut[1]: state (1 = running), valueOut[2]: reads served
    return (1.0 if state == 'RUNNING' else 0.0, reads)
