#!/usr/bin/env bash

set -e

# ----------------------------------------------------
# 0. Detect Project Root (whether run from root or packaging/)
# ----------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/pubspec.yaml" ]; then
    PROJECT_ROOT="$SCRIPT_DIR"
elif [ -f "$SCRIPT_DIR/../pubspec.yaml" ]; then
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
elif [ -f "$(pwd)/pubspec.yaml" ]; then
    PROJECT_ROOT="$(pwd)"
else
    PROJECT_ROOT="$(pwd)"
fi
cd "$PROJECT_ROOT"

# Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}     Universal Flutter Linux Packaging Script       ${NC}"
echo -e "${BLUE}====================================================${NC}"

# ----------------------------------------------------
# Package Manager Detection & Dependency Helper
# ----------------------------------------------------
detect_pkg_manager() {
    if command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v zypper &> /dev/null; then
        echo "zypper"
    elif command -v apt-get &> /dev/null; then
        echo "apt"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

install_system_deps() {
    local pm=$(detect_pkg_manager)
    echo -e "${BLUE}==> Detected system package manager:${NC} ${BOLD}$pm${NC}"
    case "$pm" in
        dnf)
            echo -e "${CYAN}Installing build and packaging dependencies via DNF (Fedora / RHEL 8+ / Rocky / Alma)...${NC}"
            sudo dnf install -y \
                clang cmake ninja-build pkgconf-pkg-config \
                gtk3-devel libappindicator-gtk3-devel libdbusmenu-gtk3-devel \
                rpm-build rpmdevtools zstd binutils tar curl
            ;;
        yum)
            echo -e "${CYAN}Installing build and packaging dependencies via YUM (RHEL / CentOS / Amazon Linux)...${NC}"
            sudo yum install -y \
                clang cmake3 ninja-build pkgconfig \
                gtk3-devel libappindicator-gtk3-devel libdbusmenu-gtk3-devel \
                rpm-build rpmdevtools zstd binutils tar curl
            ;;
        zypper)
            echo -e "${CYAN}Installing build and packaging dependencies via ZYPPER (openSUSE / SLES)...${NC}"
            sudo zypper install -y \
                clang cmake ninja pkg-config \
                gtk3-devel libayatana-appindicator3-devel libdbusmenu-gtk3-devel \
                rpm-build update-desktop-files zstd binutils tar curl
            ;;
        apt)
            echo -e "${CYAN}Installing build and packaging dependencies via APT (Debian / Ubuntu / Mint)...${NC}"
            sudo apt-get update && sudo apt-get install -y \
                clang cmake ninja-build pkg-config \
                libgtk-3-dev libappindicator3-dev libdbusmenu-gtk3-dev \
                dpkg-dev rpm zstd binutils tar curl
            ;;
        pacman)
            echo -e "${CYAN}Installing build and packaging dependencies via PACMAN (Arch Linux / Manjaro)...${NC}"
            sudo pacman -S --needed --noconfirm \
                clang cmake ninja pkgconf \
                gtk3 libappindicator-gtk3 libdbusmenu-gtk3 \
                rpm-tools zstd binutils base-devel curl
            ;;
        *)
            echo -e "${RED}Error: Could not identify package manager (dnf, yum, zypper, apt, pacman).${NC}"
            echo -e "${YELLOW}Please install clang, cmake, ninja, gtk3-devel, rpm-build, and zstd manually.${NC}"
            exit 1
            ;;
    esac
    echo -e "${GREEN}✓ Dependencies installation complete.${NC}\n"
}

show_help() {
    echo -e "${BOLD}Usage:${NC} ./build_linux.sh [OPTIONS]"
    echo ""
    echo -e "${BOLD}Options:${NC}"
    echo "  --help, -h          Show this help message"
    echo "  --install-deps, -i  Install required build & packaging tools using system package manager (dnf, yum, zypper, apt, pacman)"
    echo "  --tar, --tar-gz     Build Portable Linux tar.gz archive only (.tar.gz)"
    echo "  --deb               Build Debian/Ubuntu package only (.deb)"
    echo "  --rpm               Build RPM package for DNF, YUM & Zypper only (.rpm)"
    echo "  --arch              Build Arch Linux package only (.pkg.tar.zst)"
    echo "  --appimage          Build Universal AppImage only (.AppImage)"
    echo "  --flatpak           Build Flatpak bundle only (.flatpak)"
    echo ""
    echo -e "${BOLD}Supported Package Managers & Distros:${NC}"
    echo "  • DNF     : Fedora, RHEL 8+, Rocky Linux, AlmaLinux"
    echo "  • YUM     : RHEL 7, CentOS 7, Amazon Linux"
    echo "  • ZYPPER  : openSUSE Leap, openSUSE Tumbleweed, SUSE Linux Enterprise"
    echo "  • APT     : Debian, Ubuntu, Linux Mint, Pop!_OS"
    echo "  • PACMAN  : Arch Linux, Manjaro, EndeavourOS"
    echo ""
    exit 0
}

# Parse CLI arguments
BUILD_TAR=false
BUILD_DEB=false
BUILD_RPM=false
BUILD_ARCH=false
BUILD_APPIMAGE=false
BUILD_FLATPAK=false
SPECIFIC_TARGET=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --install-deps|-i|--deps)
            install_system_deps
            shift
            ;;
        --help|-h)
            show_help
            ;;
        --tar|--tar-gz|-t)
            BUILD_TAR=true
            SPECIFIC_TARGET=true
            shift
            ;;
        --deb)
            BUILD_DEB=true
            SPECIFIC_TARGET=true
            shift
            ;;
        --rpm)
            BUILD_RPM=true
            SPECIFIC_TARGET=true
            shift
            ;;
        --arch)
            BUILD_ARCH=true
            SPECIFIC_TARGET=true
            shift
            ;;
        --appimage)
            BUILD_APPIMAGE=true
            SPECIFIC_TARGET=true
            shift
            ;;
        --flatpak)
            BUILD_FLATPAK=true
            SPECIFIC_TARGET=true
            shift
            ;;
        *)
            echo -e "${YELLOW}Unknown option: $1${NC}"
            show_help
            ;;
    esac
done

# If no specific target requested, build all formats
if [ "$SPECIFIC_TARGET" = false ]; then
    BUILD_TAR=true
    BUILD_DEB=true
    BUILD_RPM=true
    BUILD_ARCH=true
    BUILD_APPIMAGE=true
    BUILD_FLATPAK=true
fi

