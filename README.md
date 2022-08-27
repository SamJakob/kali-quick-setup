# kali-quick-setup
Scripts to quickly set my personal Kali Linux environment.  
Also, refer to [the project Wiki](https://github.com/SamJakob/kali-quick-setup/wiki) for Quick Start guides for various platforms.

---

I use personally this with UTM for Mac on an M2 chip so it may contain some tools specifically for that purpose (that will be ignored on systems that don't need them).  
Though, there's no reason this wouldn't be useful with any host system if you want any of the other tools.

## Features
Currently, this script handles the following.

- SPICE Guest Tools setup (runs only if `spice-vdagent` is installed)
	- (Set up auto-resize when VM window resizes for UTM)
- Set up Python 2 with `python2-pip`
	- (for legacy tools)
- Set up Volatility 2
	- (contains features not yet in Volatility 3 like dumping Notepad text)
- Set up `python3-pip`
- Set up Volatility 3

I will likely add more features to this file as I continue to work with Kali.
Each feature is installed if is not already installed.

I may later add functionality to select which features specifically should be installed, but as this
is primarily for personal use at the moment that is not an immediate goal.

## Usage
```bash
git clone https://github.com/SamJakob/kali-quick-setup.git
cd kali-quick-setup
chmod +x ./setup.sh
./setup.sh
```

## Notes
Some notes on how this repository is managed.

### Quick note on file-naming conventions
For hidden files, to make them easier to work with, I will be naming them in the form
`dot_filename`, where the true name of the file would be `.filename`.

The scripts, when run, will copy these files to their true name in the expected location.

### Quick note on GPG signatures
I will not be personally enforcing the GPG signing of my commits to this repository as I expect to modify this repository from temporary Virtual Machines, thus **all commits will show up as 'Unverified' in the commit history**.

**This should be fine in this case**, however, as the scripts are intended to be fairly minimal. (...plus you probably ought to check random scripts from the internet before you run them in your machines!)
