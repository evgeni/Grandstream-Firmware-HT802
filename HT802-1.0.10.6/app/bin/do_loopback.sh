#!/bin/sh

if [ "$#" -ne 2 ]; then
   echo "Usage: $0 voip/fxs_tx/fxs_rx on/off"
   echo "All lower case"
fi

option1="${1}"
option2="${2}"

case "${option1}" in
     "voip")  echo "VoIP Loopback"
              if [ "${option2}" = "on" ]; then
                ./audiotune -e -i /test/voip_loopback_on.txt
              else
                ./audiotune -e -i /test/voip_loopback_off.txt
              fi
              ;;
       "fxs_tx") echo "FXS TX Loopback" 
              if [ "${option2}" = "on" ]; then
                ./audiotune -e -i /test/fxs_tx_loopback_on.txt
              else
                ./audiotune -e -i /test/fxs_tx_loopback_off.txt
              fi
              ;;
       "fxs_rx") echo "FXS RX Loopback"
              if [ "${option2}" = "on" ]; then
                 ./audiotune -e -i /test/fxs_rx_loopback_on.txt
              else
                 ./audiotune -e -i /test/fxs_rx_loopback_off.txt
              fi
              ;;
esac
