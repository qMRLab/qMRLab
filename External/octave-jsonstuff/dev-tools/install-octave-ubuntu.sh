#!/bin/bash
#
# This installs Octave on Ubuntu, doing what's necessary to get a newer 4.2+
# Octave even if this distro's default is an older version.
#
# This should work on Trusty, Xenial, and Bionic.

function install_octave_4_2_from_apt () {
	if grep -i 'xenial\|trusty' /etc/lsb-release &>/dev/null; then
		echo $0: Adding apt repository ppa:octave/stable to get newer Octave 4.2
		sudo add-apt-repository ppa:octave/stable --yes
		sudo apt-get update
	fi
	pkgs="octave liboctave-dev"
	echo $0: Installing packages: $pkgs
	sudo apt-get install --yes $pkgs
}

function install_octave_4_4_from_flatpak () {
	echo $0: installing flatpak
	if grep -i 'xenial\|trusty' /etc/lsb-release &>/dev/null; then
		echo $0: Adding apt repository ppa:alexlarsson/flatpak to get Flatpak
		sudo add-apt-repository ppa:alexlarsson/flatpak --yes
		sudo apt-get update
	fi
	sudo apt-get install --yes flatpak

	flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
	flatpak install --user -y flathub org.octave.Octave
}

case $OCTAVE_VER in
	4.2)
		install_octave_4_2_from_apt
		;;
	4.4)
		install_octave_4_4_from_flatpak
		;;
	*)
		echo >&2 $0: error: do not know how to install Octave version '$OCTAVE_VERSION'
		;;
esac
