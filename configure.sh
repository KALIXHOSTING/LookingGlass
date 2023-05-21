#!/bin/bash
################################
# LookingGlass - User friendly PHP Looking Glass
#
# package     LookingGlass
# author      MAVEN
# copyright   2023 Kalixhosting.
# link        https://kalixhosting.com
# license     http://opensource.org/licenses/MIT MIT License
# version     1.2.0
################################

#######################
##                   ##
##     Functions     ##
##                   ##
#######################

DIR=$(dirname "$0")

##
# Fix MTR on RHEL-based OS
##
function mtrFix() {
  # Check permissions for MTR & Symbolic link
  if [ $(stat --format="%a" /usr/sbin/mtr) -ne 4755 ] || [ ! -f "/usr/bin/mtr" ]; then
    if [ $(id -u) = "0" ]; then
      echo 'Fixing MTR permissions...'
      chmod 4755 /usr/sbin/mtr
      ln -s /usr/sbin/mtr /usr/bin/mtr
    else
      cat <<EOF

##### IMPORTANT #####
You are not root. Please log into root and run:
chmod 4755 /usr/sbin/mtr
ln -s /usr/sbin/mtr /usr/bin/mtr
#####################
EOF
    fi
  fi
}

##
# Check and install script requirements
##
function requirements() {
  # Check for apt-get/yum
  if command -v apt-get >/dev/null 2>&1; then
    INSTALL='apt-get'
    INSTALL_COMMAND='install'
    MTR_PACKAGE='mtr'
  elif command -v yum >/dev/null 2>&1; then
    INSTALL='yum'
    INSTALL_COMMAND='install -y'
    MTR_PACKAGE='mtr'
  else
    cat <<EOF

##### IMPORTANT #####
Unknown Operating system. Install dependencies manually:
host mtr iputils-ping traceroute
#####################
EOF
    return
  fi

  # Array of required functions
  local REQUIRE=("host" "iputils-ping" "traceroute")

  # Install MTR
  echo "Installing mtr using $INSTALL..."
  sudo "$INSTALL" $INSTALL_COMMAND $MTR_PACKAGE
  sleep 1

  # Loop through other requirements & install
  for i in "${REQUIRE[@]}"; do
    echo "Checking for $i..."
    if ! command -v "$i" >/dev/null 2>&1; then
      sudo "$INSTALL" $INSTALL_COMMAND "$i"
    fi
    sleep 1
  done
}

##
# Setup parameters for PHP file creation
##
function setup() {
  sleep 1

  # User input
  read -e -p "Enter the size of test files in MB (Example: 100MB 1GB 2GB) [${TEST[*]}]: " T

  # Create test files
  if [[ -n $T ]]; then
    echo
    echo 'Removing old test files:'
    # Delete old test files
    local REMOVE=("$DIR"/*.test)
    for i in "${REMOVE[@]}"; do
      if [ -f "$i" ]; then
        echo "Removing $i"
        rm "$i"
        sleep 1
      fi
    done
    IFS=' ' read -ra SIZES <<<"$T"
    for SIZE in "${SIZES[@]}"; do
      echo "Creating $SIZE test file"
      dd if=/dev/zero of="$DIR/${SIZE}.test" bs=1048576 count="${SIZE//[!0-9]/}"
      sleep 1
    done
  fi
}


###########################
##                       ##
##     Configuration     ##
##                       ##
###########################

# Clear terminal
clear

# Welcome message
cat <<EOF
########################################
#
# LookingGlass is a user-friendly script
# to create a functional Looking Glass
# for your network.
#
# Created by Maven (IG:@maven_htx)
# https://kalixhosting.com
#
########################################

EOF

read -e -p "Do you wish to install LookingGlass? (y/n): " ANSWER

if [[ "$ANSWER" = 'y' ]] || [[ "$ANSWER" = 'yes' ]]; then
  cat <<EOF

###              ###
# Starting install #
###              ###

EOF
  sleep 1
else
  echo 'Installation stopped :('
  echo
  exit
fi

# Install required scripts
echo 'Checking script requirements:'
requirements
echo

# Follow setup
cat <<EOF

###                    ###
# Starting configuration #
###                    ###

EOF
echo 'Running setup:'
setup
echo

# Check for RHEL mtr
if [ "$INSTALL" = 'yum' ]; then
  mtrFix
fi

# All done
cat <<EOF

Installation is complete

EOF
sleep 1