# 1. Parse pubspec.yaml for Name and Version
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}Error: pubspec.yaml not found in project root ($PROJECT_ROOT).${NC}"
    exit 1
fi

APP_NAME=$(grep '^name:' pubspec.yaml | head -n 1 | awk '{print $2}' | tr -d '"' | tr -d "'")
FULL_VERSION=$(grep '^version:' pubspec.yaml | head -n 1 | awk '{print $2}' | tr -d '"' | tr -d "'")
VERSION=$(echo "$FULL_VERSION" | cut -d'+' -f1)
DESCRIPTION=$(grep '^description:' pubspec.yaml | head -n 1 | cut -d':' -f2- | sed 's/^[ \t]*//' | tr -d '"' | tr -d "'")

if [ -z "$APP_NAME" ]; then APP_NAME="$(basename "$PROJECT_ROOT")"; fi
if [ -z "$VERSION" ]; then VERSION="1.0.0"; fi
if [ -z "$DESCRIPTION" ]; then DESCRIPTION="Flutter Linux Application"; fi
APPLICATION_ID="com.h.aazil"

echo -e "${GREEN}Project Root:${NC} $PROJECT_ROOT"
echo -e "${GREEN}App Name:${NC}     $APP_NAME"
echo -e "${GREEN}Version:${NC}      $VERSION"
echo -e "${GREEN}App ID:${NC}       $APPLICATION_ID"
echo -e "${GREEN}Summary:${NC}      $DESCRIPTION"
echo ""

# 1.5 Pre-generate and refresh all application icon resolutions
if [ -f "./generate_icons.sh" ]; then
    echo -e "${BLUE}==> Pre-building and synchronizing all application icon resolutions...${NC}"
    ./generate_icons.sh || true
fi

# Synchronize Flatpak icon asset if flatpak/ directory exists
# Force-remove old exports to ensure clean regeneration
if [ -d "flatpak" ]; then
    rm -f "flatpak/com.h.aazil.png" "flatpak/aazil.png" 2>/dev/null || true
    if [ -f "assets/icon/export_512x512.png" ]; then
        cp "assets/icon/export_512x512.png" "flatpak/com.h.aazil.png" 2>/dev/null || true
        cp "assets/icon/export_512x512.png" "flatpak/aazil.png" 2>/dev/null || true
    fi
fi

# 2. Check Flutter Installation & Build Linux Release
BUNDLE_DIR="build/linux/x64/release/bundle"

# If flutter is not in current PATH (e.g. running under sudo), search common user locations
if ! command -v flutter &> /dev/null; then
    if [ -n "$SUDO_USER" ] && [ -x "/home/$SUDO_USER/flutter/bin/flutter" ]; then
        export PATH="/home/$SUDO_USER/flutter/bin:$PATH"
    elif [ -x "$HOME/flutter/bin/flutter" ]; then
        export PATH="$HOME/flutter/bin:$PATH"
    elif [ -x "/opt/flutter/bin/flutter" ]; then
        export PATH="/opt/flutter/bin:$PATH"
    fi
fi

if command -v flutter &> /dev/null; then
    echo -e "${BLUE}==> Building Flutter Linux Release...${NC}"
    flutter build linux
elif [ -d "$BUNDLE_DIR" ]; then
    echo -e "${YELLOW}Notice: 'flutter' command not found in PATH, but existing build bundle found at $BUNDLE_DIR. Reusing existing bundle...${NC}"
else
    echo -e "${RED}Error: 'flutter' command not found in PATH and no previous build exists.${NC}"
    echo -e "${YELLOW}Please make sure flutter is in your PATH or build the app once as a normal user.${NC}"
    exit 1
fi

if [ ! -d "$BUNDLE_DIR" ]; then
    echo -e "${RED}Error: Build failed. Bundle directory $BUNDLE_DIR does not exist.${NC}"
    exit 1
fi

# 3. Create dist/ directory
DIST_DIR="$(pwd)/dist"
mkdir -p "$DIST_DIR"

BUILD_TMP="/tmp/${APP_NAME}_packager"
rm -rf "$BUILD_TMP"
mkdir -p "$BUILD_TMP"

# Dynamic icon detection
ICON_SRC=""
if [ -f "assets/icon/export_512x512.png" ]; then
    ICON_SRC="assets/icon/export_512x512.png"
elif [ -f "assets/icon/app_icon.png" ]; then
    ICON_SRC="assets/icon/app_icon.png"
elif [ -f "assets/images/aazil_logo.png" ]; then
    ICON_SRC="assets/images/aazil_logo.png"
elif [ -f "assets/icons/export_512x512.png" ]; then
    ICON_SRC="assets/icons/export_512x512.png"
elif [ -f "linux/flutter/icon.png" ]; then
    ICON_SRC="linux/flutter/icon.png"
fi

