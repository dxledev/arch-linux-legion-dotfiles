Speed-test panels, gauges, and benchmark scripts adapted from Omarchy commit
31bd80daa4613ffdee995ac27467fce5a2990806 (MIT; see LICENSE.omarchy).

Source: https://github.com/omacom/omarchy/tree/31bd80daa4613ffdee995ac27467fce5a2990806

The port uses the local theme/font, launcher and nmcli connection names. Network
workers handle TERM and stop when their parent exits. Disk scratch files live in
${XDG_CACHE_HOME:-$HOME/.cache}/quickshell; an optional directory argument selects
a different filesystem. Scripts accept --help and --dry-run without starting I/O.

Network measures download then upload for five seconds each using fast.com and
interface counters. Disk uses four 256MB direct-I/O files, eight seconds per phase,
and reports a steady-state mean excluding the first second. Closing stops workers
and removes only the benchmark's own scratch files.
