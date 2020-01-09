# busybox may slow on [ ]
empty() {
	case "${1}" in
		"") return 0 ;;
		*) return 255 ;;
	esac
}
equal() {
	case "${1}" in
		"${2}") return 0 ;;
		*) return 255 ;;
	esac
}
neq() {
	case "${1}" in
		"${2}") return 255 ;;
		*) return 0 ;;
	esac
}
get_pvalue_conf() {
    SRC_CONF="/conf/rc.conf"
    DST_CONF="/tmp/config/rc.conf"
    local _name="${1}"
    local _default="${2}"
    local _value=""
    if test -r ${SRC_CONF} -a -r ${DST_CONF}; then
        local name_pvalue="`cat ${SRC_CONF} | grep " ${_name} " | awk -F'=' '{print $1}' | awk '{print $2}'`"
        if test -n "${name_pvalue}"; then
            local line_no="`cat ${DST_CONF} | grep -n "${name_pvalue}=" | sed -n '1p' | awk -F':' '{print $1}'`"
            if test -n "${line_no}"; then
                local name_pvalue_flag="`cat ${DST_CONF} | grep "${name_pvalue}=" | awk -F"'" '{print $2}'`"
                if test -n "${name_pvalue_flag}";then
                    _value="`sed -n "/"${name_pvalue}="/,/"${name_pvalue_flag}"/p" ${DST_CONF} | sed '1d' | sed '$d'`"
                fi
            fi
        fi
    fi
    if test -z "${_value}"; then
        _value="`nvram get ${_name}`"
    fi
    if ! empty "${_value}"; then
        echo "${_value}"
    else
        if ! empty "${_default}"; then
            echo "${_default}"
        fi
    fi
}
check_timestamp() {
    local TIMEOUT="`get_pvalue_conf 28116 10`"
    if empty "${TIMEOUT}"; then
        TIMEOUT=600
    else
        TIMEOUT=$(expr ${TIMEOUT} \* 60)
    fi
    _checkpoint=$((${1} + ${TIMEOUT}))
    _now="`date +%s`"
    [ ${_now} -gt ${_checkpoint} ] || return 255
    return 0
}
check_user() {
    if neq ${1} "config2" && neq ${1} "gr909" && neq ${1} "test_started" && neq "`nvram get session_user`" "admin"; then
        echo ${1}
        return 0
    fi
    return 255
}
get_system_status() {
    WAN=`nvram get wan_device`
    WAN_IF=`nvram get wan_if`
    if equal `nvram get 231` 1; then
        # Bug 90573/105414
        nvram set :67="`ifconfig ${WAN_IF} 2> /dev/null |grep ${WAN_IF} |cut -d \" \" -f11`"
    else
        nvram set :67="WAN-- `ifconfig eth1|grep eth1 |cut -d \" \" -f11` &nbsp;&nbsp;&nbsp;&nbsp LAN-- `ifconfig eth0|grep eth0 |cut -d \" \" -f11`&nbsp(<B>Device
 MAC</B>)"
    fi
    nvram set :121="`ifconfig ${WAN} 2>/dev/null|grep \"inet addr\"|cut -d \" \" -f12|cut -d \":\" -f2`"
    # Bug 90573
    nvram set :ipv6_addr="`ifconfig ${WAN_IF} 2> /dev/null |grep "inet6 addr"|sed '/127.0.0.1/ d'|sed '/fe80/ d'|sed '/Scope:Host/ d'|sed '/169.254.1./ d'|cut -d ':' -f2-9|cut -d '/' -f1|cut -d ' ' -f2`"
    nvram set :199="`TZ="$(cat /etc/TZ)" uptime|cut -d ',' -f1`"
    nvram set :serial_number="`cat /proc/gxp/dev_info/security/sn 2>/dev/null`"
}
check_lang() {
	if neq $(nvram get 342) $(nvram get 342a); then
		/app/bin/lang
	fi
}

header() {
cat <<EOF
HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8
Server: Grandstream/1.10


EOF
}

header_binary() {
filename="config.txt"
if [ "x${1}" != "x" ] ; then
    filename="${1}"
fi
cat <<EOF
HTTP/1.1 200 OK
Content-Type: application/octet-stream
Content-Disposition: attachment; filename="${filename}"
Server: Grandstream/1.10

EOF
}

header_text() {
cat <<EOF
Content-Type: text/html; charset=utf-8
Pragma: no-cache


EOF
}

header_with_cookie() {
cat <<EOF
HTTP/1.0 200 OK
Content-Type: text/html; charset=utf-8
Server: Grandstream/1.10
Pragma: no-cache
Cache-Control: no-cache
Connection: close
Set-Cookie: session_id=${SESSIONID};


EOF
}

