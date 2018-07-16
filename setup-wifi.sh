list_wlan_interfaces() {
  for dir in /sys/class/net/*/wireless; do
    if [ -d "$dir" ]; then
      basename "$(dirname "$dir")"
    fi
  done
}

get_json_string_val() {
  sed -r -n -e "s/^[[:space:]]*$2[[:space:]]*:[[:space:]]*\"(.*)\"[[:space:]]*$/\1/p" $1
}

do_wifi_ssid_passphrase() {
  RET=0
  IFACE_LIST="$(list_wlan_interfaces)"
  IFACE="$(echo "$IFACE_LIST" | head -n 1)"

  if [ -z "$IFACE" ]; then
    return 1
  fi

  if ! wpa_cli -i "$IFACE" status > /dev/null 2>&1; then
    return 1
  fi

  SSID=$(get_json_string_val /boot/net_init.conf ssid)
  PASSPHRASE=$(get_json_string_val /boot/net_init.conf psk)
  KEYMGMT=$(get_json_string_val /boot/net_init.conf key_mgmt)
  PRIORITY=$(get_json_string_val /boot/net_init.conf priority)

  if [ -z "$SSID" ]; then
    return 1
  fi

  local ssid="$(echo "$SSID" \
   | sed 's;\\;\\\\;g' \
   | sed -e 's;\.;\\\.;g' \
         -e 's;\*;\\\*;g' \
         -e 's;\+;\\\+;g' \
         -e 's;\?;\\\?;g' \
         -e 's;\^;\\\^;g' \
         -e 's;\$;\\\$;g' \
         -e 's;\/;\\\/;g' \
         -e 's;\[;\\\[;g' \
         -e 's;\];\\\];g' \
         -e 's;{;\\{;g'   \
         -e 's;};\\};g'   \
         -e 's;(;\\(;g'   \
         -e 's;);\\);g'   \
         -e 's;";\\\\\";g')"

  wpa_cli -i "$IFACE" list_networks \
   | tail -n +2 | cut -f -2 | grep -P "\t$ssid$" | cut -f1 \
   | while read ID; do
    wpa_cli -i "$IFACE" remove_network "$ID" > /dev/null 2>&1
  done

  ID="$(wpa_cli -i "$IFACE" add_network)"
  wpa_cli -i "$IFACE" set_network "$ID" ssid "\"$SSID\"" 2>&1 | grep -q "OK"
  RET=$((RET + $?))

  if [ -z "$PASSPHRASE" ]; then
    wpa_cli -i "$IFACE" set_network "$ID" key_mgmt NONE 2>&1 | grep -q "OK"
    RET=$((RET + $?))
  else
    wpa_cli -i "$IFACE" set_network "$ID" psk "\"$PASSPHRASE\"" 2>&1 | grep -q "OK"
    RET=$((RET + $?))
    if [ -n "$KEYMGMT" ]; then
      wpa_cli -i "$IFACE" set_network "$ID" key_mgmt "$KEYMGMT" 2>&1 | grep -q "OK"
      RET=$((RET + $?))
    fi
  fi

  if [ -n "$PRIORITY" ]; then
    wpa_cli -i "$IFACE" set_network "$ID" priority "$PRIORITY" 2>&1 | grep -q "OK"
    RET=$((RET + $?))
  fi

  if [ $RET -eq 0 ]; then
    wpa_cli -i "$IFACE" enable_network "$ID" > /dev/null 2>&1
  else
    wpa_cli -i "$IFACE" remove_network "$ID" > /dev/null 2>&1
  fi
  wpa_cli -i "$IFACE" save_config > /dev/null 2>&1

  echo "$IFACE_LIST" | while read IFACE; do
    wpa_cli -i "$IFACE" reconfigure > /dev/null 2>&1
  done

  return $RET
}

do_config() {
  [ -e /boot/net_init.conf ] || return 0
  do_wifi_ssid_passphrase
  NEW_HOSTNAME=$(get_json_string_val /boot/net_init.conf hostname)
  mv /boot/net_init.conf /boot/_net_init.conf
  if [ -n "$NEW_HOSTNAME" ]; then
    CURRENT_HOSTNAME=`cat /etc/hostname | tr -d " \t\n\r"`
    echo $NEW_HOSTNAME > /etc/hostname
    sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts
    reboot
  fi 
}

do_config
