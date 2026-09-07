#!/bin/bash

# test
# Copyright (c) 2021, Internet Corporation for Assigned Names and Numbers

# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
# BLAME: 2021 Mauricio Vergara Ereche <mauricio.vergara@icann.org>

# DESC:
# This script restores a backup previously made with backup-hsm-opendnssec.sh
# Assumes OpenDNSSEC 1.4, MySQL and Thales HSM
#

export PATH="/bin:/usr/bin:/usr/sbin:"

# Run as root
if [ $EUID -ne 0 ] ; then
   echo "$0 must be run as root"
   exit 1
fi

# FORCE bit rewrites everything without ask. Default=0 (means: require human intervention)
if [ -z ${FORCE} ] ; then
	FORCE=0
fi

# Warning message
if [ ${FORCE} -eq 0 ] ; then
	echo "#################"
	echo "#### WARNING ####"
	echo "#################"
	echo "#"
	echo "# This script will restore a backed up version of signed OpenDNSSEC zones along with its security world"
	echo "# You may lose all the crypto information of your DNS zones and their states"
	echo "# It's your responsibility to backup any previous data that might be lost"
	echo
	#read -n 1 -s -r -p "Press any key to continue"
	echo
	echo
fi

if [ -z $1 ] || [ ! -e $1 ] ; then
	echo "ERROR: $0 <FILE>"
	exit 1
else
	TARBALL=$(readlink -e $1)				# tarball source file (created from backup-hsm-opendnssec.sh)
fi

## Shutting down puppet on all the GSI-signer infrastructure
echo "# You should manually disable puppet on all the other GSI-signer servers:"
echo "# HINT:"
for IP in 192.168.10{0,1}.16{5,6,7,8}; do
    echo "   ssh ${IP} 'puppet agent --disable'"
done
read -n 1 -s -r -p "Press any key to continue"
echo

