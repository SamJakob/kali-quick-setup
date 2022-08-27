#!/bin/sh

# Exit if a command fails.
set -e

# [[ functions ]]

print_step_start() {
	printf "\033[34;1m\033[1m[\033[37;1m-\033[34;1m\033[1m] $1\033[0m\n"
}

print_step_done() {
	printf "\033[34;1m\033[1m[\033[37;1m+\033[34;1m\033[1m] $1 \033[34;1m(done)\033[0m\n"
}

print_step_fail() {
	printf "\033[31;1m\033[1m[\033[37;1mx\033[31;1m\033[1m] $1 \033[31;1m(failed)\033[0m\n"
}

print_step_skip() {
	printf "\033[30;1m\033[1m[\033[37;1m>\033[30;1m] $1 \033[30;1m(skipped)\033[0m\n"
}

print_info() {
	printf "\033[37;1m\033[1m[\033[34;1mi\033[37;1m] $1\033[0m\n"
}

# [[ check for files ]]

check_file() {
	if [ ! -f "$1" ]; then
		print_step_fail "Failed to locate file: $1"
		exit 1
	fi
}

check_file "./dot_xsession"
check_file "./dot_wm/xrandr-loop"

# [[ start script ]]

# Perform system update
print_step_start "Updating system packages..."
sudo apt-get -qq update
sudo apt-get -qq upgrade
print_step_done "Performing system update"

# [[ SPICE configuration ]]

if [ -x /usr/bin/spice-vdagent ]; then
	print_info "Detected SPICE guest tools. Configuring..."
	print_step_start "Configuring SPICE guest tools..."
	
	# We can only check heuristically if the user has configured SPICE by checking
	# for the presence of .xsession (as if the user has been messing with the X config
	# it is assumed they have dealt with this already) as the other configuration can
	# be moved.
	#
	# Additionally, this script is intended for new VMs where that file does not
	# ordinarily exist.
	#
	# Therefore, this is the safest (and usually foolproof) way to check. If the assumption
	# is wrong, the user may back up their .xsession, re-run the script to get the new config
	# (or add it themselves) and restore their changes.
	if [ ! -f "$HOME/.xsession" ]; then
		# Copy xrandr-loop script to .wm
		print_info "$0 is installing a script to automatically update the display"
		print_info "	when the VM is resized."
		print_info "To prevent this, enter 'no' below. Otherwise, enter the path"
		print_info "	to install the scripts to."
		print_info "You can just press enter to use the default."
		printf "Enter window manager configuration location.\n($HOME/.wm) "
		read -r WMPATH
		
		# Use the default path if no path specified.
		if [ -z "$WMPATH" ]; then
			WMPATH="$HOME/.wm"
		fi
		
		# Case insensitive compare $WMPATH lowercase to 'no'.
		if [ "no" != `echo "$WMPATH" | tr '[:upper:]' '[:lower:]'` ]; then
			print_info "Installing window manager configuration to: $WMPATH"
			print_info "You have 5 seconds to press Ctrl+C if this is incorrect."
			sleep 5
			mkdir -p "$WMPATH"
			
			cp ./dot_wm/xrandr-loop "$WMPATH/xrandr-loop"
			chmod +x "$WMPATH/xrandr-loop"
			
			# Copy .xsession configuration
			cp ./dot_xsession "$HOME/.xsession"
			sed -i "s|__WM_PATH__|$WMPATH|" "$HOME/.xsession"
			chmod +x "$HOME/.xsession"
			
			print_step_done "Configuring SPICE guest tools"
		else
			print_step_skip "User requested to skip configuring SPICE guest tools"
		fi
	else
		print_step_skip "$HOME/.xsession exists - assuming SPICE already configured."
		print_info "If SPICE has not been configured, move your .xsession file,"
		print_info "	re-run this script and then copy your changes to"
		print_info "	.xsession back into the file."
	fi
else
	print_step_skip "Did not detect SPICE guest tools."
	print_info "(Install spice-vdagent if you believe this is an error.)"
fi

# [[ python2, python3 (pip), Volatility 2, Volatility 3 ]]

