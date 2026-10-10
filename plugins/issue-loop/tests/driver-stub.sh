#!/bin/bash
# A driver for the tests: no terminal, only files under $STUB.
#   $STUB/sent     every drv_send, one line "name<TAB>first line of text"
#   $STUB/last     the whole text of the last drv_send
#   $STUB/screen   what drv_read prints
#   $STUB/status   what drv_status prints (missing file: gone)
drv_send() {
  printf '%s\t%s\n' "$1" "$(head -1 <<<"$2")" >>"$STUB/sent"
  printf '%s\n' "$2" >"$STUB/last"
  [ -f "$STUB/die_on_send" ] && echo gone >"$STUB/status"
  true
}
drv_status() { cat "$STUB/status" 2>/dev/null || echo gone; }
drv_wait() { true; }
drv_read() { tail -n "$2" "$STUB/screen" 2>/dev/null; }
drv_start() { cat "$STUB/start_status" 2>/dev/null >"$STUB/status" || echo working >"$STUB/status"; echo "stub:p1"; }
