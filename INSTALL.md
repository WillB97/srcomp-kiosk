# SRComp Kiosk Installation

## Choosing an image

If the Raspberry Pi already have a desktop environment set up and it doesn't
need to be re-imaged, then you can skip this section and jump straight to
"SRComp Kiosk setup".

The kiosk runs on top of Raspberry Pi OS (a derivative of Debian). Several SD
card images are available, with varying levels of software already installed on
each. You'll need to choose a version which is suitable for the Pis and SD cards
you have available.

Student Robotics' Pis are 1As and have 4GB SD cards, so currently (early 2022)
the most convenient option is the "Raspberry Pi OS with desktop" which is 1.3GB
and contains a basic desktop environment (but no additional software).

## Bootstrap

There are a few ways to get the SRComp Kiosk bootstrap files (i.e: this repo)
onto the Pi:

* by modifying a fresh Raspberry Pi OS image to include it, or
* by copying it onto SD card after it has been written, or
* by copying it onto the Pi after the image has been booted

If preparing more than one Pi at a time the first of these is the suggested path
as it reduces the manual effort needed.

If you're running linux you can modify an image to include the necessary files
by running a script included in this repo:

``` shell
./scripts/from-clean-image $IMAGE
```

This will modify the image (in place) to include this repo and enable SSH for
easier deployment.

The equivalent steps are likely possible manually on other host operating
systems, however this has not been tested.

## Writing the image

The SD cards can either be imaged using the Raspberry Pi Imager or the images
downloaded and copied onto the SD card manually. Raspberry Pi Documentation's
[getting started guide][getting-started-guide] explains how to write the image
to the SD card.

Raspberry Pi OS has SSH disabled by default, which will be needed when the Pis
are deployed and will likely make setup of the image easier too. If you ran the
provided `from-clean-image` script to prepare the image then this change has
already been made for you. Otherwise, to enable it you can mount the `boot`
partition on a freshly written SD card image and then `touch /path/to/boot/ssh`.

[getting-started-guide]: https://www.raspberrypi.com/documentation/computers/getting-started.html

## Bootstrap (alternative)

To get the SRComp Kiosk bootstrap files (i.e: this repo) onto a Pi which has not
had it added to the image, enter the following at a terminal running on the
Raspberry Pi:

``` shell
# Install Git:
sudo apt install --yes git

# Clone this repo:
git clone --recursive https://github.com/PeterJCLaw/srcomp-kiosk
```

## SRComp Kiosk setup

To deploy SRComp Kiosk on a running Pi, enter the following at a terminal
running on the Raspberry Pi:

``` shell
cd srcomp-kiosk
sudo ./scripts/install
```

This may print the following message, either if SRComp Kiosk has been deployed
on the Pi before or if the Puppet install has created some files there.

``` text
Puppet dir (/etc/puppet) already exists, remove it? [y/N]:
```

Unless you're aware of anything particular you need in that folder, removal is
safe to proceed with (SRComp Kiosk will replace the files with its own) by
entering "y".

If the Puppet config is later modified, the changes can be deployed by running
the following command:

``` shell
cd srcomp-kiosk
sudo ./scripts/update
```