if !(command -v python2 > /dev/null 2>&1) || (python2 -m pip 2>&1 | grep -q "No module named"); then
	print_step_start "Installing Python 2 with pip..."

	# Install Python 2 with pip (pre-requisite for old tools)
	sudo apt-get install -y python2 python2.7-dev libpython2-dev
	curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
	sudo python2 get-pip.py
	sudo python2 -m pip install -U setuptools wheel
	rm get-pip.py
	
	print_step_done "Installing Python 2 with pip..."
else
	print_step_skip "Python 2 and pip already installed."
fi

if ! (python2 -m pip list 2>&1 | grep -q "volatility"); then
	print_step_start "Installing Volatility 2..."

	# Install Volatility 2
	sudo apt-get install -y build-essential git libdistorm3-dev yara libraw1394-11 libcapstone-dev capstone-tool tzdata
	sudo ln -s /usr/local/lib/python2.7/dist-packages/usr/lib/libyara.so /usr/lib/libyara.so
	python2 -m pip install -U git+https://github.com/volatilityfoundation/volatility.git
	
	print_step_done "Installing Volatility 2"
else
	print_step_skip "Volatility 2 already installed."
fi

if !(command -v python3 > /dev/null 2>&1) || (python3 -m pip 2>&1 | grep -q "No module named"); then
	print_step_start "Installing pip for Python 3..."
	# Install pip for Python 3
	sudo apt-get install -y python3 python3-dev libpython3-dev python3-pip python3-setuptools python3-wheel
	
	print_step_done "Installing pip for Python 3"
else
	print_step_skip "Python 3 and pip already installed."
fi

if ! (python3 -m pip list 2>&1 | grep -q "volatility"); then
	print_step_start "Installing Volatility 3..."
	# Install Volatility 3
	python3 -m pip install -U distorm3 yara pycrypto pillow openpyxl ujson pytz ipython capstone
	python3 -m pip install -U git+https://github.com/volatilityfoundation/volatility3.git

	print_step_done "Installing Volatility 3"
else
	print_step_skip "Volatility 3 already installed."
fi

# Add Volatility to PATH
CURRENT_SHELL_NAME=`basename "$SHELL"`

if [ "$CURRENT_SHELL_NAME" = "bash" ]; then
	# Check if .local/bin in PATH
	if ! (cat ~/.bashrc | grep "PATH" | grep -q ".local/bin"); then
		print_step_start "Adding .local/bin to PATH variable..."
		
		# Add .local/bin to PATH
		echo "export PATH=$HOME/.local/bin:\$PATH" >> ~/.bashrc
		
		print_step_done "Adding .local/bin to PATH variable"
	else
		print_step_skip ".local/bin already in PATH"
	fi
elif [ "$CURRENT_SHELL_NAME" = "zsh" ]; then
	# Check if .local/bin in PATH
	if ! (cat ~/.zshrc | grep "PATH" | grep -q ".local/bin"); then
		print_step_start "Adding .local/bin to PATH variable..."
	
		# Add .local/bin to PATH
		echo "export PATH=$HOME/.local/bin:\$PATH" >> ~/.zshrc
		
		print_step_done "Adding .local/bin to PATH variable"
	else
		print_step_skip ".local/bin already in PATH"
	fi
else
	print_info "To add Volatility 2 and 3 to your PATH,"
	print_info "you need to add $HOME/.local/bin to your path."
	echo ""
	print_info "You might be able to do this as follows:"
	print_info "echo \"export PATH=$HOME/.local/bin:\$PATH\" >> $HOME/.${CURRENT_SHELL_NAME}rc"
	echo ""
	print_info "When you're ready, press ENTER to continue..."
	read -r pause
	echo "===================="
	echo ""
fi

print_info "You'll now need to refresh your shell configuration."
echo ""
print_info "You can do this by closing and re-opening all of your Terminal windows."
print_info "Alternatively, you might be able to do this as follows:"
print_info ". ~/.${CURRENT_SHELL_NAME}rc"

# [[ end script ]]
