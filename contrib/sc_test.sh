#!/bin/bash
#
# sc_test - test a selfcontrol installation from scratch
#           lots of addumptions here.
#

function cleanup {
	rm -f $ipt_new $ipt_test
}
	
function die {
	[ ! -z "$1" ] && echo "$1"
	cleanup
	exit 1
}

[ -z "$1" ] && die "Usage: $0 <username> <package_file>"
SCUSER="$1"; shift

[ -z "$1" ] && die "Usage: $0 <username> <package_file>"
FILE="$1"; shift

PKG=$(basename "$FILE")
PKG=${PKG%%_*}


# Purge package

(dpkg -P "$PKG" >/dev/null 2&>1 || die "NOK: purge failed") |
	fgrep -v 'not empty so not removed'

# Cleanup non package config files

rm -rf /etc/selfcontrol
rm -f /home/$SCUSER/.selfcontrol

# Nuke the iptables config

(
	iptables -F SelfControl
	iptables -D OUTPUT -j SelfControl
	iptables -X SelfControl
) || die "NOK: iptables purge failes"

# Install the new package

dpkg --install "$FILE" >/dev/null || die "NOK: install failed"

# Wait for user to run default config once

echo -n "Please run SelfControl as $SCUSER, (RETURN)"
read junk

# Check that iptables are correct

ipt_test=$(tempfile)
ipt_new=$(tempfile)

cat > $ipt_test <<_EOF_
*filter
:INPUT ACCEPT
:FORWARD ACCEPT
:OUTPUT ACCEPT
:SelfControl -
-A OUTPUT -j SelfControl 
-A SelfControl -d 192.0.32.10/32 -j DROP 
COMMIT
_EOF_

iptables-save | perl -ne '/^#/&&next;s/\s\[.*//;print' > $ipt_new
cmp $ipt_new $ipt_test || die "NOK: iptables mismatch"

# Check user configuration file

[ -f /home/$SCUSER/.selfcontrol ] || die "NOK: no .selfcontrol"

# Get the one created job from config

scjob=$(
	perl -MYAML -e '
	$f = YAML::LoadFile("/home/'$SCUSER'/.selfcontrol");
	@f = keys %{ $f->{jobs} };
	print $f[0];
	')

# Check config job is same at atq job

atjob=$(atq | cut -f1 | fgrep $scjob)
[ $atjob == $scjob ] || die "NOK: atq mismatch"

# All I can think of so far

cleanup
echo "OK"
