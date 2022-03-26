# SRComp Kiosk

This is a kiosk type system intended for use at the Student Robotics Competition.

It is a puppet config wrapping a launcher script.

The launcher script is `kiosk.py` and is installed behind a wrapper as
`srcomp-kiosk` which presents an interface similar to a service -- it
has `start`, `stop`, `status` etc.

The output streams from `kiosk.py` ends up in `/var/log/srcomp-kisok`
as two log files, `stdout.log` and `stderr.log`.

If running `srcomp-kiosk` manually be sure that the `DISPLAY` environment
variable is properly set (you probably want `:0.0`).

The puppet config will launch the kiosk if it is not already running,
and it will also automatically start on boot via a `.desktop` file.

## Deployment

See [INSTALL.md](INSTALL.md) for installation and deployment instructions.
