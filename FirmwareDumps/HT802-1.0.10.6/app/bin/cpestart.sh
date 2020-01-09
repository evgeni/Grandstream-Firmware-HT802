#!/bin/sh

#Judge whether start gs_cpe or not
#if [ "`nvram get 1409`" != "1" ]
#if [ -z ${ACS_SERVER} ]
#then
#    echo "No ACS Server..."
#    exit 0
#fi


if [ -r /tmp/.cpe_factoryreset ];then
   return 0
fi

ACS_SERVER="`nvram get 4503`"
DHCP_ACS_SERVER="`nvram get ACSURL`"
ENABLE_ACS_SERVER="`nvram get 1409`"
IP_PROTOCOL="`nvram get 1415`"

# max allowable memory usage for gs_cpe
GS_CPE_MAX_MEM_USAGE_KB=4096

cpe_paramater_init()
{
    #Set CPE info
    str=`nvram get :vendor_name` && str=` echo $str| tr '[a-z]' '[A-Z]' `
    nvram set :oem_name=$str
    nvram set :manufacturer=$str
    nvram set :max_sip_profile_count=2
    nvram set :max_line_count=2
    nvram set :max_session_per_line=2
    nvram set :max_session_count=2
    nvram set :max_fxo_count=0
    nvram set :max_fxs_count=2
    nvram set :need_map="false"
    nvram set :need_line_map="false"
    nvram set :prod_class="`cat /proc/gxp/dev_info/dev_alias`"

    nvram set :device_id="`cat /proc/gxp/dev_info/dev_id`"
    nvram set :prod_model="`cat /proc/gxp/dev_info/dev_alias`"
    nvram set :max_skype_profile_count=0
    nvram set :max_linekey_count=0
    nvram set :max_multikey_count=0
    nvram set :ext_board_num=0
    nvram set :max_ext_multikey_count=0
    nvram set :hw_ver="`cat /proc/gxp/dev_info/dev_rev`"
    #nvram set :serial_number="`cat /proc/gxp/dev_info/dev_mac | awk -F: '{print $1 $2 $3 $4 $5 $6}'`"
    nvram set :serial_number="`cat /proc/gxp/dev_info/security/sn`"
    nvram set :oem_oui="000B82"
    nvram set :max_vpk_count=0
    # Bug 73678
    model="`nvram get :prod_model`"
    if [ $model = "HT801" ]; then
        nvram set :max_sip_profile_count=1
        nvram set :max_line_count=1
        nvram set :max_fxs_count=1
    elif [ $model = "HT814" ]; then
        nvram set :max_line_count=4
        nvram set :max_fxs_count=4
        nvram set :need_map="true"
    elif [ $model = "HT812" ]; then
    # Bug 116859 for telefonica
        nvram set :need_map="true"
    fi

    # Bug 116852/116859
    oemId="`nvram get :oem_id`"
    if [ $oemId = "73" ]; then
        nvram set :max_sip_profile_count=1
        if [ $model = "HT812" -o $model = "HT814" -o $model = "HT818" ]; then
            nvram set :need_line_map="true"
        fi
    fi

    nvram commit
}

cpe_memory_init()
{
    GS_CPE_MEM_MAX="`nvram get gs_cpe_max_mem`"
    # Limit the run time memory usage of the gs_cpe if configured
    if [ ! -z ${GS_CPE_MEM_MAX} ]; then
        # different mem limit options
        if [ ${GS_CPE_MEM_MAX} = 1 ]; then
            GS_CPE_MEM_LIMIT=1024
        elif [ ${GS_CPE_MEM_MAX} = 2 ]; then
            GS_CPE_MEM_LIMIT=2048
        elif [ ${GS_CPE_MEM_MAX} = 3 ]; then
            GS_CPE_MEM_LIMIT=3072
        else
            GS_CPE_MEM_LIMIT=${GS_CPE_MAX_MEM_USAGE_KB}
        fi

        echo "cpestart.sh: Starting gs_cpe with limited runtime memory of ${GS_CPE_MEM_LIMIT}kb..."
        ulimit -v ${GS_CPE_MEM_LIMIT}
    else
        echo "cpestart.sh: Starting gs_cpe..."
    fi
}

#if [ "x${ENABLE_ACS_SERVER}" = "x0" ]; then
#    echo "cpestart.sh: gs_cpe is disabled"
#    exit
#fi

#ps | grep gs_cpe | grep -v grep
#if [ $? -eq 0 ]; then
#    echo "cpestart.sh: gs_cpe is already running"
#    exit
#fi

# Run gs_cpe only if TR069 is enabled
if [ "x${ENABLE_ACS_SERVER}" = "x1" ]; then
#    echo "cpestart.sh: ACS is Enabled..." >> /tmp/cpestart.log
    if [ -n "`ps | grep -v 'grep' | grep 'gs_cpe'`" ]; then
        echo "cpestart.sh: gs_cpe is already running, kill it first..."
        killall gs_cpe 2>/dev/null
    fi
    # Always enable core dump for gs_cpe
    ulimit -c unlimited
    # set some Pvalues for CPE
    cpe_paramater_init

    # set timeout waiting for network
    TIME_OUT=30
    while [ ${TIME_OUT} -gt 0 ]
    do
        # Bug 33027 check network
        # IP_PROTOCOL = 0 (both, prefer IPv4); 1 (both, prefer IPv6); 2 (IPv4 only); 3 (IPv6 only)
        #if [ "x${IP_PROTOCOL}" = "x3" ]; then
            # IPv6 only, try to find the line containing IPv6 address
        #    inet=`/sbin/ifconfig |grep "inet"|sed '/127.0.0.1/ d'|sed '/fe80/ d'|sed '/Scope:Host/ d'|sed '/169.254.1./ d'`
        #else
        #    inet=`/sbin/ifconfig |grep "inet"|sed '/127.0.0.1/ d'|sed '/inet6/ d'|sed '/169.254.1./ d'`
        #fi
 
        inet=`/sbin/ifconfig |grep "inet"|sed '/127.0.0.1/ d'|sed '/inet6/ d'|sed '/169.254.1./ d'`
        if [ -z "${inet}" ]
        then
            inet=`/sbin/ifconfig |grep "inet"|sed '/127.0.0.1/ d'|sed '/fe80/ d'|sed '/Scope:Host/ d'|sed '/169.254.1./ d'`
		fi

        if [ ! -z "${inet}" ]
        then
            # network is up, break out of the loop to start gs_cpe
            break;
        fi

        # Bug 63473. network is not up, wait 2 seconds, then check network again
        sleep 2
        TIME_OUT=$((TIME_OUT-2))
        echo "cpestart.sh: Waiting for network, TIME_OUT = ${TIME_OUT} sec..."
    done
    #
    # starting gs_cpe, regardless of the network status (Bug 63473)
    cpe_memory_init

    /app/bin/gs_cpe &
    sleep 1
    break;
else
    # TR069 is disabled
    if [ -n "`ps | grep -v 'grep' | grep 'gs_cpe'`" ]; then
        killall gs_cpe 2>/dev/null
        echo "cpestart.sh: TR069 is disabled...gs_cpe killed."
    else
        echo "cpestart.sh: TR069 is disabled...gs_cpe Not Started."
    fi
    nvram set :cpe_running=0
    nvram commit
fi
