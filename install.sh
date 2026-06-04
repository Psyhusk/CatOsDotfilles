#!/bin/bash

set -e

REPO_URL="https://github.com/Psyhusk/CatDotsOS.git"
TMP_DIR="/tmp/catdots"
PKGBUILD_URL="https://raw.githubusercontent.com/Psyhusk/CatDotsOS/main/packaging/archlinux/PKGBUILD"
PKG_AUR_DEPS=(
	nautilus
  	nautilus-code
  	nautilus-copy-path
  	nautilus-hide
	matugen-bin
	python-inquirerpy
	qt6ct-kde
	qt5ct-kde
	hyprshade
	bibata-cursor-theme-bin
	aur-check-updates
	waypaper
	wlogout
	neofetch
)

fail() {
	echo "✘ $1"
	exit 1
}

info() {
	echo "> $1"
}

success() {
	echo "✔ $1"
}

is_installed() {
	pacman -Q "$1" &>/dev/null
}

install_system_deps() {
	info "Checking system dependencies..."

	local deps=(git base-devel)

	for dep in "${deps[@]}"; do
		if ! is_installed "$dep"; then
			info "Installing $dep..."
			sudo pacman -S --needed --noconfirm "$dep" || fail "Failed to install $dep"
		fi
	done

	success "System dependencies ready"
}

install_yay() {
	if command -v yay &>/dev/null; then
		info "yay already installed"
		return 0
	fi

	info "Installing yay (AUR helper)..."

	rm -rf /tmp/yay

	git clone https://aur.archlinux.org/yay.git /tmp/yay || fail "Failed to clone yay"

	cd /tmp/yay || fail "Cannot enter yay directory"

	makepkg -si --noconfirm || fail "Failed to build/install yay"

	cd - >/dev/null || true
	rm -rf /tmp/yay

	success "yay installed"
}

install_aur_deps() {
	info "Installing AUR packages"
	for pkg in "${PKG_AUR_DEPS[@]}"; do
		if ! pacman -Qi "$pkg" &>/dev/null; then
			echo "Installing AUR dependency: $pkg"
			yay -S --noconfirm "$pkg" || fail "Failed to install aur pkg: $pkg"
		fi
	done
	success "aur deps installed"
}

download_pkgbuild() {
	info "Downloading PKGBUILD from https://github.com/Psyhusk/CatDotsOS ..."

	mkdir -p "$TMP_DIR"

	curl -fLo "$TMP_DIR/PKGBUILD" "$PKGBUILD_URL" \
		|| fail "Failed to download PKGBUILD"

	success "Package files downloaded"
}

build() {
	info "Building CatOsDotfilles package..."

	cd "$TMP_DIR" || fail "Temp dir missing"

	makepkg -si --noconfirm || fail "makepkg failed"

	success "CatOsDotfilles installed via pacman"
}

run_setup() {
	info "Running post-install setup..."

	if command -v catdots &>/dev/null; then
		catdots init || fail "catdots init failed"
	else
		fail "catdots command not found after install"
	fi

	success "Setup completed"
}

main() {
	install_system_deps
	install_yay
	install_aur_deps
	download_pkgbuild
	build
	run_setup

	echo
	success "CatOsDotfilles installation complete! Enjoy your setup 🐱"
}

main