# ----------------------------------------------------
# A. DEBIAN / UBUNTU (.deb) [APT / dpkg]
# ----------------------------------------------------
if [ "$BUILD_DEB" = true ]; then
    echo -e "\n${BLUE}==> Packaging Debian / Ubuntu (.deb for APT)...${NC}"
    DEB_NAME="${APP_NAME}_${VERSION}_amd64.deb"
    DEB_DIR="$BUILD_TMP/deb_stage"
    rm -rf "$DEB_DIR"
    mkdir -p "$DEB_DIR/DEBIAN"
    mkdir -p "$DEB_DIR/usr/lib/$APP_NAME"
    mkdir -p "$DEB_DIR/usr/bin"
    mkdir -p "$DEB_DIR/usr/share/applications"
    mkdir -p "$DEB_DIR/usr/share/icons/hicolor/512x512/apps"

    # Copy Bundle
    cp -r "$BUNDLE_DIR"/* "$DEB_DIR/usr/lib/$APP_NAME/"

    # Launcher wrapper script
    cat << EOF > "$DEB_DIR/usr/bin/$APP_NAME"
#!/bin/sh
exec /usr/lib/$APP_NAME/$APP_NAME "\$@"
EOF
    chmod +x "$DEB_DIR/usr/bin/$APP_NAME"

    # Desktop entry
    cat << EOF > "$DEB_DIR/usr/share/applications/$APPLICATION_ID.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=Aazil
GenericName=Sandboxed Media Viewer
Comment=Sandboxed Media Viewer (عازل)
Exec=$APP_NAME %U
Icon=$APPLICATION_ID
Terminal=false
StartupNotify=true
StartupWMClass=$APPLICATION_ID
Categories=AudioVideo;Graphics;Utility;
EOF
    cp "$DEB_DIR/usr/share/applications/$APPLICATION_ID.desktop" "$DEB_DIR/usr/share/applications/$APP_NAME.desktop"

    # Install icons for all resolutions
    for res in 16x16 20x20 24x24 32x32 48x48 64x64 128x128 256x256 512x512 1024x1024; do
        if [ -f "assets/icon/export_${res}.png" ]; then
            mkdir -p "$DEB_DIR/usr/share/icons/hicolor/$res/apps"
            cp "assets/icon/export_${res}.png" "$DEB_DIR/usr/share/icons/hicolor/$res/apps/$APP_NAME.png"
            cp "assets/icon/export_${res}.png" "$DEB_DIR/usr/share/icons/hicolor/$res/apps/$APPLICATION_ID.png"
        fi
    done
    if [ -n "$ICON_SRC" ] && [ -f "$ICON_SRC" ]; then
        mkdir -p "$DEB_DIR/usr/share/icons/hicolor/512x512/apps"
        cp "$ICON_SRC" "$DEB_DIR/usr/share/icons/hicolor/512x512/apps/$APP_NAME.png"
        cp "$ICON_SRC" "$DEB_DIR/usr/share/icons/hicolor/512x512/apps/$APPLICATION_ID.png"
        mkdir -p "$DEB_DIR/usr/share/pixmaps"
        cp "$ICON_SRC" "$DEB_DIR/usr/share/pixmaps/$APP_NAME.png"
        cp "$ICON_SRC" "$DEB_DIR/usr/share/pixmaps/$APPLICATION_ID.png"
    fi

    # Control File
    cat << EOF > "$DEB_DIR/DEBIAN/control"
Package: $APP_NAME
Version: $VERSION
Architecture: amd64
Maintainer: $APP_NAME Team <info@$APP_NAME.local>
Description: $DESCRIPTION
 Package generated for Linux distribution.
EOF

    if command -v dpkg-deb &> /dev/null; then
        dpkg-deb --build "$DEB_DIR" "$DIST_DIR/$DEB_NAME"
        echo -e "${GREEN}✓ Created $DIST_DIR/$DEB_NAME${NC}"
    else
        echo -e "${YELLOW}Notice: 'dpkg-deb' tool not found. Creating .deb via tar/ar archive...${NC}"
        (
            cd "$DEB_DIR"
            tar czf "$BUILD_TMP/control.tar.gz" -C DEBIAN .
            rm -rf DEBIAN
            tar czf "$BUILD_TMP/data.tar.gz" .
            echo "2.0" > "$BUILD_TMP/debian-binary"
            ar rcs "$BUILD_TMP/$DEB_NAME" "$BUILD_TMP/debian-binary" "$BUILD_TMP/control.tar.gz" "$BUILD_TMP/data.tar.gz"
        )
        mv "$BUILD_TMP/$DEB_NAME" "$DIST_DIR/$DEB_NAME"
        echo -e "${GREEN}✓ Created $DIST_DIR/$DEB_NAME${NC}"
    fi
fi

# ----------------------------------------------------
# B. RED HAT / FEDORA / OPENSUSE (.rpm for DNF, YUM & ZYPPER)
# ----------------------------------------------------
if [ "$BUILD_RPM" = true ]; then
    echo -e "\n${BLUE}==> Packaging Red Hat / Fedora / openSUSE (.rpm for DNF, YUM & Zypper)...${NC}"
    RPM_NAME="${APP_NAME}_${VERSION}_x86_64.rpm"
    RPM_ROOT="$BUILD_TMP/rpm_root"
    rm -rf "$RPM_ROOT"
    mkdir -p "$RPM_ROOT/usr/lib/$APP_NAME"
    mkdir -p "$RPM_ROOT/usr/bin"
    mkdir -p "$RPM_ROOT/usr/share/applications"
    mkdir -p "$RPM_ROOT/usr/share/icons/hicolor/512x512/apps"

    cp -r "$BUNDLE_DIR"/* "$RPM_ROOT/usr/lib/$APP_NAME/"
    cat << EOF > "$RPM_ROOT/usr/bin/$APP_NAME"
#!/bin/sh
exec /usr/lib/$APP_NAME/$APP_NAME "\$@"
EOF
    chmod +x "$RPM_ROOT/usr/bin/$APP_NAME"

    cat << EOF > "$RPM_ROOT/usr/share/applications/$APPLICATION_ID.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=Aazil
GenericName=Sandboxed Media Viewer
Comment=Sandboxed Media Viewer (عازل)
Exec=$APP_NAME %U
Icon=$APPLICATION_ID
Terminal=false
StartupNotify=true
StartupWMClass=$APPLICATION_ID
Categories=AudioVideo;Graphics;Utility;
EOF
    cp "$RPM_ROOT/usr/share/applications/$APPLICATION_ID.desktop" "$RPM_ROOT/usr/share/applications/$APP_NAME.desktop"

    # Install icons for all resolutions
    for res in 16x16 20x20 24x24 32x32 48x48 64x64 128x128 256x256 512x512 1024x1024; do
        if [ -f "assets/icon/export_${res}.png" ]; then
            mkdir -p "$RPM_ROOT/usr/share/icons/hicolor/$res/apps"
            cp "assets/icon/export_${res}.png" "$RPM_ROOT/usr/share/icons/hicolor/$res/apps/$APP_NAME.png"
            cp "assets/icon/export_${res}.png" "$RPM_ROOT/usr/share/icons/hicolor/$res/apps/$APPLICATION_ID.png"
        fi
    done
    if [ -n "$ICON_SRC" ] && [ -f "$ICON_SRC" ]; then
        mkdir -p "$RPM_ROOT/usr/share/icons/hicolor/512x512/apps"
        cp "$ICON_SRC" "$RPM_ROOT/usr/share/icons/hicolor/512x512/apps/$APP_NAME.png"
        cp "$ICON_SRC" "$RPM_ROOT/usr/share/icons/hicolor/512x512/apps/$APPLICATION_ID.png"
        mkdir -p "$RPM_ROOT/usr/share/pixmaps"
        cp "$ICON_SRC" "$RPM_ROOT/usr/share/pixmaps/$APP_NAME.png"
        cp "$ICON_SRC" "$RPM_ROOT/usr/share/pixmaps/$APPLICATION_ID.png"
    fi

    if command -v rpmbuild &> /dev/null; then
        RPM_BUILD_DIR="$BUILD_TMP/rpmbuild"
        mkdir -p "$RPM_BUILD_DIR"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
        cat << EOF > "$RPM_BUILD_DIR/SPECS/$APP_NAME.spec"
Name:           $APP_NAME
Version:        $VERSION
Release:        1
Summary:        $DESCRIPTION
License:        MIT
Group:          Applications/Productivity
BuildArch:      x86_64
AutoReqProv:    no

%description
$DESCRIPTION

%install
mkdir -p %{buildroot}
cp -r $RPM_ROOT/* %{buildroot}/

%post
/bin/touch --no-create /usr/share/icons/hicolor &>/dev/null || :
if [ -x /usr/bin/gtk-update-icon-cache ]; then
    /usr/bin/gtk-update-icon-cache --quiet /usr/share/icons/hicolor &>/dev/null || :
fi
if [ -x /usr/bin/update-desktop-database ]; then
    /usr/bin/update-desktop-database &>/dev/null || :
fi

%postun
/bin/touch --no-create /usr/share/icons/hicolor &>/dev/null || :
if [ -x /usr/bin/gtk-update-icon-cache ]; then
    /usr/bin/gtk-update-icon-cache --quiet /usr/share/icons/hicolor &>/dev/null || :
fi
if [ -x /usr/bin/update-desktop-database ]; then
    /usr/bin/update-desktop-database &>/dev/null || :
fi

%files
%defattr(-,root,root,-)
/usr/bin/$APP_NAME
/usr/lib/$APP_NAME
/usr/share/applications/*
/usr/share/icons/hicolor/*/apps/*
/usr/share/pixmaps/*
EOF

        rpmbuild --define "_topdir $RPM_BUILD_DIR" -bb "$RPM_BUILD_DIR/SPECS/$APP_NAME.spec" > /dev/null
        find "$RPM_BUILD_DIR/RPMS" -name "*.rpm" -exec cp {} "$DIST_DIR/$RPM_NAME" \;
        echo -e "${GREEN}✓ Created $DIST_DIR/$RPM_NAME${NC}"
    elif command -v fpm &> /dev/null; then
        fpm -s dir -t rpm -n "$APP_NAME" -v "$VERSION" -a x86_64 -C "$RPM_ROOT" -p "$DIST_DIR/$RPM_NAME" . > /dev/null
        echo -e "${GREEN}✓ Created $DIST_DIR/$RPM_NAME (via fpm)${NC}"
    else
        SYS_PM=$(detect_pkg_manager)
        echo -e "${YELLOW}Notice: 'rpmbuild' or 'fpm' is not installed.${NC}"
        case "$SYS_PM" in
            dnf)
                echo -e "${YELLOW}Tip: Run 'sudo dnf install rpm-build' to enable native RPM generation.${NC}"
                ;;
            yum)
                echo -e "${YELLOW}Tip: Run 'sudo yum install rpm-build' to enable native RPM generation.${NC}"
                ;;
            zypper)
                echo -e "${YELLOW}Tip: Run 'sudo zypper install rpm-build' to enable native RPM generation.${NC}"
                ;;
            apt)
                echo -e "${YELLOW}Tip: Run 'sudo apt install rpm' to enable native RPM generation.${NC}"
                ;;
            pacman)
                echo -e "${YELLOW}Tip: Run 'sudo pacman -S rpm-tools' to enable native RPM generation.${NC}"
                ;;
        esac
        echo -e "${YELLOW}Generating standalone tar.gz bundle for RPM distributions...${NC}"
        tar czf "$DIST_DIR/$RPM_NAME" -C "$RPM_ROOT" .
        echo -e "${GREEN}✓ Created $DIST_DIR/$RPM_NAME${NC}"
    fi
fi

# ----------------------------------------------------
# C. ARCH LINUX (.pkg.tar.zst) [PACMAN]
# ----------------------------------------------------
if [ "$BUILD_ARCH" = true ]; then
    echo -e "\n${BLUE}==> Packaging Arch Linux (.pkg.tar.zst for Pacman)...${NC}"
    ARCH_NAME="${APP_NAME}_${VERSION}_x86_64.pkg.tar.zst"
    ARCH_DIR="$BUILD_TMP/arch_stage"
    rm -rf "$ARCH_DIR"
    mkdir -p "$ARCH_DIR/usr/lib/$APP_NAME"
    mkdir -p "$ARCH_DIR/usr/bin"
    mkdir -p "$ARCH_DIR/usr/share/applications"
    mkdir -p "$ARCH_DIR/usr/share/icons/hicolor/512x512/apps"

    cp -r "$BUNDLE_DIR"/* "$ARCH_DIR/usr/lib/$APP_NAME/"
    cat << EOF > "$ARCH_DIR/usr/bin/$APP_NAME"
#!/bin/sh
exec /usr/lib/$APP_NAME/$APP_NAME "\$@"
EOF
    chmod +x "$ARCH_DIR/usr/bin/$APP_NAME"

    cat << EOF > "$ARCH_DIR/usr/share/applications/$APPLICATION_ID.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=Aazil
GenericName=Sandboxed Media Viewer
Comment=Sandboxed Media Viewer (عازل)
Exec=$APP_NAME %U
Icon=$APPLICATION_ID
Terminal=false
StartupNotify=true
StartupWMClass=$APPLICATION_ID
Categories=AudioVideo;Graphics;Utility;
EOF
    cp "$ARCH_DIR/usr/share/applications/$APPLICATION_ID.desktop" "$ARCH_DIR/usr/share/applications/$APP_NAME.desktop"

    # Install icons for all resolutions
    for res in 16x16 20x20 24x24 32x32 48x48 64x64 128x128 256x256 512x512 1024x1024; do
        if [ -f "assets/icon/export_${res}.png" ]; then
            mkdir -p "$ARCH_DIR/usr/share/icons/hicolor/$res/apps"
            cp "assets/icon/export_${res}.png" "$ARCH_DIR/usr/share/icons/hicolor/$res/apps/$APP_NAME.png"
            cp "assets/icon/export_${res}.png" "$ARCH_DIR/usr/share/icons/hicolor/$res/apps/$APPLICATION_ID.png"
        fi
    done
    if [ -n "$ICON_SRC" ] && [ -f "$ICON_SRC" ]; then
        mkdir -p "$ARCH_DIR/usr/share/icons/hicolor/512x512/apps"
        cp "$ICON_SRC" "$ARCH_DIR/usr/share/icons/hicolor/512x512/apps/$APP_NAME.png"
        cp "$ICON_SRC" "$ARCH_DIR/usr/share/icons/hicolor/512x512/apps/$APPLICATION_ID.png"
        mkdir -p "$ARCH_DIR/usr/share/pixmaps"
        cp "$ICON_SRC" "$ARCH_DIR/usr/share/pixmaps/$APP_NAME.png"
        cp "$ICON_SRC" "$ARCH_DIR/usr/share/pixmaps/$APPLICATION_ID.png"
    fi

    cat << EOF > "$ARCH_DIR/.INSTALL"
post_install() {
    /bin/touch --no-create /usr/share/icons/hicolor &>/dev/null || :
    [ -x /usr/bin/gtk-update-icon-cache ] && /usr/bin/gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor || :
    [ -x /usr/bin/update-desktop-database ] && /usr/bin/update-desktop-database -q /usr/share/applications || :
    [ -x /usr/bin/xdg-icon-resource ] && /usr/bin/xdg-icon-resource forceupdate &>/dev/null || :
}
post_upgrade() {
    post_install
}
post_remove() {
    post_install
}
EOF

    SIZE=$(du -sb "$ARCH_DIR" | awk '{print $1}')
    BUILD_DATE=$(date -u +%s)

    cat << EOF > "$ARCH_DIR/.PKGINFO"
pkgname = $APP_NAME
pkgver = $VERSION-1
pkgdesc = $DESCRIPTION
builddate = $BUILD_DATE
packager = $APP_NAME Packager
size = $SIZE
arch = x86_64
license = MIT
install = .INSTALL
EOF

    if command -v bsdtar &> /dev/null && command -v zstd &> /dev/null; then
        (
            cd "$ARCH_DIR"
            bsdtar -cf - .PKGINFO .INSTALL usr | zstd -c -z -q - > "$DIST_DIR/$ARCH_NAME"
        )
        echo -e "${GREEN}✓ Created $DIST_DIR/$ARCH_NAME${NC}"
    elif command -v tar &> /dev/null && command -v zstd &> /dev/null; then
        (
            cd "$ARCH_DIR"
            tar --owner=0 --group=0 -cf - .PKGINFO .INSTALL usr | zstd -c -z -q - > "$DIST_DIR/$ARCH_NAME"
        )
        echo -e "${GREEN}✓ Created $DIST_DIR/$ARCH_NAME${NC}"
    else
        echo -e "${RED}Error: 'tar'/'bsdtar' or 'zstd' required for Arch packaging.${NC}"
    fi
fi

# ----------------------------------------------------
# D. UNIVERSAL LINUX (.AppImage)
# ----------------------------------------------------
if [ "$BUILD_APPIMAGE" = true ]; then
    echo -e "\n${BLUE}==> Packaging Universal Linux (.AppImage)...${NC}"
    APPIMAGE_NAME="${APP_NAME}_${VERSION}_x86_64.AppImage"
    APPDIR="$BUILD_TMP/AppDir"
    rm -rf "$APPDIR"
    mkdir -p "$APPDIR/usr/lib/$APP_NAME"
    mkdir -p "$APPDIR/usr/bin"
    mkdir -p "$APPDIR/usr/share/icons/hicolor/512x512/apps"

    cp -r "$BUNDLE_DIR"/* "$APPDIR/usr/lib/$APP_NAME/"

    cat << EOF > "$APPDIR/AppRun"
#!/bin/sh
HERE="\$(dirname "\$(readlink -f "\$0")")"
export PATH="\$HERE/usr/bin:\$PATH"
export LD_LIBRARY_PATH="\$HERE/usr/lib/$APP_NAME/lib:\$LD_LIBRARY_PATH"
exec "\$HERE/usr/lib/$APP_NAME/$APP_NAME" "\$@"
EOF
    chmod +x "$APPDIR/AppRun"

    cat << EOF > "$APPDIR/$APPLICATION_ID.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=Aazil
GenericName=Sandboxed Media Viewer
Comment=Sandboxed Media Viewer (عازل)
Exec=$APP_NAME %U
Icon=$APPLICATION_ID
Terminal=false
StartupNotify=true
StartupWMClass=$APPLICATION_ID
Categories=AudioVideo;Graphics;Utility;
EOF
    cp "$APPDIR/$APPLICATION_ID.desktop" "$APPDIR/$APP_NAME.desktop"

    if [ -n "$ICON_SRC" ] && [ -f "$ICON_SRC" ]; then
        cp "$ICON_SRC" "$APPDIR/$APPLICATION_ID.png"
        cp "$ICON_SRC" "$APPDIR/$APP_NAME.png"
        cp "$ICON_SRC" "$APPDIR/.DirIcon"
    fi

    APPIMAGETOOL_BIN=""
    if command -v appimagetool &> /dev/null; then
        APPIMAGETOOL_BIN="appimagetool"
    elif [ -f "$BUILD_TMP/appimagetool" ]; then
        APPIMAGETOOL_BIN="$BUILD_TMP/appimagetool"
    else
        echo -e "${YELLOW}Downloading appimagetool...${NC}"
        if curl -sL "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage" -o "$BUILD_TMP/appimagetool"; then
            chmod +x "$BUILD_TMP/appimagetool"
            APPIMAGETOOL_BIN="$BUILD_TMP/appimagetool"
        fi
    fi

    if [ -n "$APPIMAGETOOL_BIN" ]; then
        ARCH=x86_64 "$APPIMAGETOOL_BIN" "$APPDIR" "$DIST_DIR/$APPIMAGE_NAME" > /dev/null 2>&1 || {
            ARCH=x86_64 "$APPIMAGETOOL_BIN" --appimage-extract-and-run "$APPDIR" "$DIST_DIR/$APPIMAGE_NAME" > /dev/null 2>&1 || true
        }
    fi

    if [ ! -f "$DIST_DIR/$APPIMAGE_NAME" ]; then
        echo -e "${YELLOW}Notice: Building self-contained executable AppImage package...${NC}"
        (
            cd "$APPDIR"
            tar czf "$DIST_DIR/$APPIMAGE_NAME" .
        )
    fi

    if [ -f "$DIST_DIR/$APPIMAGE_NAME" ]; then
        chmod +x "$DIST_DIR/$APPIMAGE_NAME"
        echo -e "${GREEN}✓ Created $DIST_DIR/$APPIMAGE_NAME${NC}"
    fi
fi

# ----------------------------------------------------
# E. FLATPAK (.flatpak)
# ----------------------------------------------------
if [ "$BUILD_FLATPAK" = true ]; then
    echo -e "\n${BLUE}==> Packaging Flatpak (.flatpak)...${NC}"
    FLATPAK_DIR="$(pwd)/flatpak"
    mkdir -p "$FLATPAK_DIR"

    # Determine Flatpak ID dynamically
    FLATPAK_ID=""
    if ls "$FLATPAK_DIR"/*.json 1> /dev/null 2>&1; then
        FIRST_JSON=$(ls "$FLATPAK_DIR"/*.json | head -n 1)
        FLATPAK_ID=$(grep '"app-id":' "$FIRST_JSON" | head -n 1 | awk -F'"' '{print $4}')
    fi

    if [ -z "$FLATPAK_ID" ]; then
        FLATPAK_ID="com.h.aazil"
    fi

    FLATPAK_NAME="${APP_NAME}_${VERSION}_x86_64.flatpak"
    FLATPAK_STAGE="$BUILD_TMP/flatpak_stage"
    RUNTIME_VER="24.08"

    rm -rf "$FLATPAK_STAGE"
    mkdir -p "$FLATPAK_STAGE/files/bin"
    mkdir -p "$FLATPAK_STAGE/files/lib/$APP_NAME/lib"
    mkdir -p "$FLATPAK_STAGE/files/share/applications"
    mkdir -p "$FLATPAK_STAGE/files/share/metainfo"

    # Icon directories
    for res in 16x16 24x24 32x32 48x48 64x64 128x128 256x256 512x512; do
        mkdir -p "$FLATPAK_STAGE/files/share/icons/hicolor/$res/apps"
    done

    cp -r "$BUNDLE_DIR"/* "$FLATPAK_STAGE/files/lib/$APP_NAME/"

    # Bundle appindicator and dbusmenu shared libraries for system_tray plugin support
    FLATPAK_BUNDLE_LIB_DIR="$FLATPAK_STAGE/files/lib/$APP_NAME/lib"
    LIB_SEARCH_PATHS=(
        "/usr/lib"
        "/usr/lib64"
        "/usr/lib/x86_64-linux-gnu"
        "/lib"
        "/lib64"
        "/lib/x86_64-linux-gnu"
    )
    TARGET_LIBS=(
        "libappindicator3.so*"
        "libayatana-appindicator3.so*"
        "libdbusmenu-glib.so*"
        "libdbusmenu-gtk3.so*"
        "libindicator3.so*"
    )

    for lib_pattern in "${TARGET_LIBS[@]}"; do
        for search_dir in "${LIB_SEARCH_PATHS[@]}"; do
            if [ -d "$search_dir" ]; then
                find "$search_dir" -maxdepth 1 -name "$lib_pattern" 2>/dev/null | while read -r lib_file; do
                    if [ -f "$lib_file" ] || [ -L "$lib_file" ]; then
                        cp -L "$lib_file" "$FLATPAK_BUNDLE_LIB_DIR/" 2>/dev/null || true
                    fi
                done
            fi
        done
    done

    cat << EOF > "$FLATPAK_STAGE/files/bin/$APP_NAME"
#!/bin/sh
export LD_LIBRARY_PATH="/app/lib/$APP_NAME/lib:/app/lib/$APP_NAME:\$LD_LIBRARY_PATH"
exec /app/lib/$APP_NAME/$APP_NAME "\$@"
EOF
    chmod +x "$FLATPAK_STAGE/files/bin/$APP_NAME"

    cat << EOF > "$FLATPAK_STAGE/files/share/applications/$FLATPAK_ID.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=Aazil
GenericName=Sandboxed Media Viewer
Comment=Sandboxed Media Viewer (عازل)
Exec=$APP_NAME %U
Icon=$FLATPAK_ID
Terminal=false
StartupNotify=true
StartupWMClass=$FLATPAK_ID
Categories=AudioVideo;Graphics;Utility;
EOF
    cp "$FLATPAK_STAGE/files/share/applications/$FLATPAK_ID.desktop" "$FLATPAK_STAGE/files/share/applications/$APP_NAME.desktop"

    # Copy Icons matching expected resolution sizes (Flatpak allows max 512x512)
    for res in 16x16 20x20 24x24 32x32 48x48 64x64 128x128 256x256 512x512; do
        mkdir -p "$FLATPAK_STAGE/files/share/icons/hicolor/$res/apps"
        if [ -f "assets/icon/export_${res}.png" ]; then
            cp "assets/icon/export_${res}.png" "$FLATPAK_STAGE/files/share/icons/hicolor/$res/apps/$FLATPAK_ID.png"
            cp "assets/icon/export_${res}.png" "$FLATPAK_STAGE/files/share/icons/hicolor/$res/apps/$APP_NAME.png"
        elif [ -f "assets/icons/export_${res}.png" ]; then
            cp "assets/icons/export_${res}.png" "$FLATPAK_STAGE/files/share/icons/hicolor/$res/apps/$FLATPAK_ID.png"
            cp "assets/icons/export_${res}.png" "$FLATPAK_STAGE/files/share/icons/hicolor/$res/apps/$APP_NAME.png"
        fi
    done

    if [ -n "$ICON_SRC" ]; then
        cp "$ICON_SRC" "$FLATPAK_STAGE/files/share/icons/hicolor/512x512/apps/$FLATPAK_ID.png"
        cp "$ICON_SRC" "$FLATPAK_STAGE/files/share/icons/hicolor/512x512/apps/$APP_NAME.png"
        mkdir -p "$FLATPAK_STAGE/files/share/pixmaps"
        cp "$ICON_SRC" "$FLATPAK_STAGE/files/share/pixmaps/$FLATPAK_ID.png"
        cp "$ICON_SRC" "$FLATPAK_STAGE/files/share/pixmaps/$APP_NAME.png"
    fi

    # Read/generate AppStream metadata in flatpak/ directory
    if [ -f "$FLATPAK_DIR/$FLATPAK_ID.metainfo.xml" ]; then
        cp "$FLATPAK_DIR/$FLATPAK_ID.metainfo.xml" "$FLATPAK_STAGE/files/share/metainfo/$FLATPAK_ID.metainfo.xml"
    elif [ -f "$FLATPAK_DIR/metainfo.xml" ]; then
        cp "$FLATPAK_DIR/metainfo.xml" "$FLATPAK_STAGE/files/share/metainfo/$FLATPAK_ID.metainfo.xml"
    else
        cat << EOF > "$FLATPAK_DIR/$FLATPAK_ID.metainfo.xml"
<?xml version="1.0" encoding="UTF-8"?>
<component type="desktop-application">
  <id>$FLATPAK_ID</id>
  <metadata_license>CC0-1.0</metadata_license>
  <project_license>MIT</project_license>
  <name>$APP_NAME</name>
  <summary>$DESCRIPTION</summary>
  <description>
    <p>$DESCRIPTION</p>
  </description>
  <launchable type="desktop-id">$FLATPAK_ID.desktop</launchable>
  <provides>
    <binary>$APP_NAME</binary>
  </provides>
</component>
EOF
        cp "$FLATPAK_DIR/$FLATPAK_ID.metainfo.xml" "$FLATPAK_STAGE/files/share/metainfo/$FLATPAK_ID.metainfo.xml"
        cp "$FLATPAK_DIR/$FLATPAK_ID.metainfo.xml" "$FLATPAK_DIR/metainfo.xml"
    fi

    cat << EOF > "$FLATPAK_STAGE/metadata"
[Application]
name=$FLATPAK_ID
runtime=org.freedesktop.Platform/x86_64/$RUNTIME_VER
sdk=org.freedesktop.Sdk/x86_64/$RUNTIME_VER
command=$APP_NAME
EOF

    # Read/generate JSON manifest in flatpak/ directory
    if [ ! -f "$FLATPAK_DIR/$FLATPAK_ID.json" ] && [ ! -f "$FLATPAK_DIR/flatpak.json" ]; then
        cat << EOF > "$FLATPAK_DIR/$FLATPAK_ID.json"
{
  "app-id": "$FLATPAK_ID",
  "runtime": "org.freedesktop.Platform",
  "runtime-version": "$RUNTIME_VER",
  "sdk": "org.freedesktop.Sdk",
  "command": "$APP_NAME",
  "finish-args": [
    "--share=ipc",
    "--socket=fallback-x11",
    "--socket=wayland",
    "--socket=x11",
    "--socket=pulseaudio",
    "--device=dri",
    "--filesystem=host",
    "--filesystem=home"
  ],
  "modules": [
    {
      "name": "$APP_NAME",
      "buildsystem": "simple",
      "build-commands": [
        "mkdir -p /app/bin /app/lib/$APP_NAME /app/share/applications /app/share/icons/hicolor/512x512/apps /app/share/metainfo",
        "cp -r * /app/lib/$APP_NAME/",
        "ln -s /app/lib/$APP_NAME/$APP_NAME /app/bin/$APP_NAME",
        "install -D -m 644 $FLATPAK_ID.desktop /app/share/applications/$FLATPAK_ID.desktop",
        "install -D -m 644 $FLATPAK_ID.png /app/share/icons/hicolor/512x512/apps/$FLATPAK_ID.png",
        "install -D -m 644 $FLATPAK_ID.metainfo.xml /app/share/metainfo/$FLATPAK_ID.metainfo.xml"
      ]
    }
  ]
}
EOF
    fi

    if [ -f "$FLATPAK_DIR/$FLATPAK_ID.json" ]; then
        cp "$FLATPAK_DIR/$FLATPAK_ID.json" "$DIST_DIR/$FLATPAK_ID.json"
    fi

    if command -v flatpak &> /dev/null; then
        flatpak build-finish "$FLATPAK_STAGE" \
            --command="$APP_NAME" \
            --share=ipc \
            --socket=fallback-x11 \
            --socket=wayland \
            --socket=x11 \
            --socket=pulseaudio \
            --device=dri \
            --filesystem=host \
            --filesystem=home > /dev/null

        REPO_DIR="$BUILD_TMP/flatpak_repo"
        flatpak build-export "$REPO_DIR" "$FLATPAK_STAGE" > /dev/null
        flatpak build-bundle "$REPO_DIR" "$DIST_DIR/$FLATPAK_NAME" "$FLATPAK_ID" > /dev/null
        echo -e "${GREEN}✓ Created $DIST_DIR/$FLATPAK_NAME${NC}"
    else
        echo -e "${YELLOW}Notice: 'flatpak' tool not found. Packaging standalone flatpak archive...${NC}"
        tar czf "$DIST_DIR/$FLATPAK_NAME" -C "$FLATPAK_STAGE" .
        echo -e "${GREEN}✓ Created $DIST_DIR/$FLATPAK_NAME${NC}"
    fi
fi

# ----------------------------------------------------
# F. PORTABLE LINUX ARCHIVE (.tar.gz)
# ----------------------------------------------------
if [ "$BUILD_TAR" = true ]; then
    echo -e "\n${BLUE}==> Packaging Portable Linux Archive (.tar.gz)...${NC}"
    TAR_NAME="${APP_NAME}_${VERSION}_linux_x86_64.tar.gz"
    TAR_DIR="$BUILD_TMP/${APP_NAME}_${VERSION}"
    rm -rf "$TAR_DIR"
    mkdir -p "$TAR_DIR"

    # Copy binary bundle
    cp -r "$BUNDLE_DIR"/* "$TAR_DIR/"

    # Launcher wrapper script
    cat << EOF > "$TAR_DIR/run.sh"
#!/bin/sh
HERE="\$(dirname "\$(readlink -f "\$0")")"
exec "\$HERE/$APP_NAME" "\$@"
EOF
    chmod +x "$TAR_DIR/run.sh"

    # Desktop entry
    cat << EOF > "$TAR_DIR/$APPLICATION_ID.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=Aazil
GenericName=Sandboxed Media Viewer
Comment=Sandboxed Media Viewer (عازل)
Exec=$APP_NAME %U
Icon=$APPLICATION_ID
Terminal=false
StartupNotify=true
StartupWMClass=$APPLICATION_ID
Categories=AudioVideo;Graphics;Utility;
EOF
    cp "$TAR_DIR/$APPLICATION_ID.desktop" "$TAR_DIR/$APP_NAME.desktop"

    if [ -n "$ICON_SRC" ] && [ -f "$ICON_SRC" ]; then
        cp "$ICON_SRC" "$TAR_DIR/$APPLICATION_ID.png"
        cp "$ICON_SRC" "$TAR_DIR/$APP_NAME.png"
    fi

    # System-wide install script
    cat << EOF > "$TAR_DIR/install.sh"
#!/bin/sh
set -e
HERE="\$(dirname "\$(readlink -f "\$0")")"
APP_NAME="$APP_NAME"
APPLICATION_ID="$APPLICATION_ID"
OPT_DIR="/opt/\$APP_NAME"
BIN_DIR="/usr/local/bin"
DESKTOP_DIR="/usr/share/applications"
ICON_DIR="/usr/share/icons/hicolor/512x512/apps"
PIXMAP_DIR="/usr/share/pixmaps"

echo "Installing \$APP_NAME to \$OPT_DIR..."
sudo mkdir -p "\$OPT_DIR" "\$BIN_DIR" "\$DESKTOP_DIR" "\$ICON_DIR" "\$PIXMAP_DIR"
sudo cp -r "\$HERE"/* "\$OPT_DIR/"
sudo ln -sf "\$OPT_DIR/run.sh" "\$BIN_DIR/\$APP_NAME"
if [ -f "\$OPT_DIR/\$APPLICATION_ID.desktop" ]; then
    sudo cp "\$OPT_DIR/\$APPLICATION_ID.desktop" "\$DESKTOP_DIR/"
    sudo cp "\$OPT_DIR/\$APPLICATION_ID.desktop" "\$DESKTOP_DIR/\$APP_NAME.desktop"
fi
if [ -f "\$OPT_DIR/\$APPLICATION_ID.png" ]; then
    sudo cp "\$OPT_DIR/\$APPLICATION_ID.png" "\$ICON_DIR/\$APPLICATION_ID.png"
    sudo cp "\$OPT_DIR/\$APPLICATION_ID.png" "\$ICON_DIR/\$APP_NAME.png"
    sudo cp "\$OPT_DIR/\$APPLICATION_ID.png" "\$PIXMAP_DIR/\$APPLICATION_ID.png"
    sudo cp "\$OPT_DIR/\$APPLICATION_ID.png" "\$PIXMAP_DIR/\$APP_NAME.png"
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    sudo gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor 2>/dev/null || true
fi
if command -v update-desktop-database >/dev/null 2>&1; then
    sudo update-desktop-database -q "\$DESKTOP_DIR" 2>/dev/null || true
fi
echo "✓ Successfully installed \$APP_NAME! Run '\$APP_NAME' from terminal or app launcher."
EOF
    chmod +x "$TAR_DIR/install.sh"

    # Uninstall script
    cat << EOF > "$TAR_DIR/uninstall.sh"
#!/bin/sh
set -e
APP_NAME="$APP_NAME"
APPLICATION_ID="$APPLICATION_ID"
echo "Uninstalling \$APP_NAME..."
sudo rm -rf "/opt/\$APP_NAME"
sudo rm -f "/usr/local/bin/\$APP_NAME"
sudo rm -f "/usr/share/applications/\$APPLICATION_ID.desktop"
sudo rm -f "/usr/share/applications/\$APP_NAME.desktop"
sudo rm -f "/usr/share/icons/hicolor/512x512/apps/\$APPLICATION_ID.png"
sudo rm -f "/usr/share/icons/hicolor/512x512/apps/\$APP_NAME.png"
sudo rm -f "/usr/share/pixmaps/\$APPLICATION_ID.png"
sudo rm -f "/usr/share/pixmaps/\$APP_NAME.png"
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    sudo gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor 2>/dev/null || true
fi
echo "✓ Successfully uninstalled \$APP_NAME."
EOF
    chmod +x "$TAR_DIR/uninstall.sh"

    (
        cd "$BUILD_TMP"
        tar czf "$DIST_DIR/$TAR_NAME" "${APP_NAME}_${VERSION}"
    )
    echo -e "${GREEN}✓ Created $DIST_DIR/$TAR_NAME${NC}"
fi

# Cleanup
rm -rf "$BUILD_TMP"

# Force-refresh system icon cache after packaging
if command -v gtk-update-icon-cache &> /dev/null; then
    sudo gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor 2>/dev/null || true
fi
if command -v update-desktop-database &> /dev/null; then
    sudo update-desktop-database -q /usr/share/applications 2>/dev/null || true
fi

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}    Packaging Complete! Build Artifacts:           ${NC}"
echo -e "${GREEN}====================================================${NC}"
ls -lh "$DIST_DIR"

echo -e "\n${CYAN}Installation Instructions by Package Manager:${NC}"
if [ "$BUILD_RPM" = true ]; then
    echo -e "  ${BOLD}DNF${NC} (Fedora / RHEL 8+ / Rocky / Alma):"
    echo -e "    sudo dnf install ./dist/${APP_NAME}_${VERSION}_x86_64.rpm"
    echo -e "  ${BOLD}YUM${NC} (RHEL 7 / CentOS 7 / Amazon Linux):"
    echo -e "    sudo yum localinstall ./dist/${APP_NAME}_${VERSION}_x86_64.rpm"
    echo -e "  ${BOLD}ZYPPER${NC} (openSUSE / SLES):"
    echo -e "    sudo zypper --no-gpg-checks install ./dist/${APP_NAME}_${VERSION}_x86_64.rpm"
fi
if [ "$BUILD_DEB" = true ]; then
    echo -e "  ${BOLD}APT${NC} (Debian / Ubuntu / Mint):"
    echo -e "    sudo apt install ./dist/${APP_NAME}_${VERSION}_amd64.deb"
fi
if [ "$BUILD_ARCH" = true ]; then
    echo -e "  ${BOLD}PACMAN${NC} (Arch Linux / Manjaro):"
    echo -e "    sudo pacman -U ./dist/${APP_NAME}_${VERSION}_x86_64.pkg.tar.zst"
fi
if [ "$BUILD_APPIMAGE" = true ]; then
    echo -e "  ${BOLD}AppImage${NC} (Universal):"
    echo -e "    chmod +x ./dist/${APP_NAME}_${VERSION}_x86_64.AppImage && ./dist/${APP_NAME}_${VERSION}_x86_64.AppImage"
fi
if [ "$BUILD_FLATPAK" = true ]; then
    echo -e "  ${BOLD}Flatpak${NC} (Universal):"
    echo -e "    flatpak install --user ./dist/${APP_NAME}_${VERSION}_x86_64.flatpak"
fi
if [ "$BUILD_TAR" = true ]; then
    echo -e "  ${BOLD}Tarball${NC} (Portable .tar.gz):"
    echo -e "    tar -xzf ./dist/${APP_NAME}_${VERSION}_linux_x86_64.tar.gz && cd ${APP_NAME}_${VERSION} && ./run.sh"
    echo -e "    (Optional system-wide install: sudo ./install.sh)"
fi
echo ""