## Extracting tarball
cd /tmp
echo
echo "# Extracting backup restore tarball ($1) data into /tmp..."
echo
BackupDIR="$(tar jtvf ${TARBALL} --exclude="*/*" | head -n 1 | awk '{print $6}')"
tar jxf ${TARBALL}
cd ${BackupDIR}
DATE=$(echo $BackupDIR| cut -d "-" -f1,2,3,4)

## Shutting down OpenDNSSEC
echo
echo "# OpenDNSSEC: Shutting down OpenDNSSEC..."
echo
ods-control stop
ps -axfu| grep -q "[o]ds-"
if [ $? -eq 1 ] ; then
	echo "# WARNING: Couldn't shutdown OpenDNSSEC engine, please shut down manually"
	echo
	read -n 1 -s -r -p "Press any key to continue"
fi

## Shutting down Thales HSM
echo
echo "# Thales: Shutting down Thales HSM daemon..."
echo
/opt/nfast/sbin/init.d-ncipher stop
pstree nfast &>/dev/null
if [ $? -eq 0 ] ; then
	echo "# WARNING: Couldn't shutdown nfast HSM engine, please shut down manually"
	echo
	read -n 1 -s -r -p "Press any key to continue"
fi

# Re-importing DB
if [ ${FORCE} -eq 0 ] ; then
	echo "# Re-write kasp DB? (THIS WILL DESTROY THE OLD kasp MySQL DATABASE)"
	select yn in yes no ; do
		case ${yn} in
			yes )
				echo
				echo "# MySQL: Dropping old kasp DB..." ;
				mysqladmin drop kasp --force
				echo "# MySQL: importing kasp DB..." ;
				mysqladmin create kasp
				mysql kasp < kasp-${DATE}.sql ;
				break ;;
			no ) echo " We didn't rewrite kasp DB." ; break ;;
		esac
	done
elif [ ${FORCE} -eq 1 ] ; then
	echo
	echo "# MySQL: Removing old kasp DB..."
	mysqladmin drop kasp --force
	echo "# MySQL: Importing kasp DB..."
	mysqladmin create kasp
	mysql kasp < kasp-${DATE}.sql
fi

# Rewriting HSM Security World
BACKUPKEYSDIR="/opt/nfast/kmdata/local.$(date +%F).backup"
if [ ${FORCE} -eq 0 ] ; then
	echo
	echo "# Re-write Thales soft HSM Security World? (THIS IS DANGEROUS, USE WISELY)"
	select yn in yes no ; do
		case ${yn} in
			yes )
				echo
				echo "# Thales: Backing up old Security World keys into ${BACKUPKEYSDIR}"
				mkdir -p ${BACKUPKEYSDIR}
				mv /opt/nfast/kmdata/local/key_pkcs11* /opt/nfast/kmdata/local.$(date +%F).backup/
				echo "# Thales: Rewritting HSM Security World..." ;
				rsync -apr kmdata/local /opt/nfast/kmdata ;
				break ;;
			no )
				echo "# Thales SecurityWorld: We didn't rewrite HSM Security World" ;
				break ;;
		esac
	done
elif [ ${FORCE} -eq 1 ] ; then
	echo
	echo "# Thales: Backing up old Security World keys into ${BACKUPKEYSDIR}"
	mkdir ${BACKUPKEYSDIR}
	mv /opt/nfast/kmdata/local/key_pkcs11* /opt/nfast/kmdata/local.$(date +%F).backup/
	echo "# Thales: Rewritting HSM Security World..."
	rsync -apr kmdata/local /opt/nfast/kmdata
fi

# Rewritting temp OpenDNSSEC files
if [ ${FORCE} -eq 0 ] ; then
   echo
   echo "# Re-write OpenDNSSEC config for each zone (DNSSEC policies) files in /var/lib/opendnssec/signconf?"
	select yn in yes no ; do
		case ${yn} in
			yes )
				echo
				echo "# OpenDNSSEC: Removing temp files that are not longer useful..."
				rm -rf /var/lib/opendnssec/tmp/*
				echo "# OpenDNSSEC: Restoring the signconf for each zone..."
				rm -rf /var/lib/opendnssec/signconf/*
				rsync -apr opendnssec/signconf /var/lib/opendnssec/
				break ;;
			no ) echo "# OpenDNSSEC: We didn't rewrite OpenDNSSEC temp files" ; break ;;
		esac
	done
elif [ ${FORCE} -eq 1 ] ; then
	echo
	echo "# OpenDNSSEC: Removing temp files that are not useful..."
	rm -rf /var/lib/opendnssec/tmp/*
	echo "# OpenDNSSEC: Restoring the signconf for each zone..."
	rm -rf /var/lib/opendnssec/signconf/*
	rsync -apr opendnssec/signconf /var/lib/opendnssec/
fi

######## NOW WE BRING EVERYTHING BACK UP
# Turn on Thales HSM
echo
echo "# Thales: Starting Thales HSM (nCipher) daemon..."
/opt/nfast/sbin/init.d-ncipher start
if [ $? -ne 0 ] ; then
	echo "# WARNING: HSM didn't come back correctly. Please start service manually"
	exit 1
fi
echo

# Prepare OpenDNSSEC
echo "# Thales: Log-in back OpenDNSSEC with the HSM"
ods-hsmutil login

# Bring OpenDNSSEC back on
#if [ ${FORCE} -eq 0 ] ; then
#	echo
#	echo "# OpenDNSSEC: Turn on OpenDNSSEC service (ods-signer and ods-enforcerd)?"
#	select yn in yes no ; do
#		case ${yn} in
#			yes )
#				echo
#				echo "# Starting OpenDNSSEC..."
#				ods-control start # Run twice... many times enforcer doesn't start right away.
#				ods-control start
#				if [ $? -ne 0 ] ; then
#					echo "# WARNING: OpenDNSSEC didn't start. Please start service manually"
#					read -n 1 -s -r -p "Press any key to continue"
#				fi
#				break ;;
#			no ) echo "# OpenDNSSEC: We didn't start OpenDNSSEC" ; break ;;
#		esac
#	done
#	echo
#elif [ ${FORCE} -eq 1 ] ; then
#	echo
#	echo "# OpenDNSSEC: Starting OpenDNSSEC..."
#	ods-control start # Run twice... many times enforcer doesn't start right away.
#	ods-control start
#	if [ $? -ne 0 ] ; then
#		echo "# WARNING: OpenDNSSEC didn't start. Please start service manually"
#		exit 1
#	fi
#	echo
#fi

# Force re-sign of zones.
#if [ ${FORCE} -eq 0 ] ; then
#	echo "# OpenDNSSEC: Do I force re-sign of every domain/zone?"
#	echo "#   (NOTE: Try to avoid this. It's better to do it via a 'bump' of every zone in the Zone Authoring side (zonedit, RDNS, etc)"
#	select yn in yes no ; do
#		case ${yn} in
#			yes )
#				echo "# OpenDNSSEC: Forcing re-sign zones (via XFR retransfer)..."
#				contz=1
#				for DOM in /var/lib/opendnssec/signconf/*.xml; do
#					totalz=$(ls /var/lib/opendnssec/signconf/*.xml | wc -l)
#					realDOM="$(basename ${DOM}|rev|cut -c 5-|rev)"
#					echo "# signing ${contz}/${totalz} ..."
#					ods-signer retransfer ${realDOM}
#					sleep 0.5
#					contz=$((contz+1))
#				done
#				break ;;
#			no ) echo "# OpenDNSSEC: We didn't force-resign" ; break ;;
#		esac
#	done
#elif [ ${FORCE} -eq 1 ] ; then
#	echo "# OpenDNSSEC: Forcing re-sign zones..."
#	for DOM in /var/lib/opendnssec/signconf/*.xml; do
#		realDOM="$(basename ${DOM}|rev|cut -c 5-|rev)"
#		ods-force-resign ${realDOM}
#	done
#fi

echo
echo "################"
echo "# Final notes: #"
echo "################"
echo "# 0. OpenDNSSEC has NOT been restarted. Allow it to run from puppet once the restore is complete."
echo "# 1. Watch closely /var/log/syslog"
echo "     - HINT 1: If /CRITICAL/ message appears, something is very-broken (Check also in Zabbix)"
echo "     - HINT 2: If restore has been done with recent material, there should minimal DNSKEY creations. If there are lots, something is VERY broken"
echo "# 2. Two pseudo-backups are still on the system if you need to rollback:"
echo "#    - ${BACKUPKEYSDIR}"
echo "#    - /tmp/${BackupDIR}"
echo "# 3. Check that all the gsi-distribution servers are in sync (HINT: BIND can get stuck with too many TCP xfr connections)"
echo '#    - Use from your laptop (outside GSI infra) the script check-gsi-signer.sh <$ZONE>'
echo "#"
echo