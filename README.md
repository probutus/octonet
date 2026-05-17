# OctopusNet

Master branch contains original system which needs an ubuntu 16.04 LTS to build due to its age (2015!)
There is a new branch available called octonet-ng which brings the octonet to recent LTS Kernel 6.12.81 and buildroot 2025.02 LTS. Building and flashing works the same for both systems

###Prepare for Building
On Debian/Ubuntu (as root or using sudo):

```
 >apt-get install build-essential bison flex gettext libncurses5-dev texinfo autoconf automake libtool
 >apt-get install libpng12-dev libglib2.0-dev libgtk2.0-dev gperf
 >apt-get install rsync git subversion mercurial
```

* Ensure bash ist default shell (Debian/Ubuntu standard is dash):

```
  >dpkg-reconfigure dash
```
  and select no.


* Clone the octonet repositories:

```
For master branch:
  >git clone -b master https://github.com/probutus/octonet.git octonet
  >cd octonet  
  >./mk.patch
For new octonet-ng branch:
  >git clone -b octonet-ng https://github.com/probutus/octonet.git octonet
  >cd octonet  
  >./mk.patch

```


###Building

Complete build (needed once)
```
  >./mk.all
```

Rebuild main firmware
```
  >./mk
```

###Installing

* Create a subdirectory octonet on a local webserver, enable directory listing.

```
  >cp buildroot/output-octonet/images/octonet.* <your webserver root>/octonet
```

On some servers a .htaccess file with:
```
Options +Indexes
```
in the octonet directory might be necessary.

* Configure your OctopusNet(s) to use your webserver as update server:
```
http://<OctopusNet IP>/updateserver.html
```
Initiate update from the OctopusNet 

Note 1: I included a python webserver which enables you to update the octopus-net firmware without having a webserver installed. See octoupdateserver directory. Just run it with python3 and have the octonet directory at the same level at the server. (this script needs to be run as root as it needs access to port 80). Please add the filename of the image you want to flash into the script.

Note 2: for security reasons only private ip addresses (10.0.0.0/8, 172.16.0.0/12, 192.168,0.0/16) are accepted


You can find details about the OctopusNet hardware, the flash memory map and the boot process
in dddvb/docs/octopusnet in the dddvb repo!