print_error_page(){
local _product_year="`ls -le /sbin/gs_config | awk '{print $10}'`"
cat << EOF
<html>
<head>
<title>Grandstream Device Configuration</title>
<style type="text/css">
<!--
.l{  font-family: Tahoma; font-size: 10pt; color: #000000; }
a.l:Hover{  font-family: Tahoma; font-size: 10pt; color: #ffffff; }
-->
</style></head><body bgcolor="#CCCCCC">
<form name="rs_form" action="rs" method="post" autocomplete="off">
<input name="session_token" type=hidden value="`nvram get session_token`">
<table width="870" border="1" align="center" cellpadding="0" cellspacing="0" bordercolor="#336699">
<tr><td valign="top"><table width="100%" border="0" align="center" cellpadding="0" cellspacing="0">
<tr><td height="48" valign="middle" bgcolor="#F3C47C" class="l" align="center"><strong><font color="#336699" size="3"><b>Grandstream Device Configuration</b></font></strong></td>
</tr><tr><td height="20" valign="top" background="/backline.gif" bgcolor="#F3C47C" align="center">
<table width="70%" cellpadding="0" cellspacing="0">
<tr><td bgcolor="#999999" align="center"><a href="index" class="l"><b>STATUS</b></a></td>
<td bgcolor="#999999" align="center"><a href="config2" class="l"><b>BASIC SETTINGS</b></a></td>
<td bgcolor="#999999" align="center"><a href="config" class="l"><b>ADVANCED SETTINGS</b></a></td>
</tr></table></td></tr>
        <tr bgcolor="#FFFFCC">
          <td> <table width=100% border=0 cellspacing=1 cellpadding=2>
              <tr>
                <td> <table width=500 border=0 cellspacing=5 cellpadding=0 align=center bgcolor="ffffcc">
                    <tr bordercolor="ffffff" bgcolor="ffffff">
                      <td align=center bgcolor="ffffcc" height=69> <br> <br>
                        An error has occurred.<br>
                        <br> <br> </td>
                    </tr>
                  </table></td>
              </tr>
              <tr>
                <td>&nbsp;</td>
                <td>&nbsp;</td>
              </tr>
              <tr height=28 bgcolor="#F3C47C" align=center>
                <td colspan=2>
                  <input type="submit" name="reboot" value="Reboot">
                  <input name="gnkey" type=hidden value=0b82> </td>
              </tr>
            </table></td>
        </tr>
<tr><td bgcolor="#336699" align="center" class="l"><font size="1">All Rights Reserved Grandstream Networks, Inc. 2006-${_product_year}</font></td></tr>
</table></td></tr>
</table></form>
</body></html>
EOF
}

print_error_page_without_links(){
local _product_year="`ls -le /sbin/gs_config | awk '{print $10}'`"
cat << EOF
<html>
<head>
<title>Grandstream Device Configuration</title>
<style type="text/css">
<!--
.l{  font-family: Tahoma; font-size: 10pt; color: #000000; }
a.l:Hover{  font-family: Tahoma; font-size: 10pt; color: #ffffff; }
-->
</style></head><body bgcolor="#CCCCCC">
<table width="870" border="1" align="center" cellpadding="0" cellspacing="0" bordercolor="#336699">
<tr><td valign="top"><table width="100%" border="0" align="center" cellpadding="0" cellspacing="0">
<tr><td height="48" valign="middle" bgcolor="#F3C47C" class="l" align="center"><strong><font color="#336699" size="3"><b>Grandstream Device Configuration</b></font></strong></td>
</tr><tr><td height="20" valign="top" background="/backline.gif" bgcolor="#F3C47C" align="center">
        <tr bgcolor="#FFFFCC">
          <td> <table width=100% border=0 cellspacing=1 cellpadding=2>
              <tr>
                <td> <table width=500 border=0 cellspacing=5 cellpadding=0 align=center bgcolor="ffffcc">
                    <tr bordercolor="ffffff" bgcolor="ffffff">
                      <td align=center bgcolor="ffffcc" height=69> <br> <br>
                        An error has occurred.<br>
                        <br> <br> </td>
                    </tr>
                  </table></td>
              </tr>
            </table></td>
        </tr>
<tr><td bgcolor="#336699" align="center" class="l"><font size="1">All Rights Reserved Grandstream Networks, Inc. 2006-${_product_year}</font></td></tr>
</table></td></tr>
</table>
</body></html>
EOF
}

nvparse_html_check(){
PS=`nvparse ${1}` 2> /dev/null
echo ${PS} | grep '/html' > /dev/null
if [ $? -eq 0 ] ; then
	echo ${PS}
else
	${2}
fi
}

nvparse1_html_check(){
PS=`nvparse1 ${1}` 2> /dev/null
echo ${PS} | grep '/html' > /dev/null
if [ $? -eq 0 ] ; then
	echo ${PS}
else
	${2}
fi
}

access_level(){
_admin_password="`get_pvalue_conf 2 admin`"
_user_password="`get_pvalue_conf 196 123`"
_viewer_password="`get_pvalue_conf 28113 viewer`"
radius_error_action="`get_pvalue_conf 28114 1`"
allow_local_auth=1
if empty "${_admin_password}"; then
	_admin_password="admin"
fi
if empty "${_user_password}"; then
	_user_password="123"
fi
if empty "${_viewer_password}"; then
	_viewer_password="viewer"
fi

[ -z "${radius_error_action}" ] && radius_error_action=0
RADIUSAUTH="`/etc/init.d/radiusclient "${1}" "${2}"`"
case "${RADIUSAUTH}" in
    Invalid )
        allow_local_auth=1
        ;;
    Disabled )
        allow_local_auth=1
        ;;
    Timeout | UnknownLevel )
        if [ ${radius_error_action} -eq 0 ]; then
            echo "no_access_level"
            allow_local_auth=0
        else
            allow_local_auth=1
        fi
        ;;
    Rejected )
        echo "no_access_level"
        allow_local_auth=0
        ;;
    Authorized )
        allow_local_auth=0
        AUTHSESSION="`nvram get :session_user`"
        case "${AUTHSESSION}" in
            admin )
                echo "admin_level"
                ;;
            user )
                echo "user_level"
                ;;
            viewer )
                echo "viewer_level"
                ;;
            * )
                echo "no_access_level"
                ;;
        esac
        ;;
    Error )
        echo "no_access_level"
        allow_local_auth=0
        ;;
    "" | * )
        echo "no_access_level"
        allow_local_auth=0
        ;;
