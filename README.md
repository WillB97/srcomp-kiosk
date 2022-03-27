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

## Configuration

The puppet configuration uses the MAC addresses of the target devices to
identify physically which device it is being run on and what properties to set.

In preparation for a new deployment the `pi_macs` file should be edited to
reflect the expected deployment and `macs-to-names.py` run to update the `hiera`
configuration for puppet and the `pi-names` file.

## Deployment

See [INSTALL.md](INSTALL.md) for installation and deployment instructions.

## Operations

Scripts are provided in the root of the repo which use the `pi-names` file to
check on the status of the deployed Pis or run commands on them. These all
assume that you have suitable DNS entries available (either through real DNS or
by editing your local `/etc/hosts` file) so that SSH connections to the Pis can
use their names.