esac
if [ ${allow_local_auth} -ne 1 ];then
    return
fi

case "${1}" in
    admin )
        if equal "${_admin_password}" "${2}" ; then
            nvram set :session_user="admin"
            nvram set username="admin"
            echo "admin_level"
        else
            echo "no_access_level"
        fi
        ;;
    user )
        if equal "${_user_password}" "${2}" ; then
            nvram set :session_user="user"
            nvram set username="user"
            echo "user_level"
        else
            echo "no_access_level"
        fi
        ;;
    viewer )
        if equal "${_viewer_password}" "${2}" ; then
            nvram set :session_user="viewer"
            nvram set username="viewer"
            echo "viewer_level"
        else
            echo "no_access_level"
        fi
        ;;
    "" | * )
        nvram unset :session_user
        nvram set username="admin"
        echo "no_access_level"
        ;;
esac
}

generate_session_token()
{
    _session_token="`dd if=/dev/urandom bs=16 count=1 2>/dev/null | hexdump | head -1 | cut -d' ' -f2- | sed "s/ //g"`"
    _session_token_time="`date +%s`"
    nvram set :session_token="${_session_token}"
    nvram set :session_token_time="${_session_token_time}"
}

check_session_token_time()
{
    _session_token_time="`nvram get session_token_time`"
     [ -z "${_session_token_time}" ] && return 0
    _session_token_time=$((${_session_token_time} + 600))
    _now="`date +%s`"
    if [ ${_now} -gt ${_session_token_time} ];then
        generate_session_token
        return 0
    fi
    return 255
}

get_pvalue()
{
    local _name="${1}"
    local _default="${2}"
    local _value="`nvram get ${_name}`"
    if ! empty "${_value}"; then
        echo "${_value}"
    else
        if ! empty "${_default}"; then
            echo "${_default}"
        fi
    fi
}

check_web_access_attempts()
{
    local _access_attempts="${1}"
    local _invalid_attempts="${2}"
    [ -z "${_access_attempts}" ] && _access_attempts=5
    [ -z "${_invalid_attempts}" ] && _invalid_attempts=0
    [ ${_access_attempts} -eq 0 ] && return 255
    [ ${_invalid_attempts} -ge ${_access_attempts} ] && return 0
    return 255
}

get_web_remain_attempts()
{
    local _access_attempts="${1}"
    local _invalid_attempts="${2}"
    local _remain=0
    [ -z "${_access_attempts}" ] && _access_attempts=5
    [ -z "${_invalid_attempts}" ] && _invalid_attempts=0
    _remain="$(expr ${_access_attempts} - ${_invalid_attempts})"
    echo ${_remain}
}

check_web_lock_duration()
{
    local _lockout="${1}"
    local _last_attempt="${2}"
    [ -z "${_lockout}" ] && _lockout=10
    [ -z "${_last_attempt}" ] && _last_attempt=0
    _lockout="`expr ${_lockout} \* 60`"
    _now="`date +%s`"
    _checkpoint="`expr ${_last_attempt} + ${_lockout}`"
    [ ${_now} -lt ${_checkpoint} ] && return 0
    return 255
}

get_web_remain_duration()
{
    local _lockout="${1}"
    local _last_attempt="${2}"
    local _remain=0
    [ -z "${_lockout}" ] && _lockout=10
    [ -z "${_last_attempt}" ] && _last_attempt=0
    _lockout="`expr ${_lockout} \* 60`"
    _now="`date +%s`"
    _checkpoint="`expr ${_last_attempt} + ${_lockout}`"
    _remain="`expr ${_checkpoint} - ${_now}`"
    echo ${_remain}
}
