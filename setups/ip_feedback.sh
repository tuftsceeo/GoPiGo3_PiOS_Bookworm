#!/bin/bash

# FILE:  ip_feedback.sh
# This script is run once at boot by ip_feedback.service

# Function to convert numbers (0-255) to words
number_to_words() {
    local num=$1
    
    if [ $num -eq 0 ]; then
        echo "zero"
        return
    fi
    
    # Handle hundreds
    local hundreds=$((num / 100))
    local remainder=$((num % 100))
    local result=""
    
    if [ $hundreds -gt 0 ]; then
        case $hundreds in
            1) result="One hundred" ;;
            2) result="Two hundred" ;;
        esac
    fi
    
    # Handle tens and ones
    if [ $remainder -gt 0 ]; then
        if [ $hundreds -gt 0 ]; then
            result="$result "
        fi
        
        if [ $remainder -lt 20 ]; then
            case $remainder in
                1) result="${result}One" ;;
                2) result="${result}Two" ;;
                3) result="${result}Three" ;;
                4) result="${result}Tour" ;;
                5) result="${result}Five" ;;
                6) result="${result}Six" ;;
                7) result="${result}Seven" ;;
                8) result="${result}Eight" ;;
                9) result="${result}Nine" ;;
                10) result="${result}Ten" ;;
                11) result="${result}Eleven" ;;
                12) result="${result}Twelve" ;;
                13) result="${result}Thirteen" ;;
                14) result="${result}Fourteen" ;;
                15) result="${result}Fifteen" ;;
                16) result="${result}Sixteen" ;;
                17) result="${result}Seventeen" ;;
                18) result="${result}Eighteen" ;;
                19) result="${result}Nineteen" ;;
            esac
        else
            local tens=$((remainder / 10))
            local ones=$((remainder % 10))
            
            case $tens in
                2) result="${result}Twenty" ;;
                3) result="${result}Thirty" ;;
                4) result="${result}Forty" ;;
                5) result="${result}Fifty" ;;
                6) result="${result}Sixty" ;;
                7) result="${result}Seventy" ;;
                8) result="${result}Eighty" ;;
                9) result="${result}Ninety" ;;
            esac
            
            if [ $ones -gt 0 ]; then
                case $ones in
                    1) result="${result} One" ;;
                    2) result="${result} Two" ;;
                    3) result="${result} Three" ;;
                    4) result="${result} Four" ;;
                    5) result="${result} Five" ;;
                    6) result="${result} Six" ;;
                    7) result="${result} Seven" ;;
                    8) result="${result} Eight" ;;
                    9) result="${result} Nine" ;;
                esac
            fi
        fi
    fi
    
    echo "$result"
}

# Function to speak IP address with pauses
speak_ip_with_pauses() {
    local ip=$1
    local user=$2
    IFS='.' read -ra OCTETS <<< "$ip"
    
    for i in "${!OCTETS[@]}"; do
        if [ $i -gt 0 ]; then
            sleep 0.1
            su -c "espeak-ng -s 180 -p 70 -g 8 -v mb-us2 'Dot'" $user
            sleep 0.1
        fi
        local octet_words=$(number_to_words ${OCTETS[$i]})
        su -c "espeak-ng -s 180 -p 70 -g 8 -v mb-us2 '$octet_words'" $user
    done
}

echo "Setting volume to 100%"
amixer sset 'Master' 100% &>/dev/null
amixer sset 'Headphone' 100% &>/dev/null  
amixer sset 'PCM' 100% &>/dev/null

echo "starting"
sleep 10
COUNT=0
IPs=$(hostname --all-ip-addresses)
while [ -z "$IPs" ]
do
    echo "loop"
    sleep 1;
    IPs=$(hostname --all-ip-addresses)
    COUNT=$((COUNT+1))
    echo "count: "$COUNT > /home/pi/ipcount
done

echo "done looping "

echo "count: "$COUNT > /home/pi/ipcount

ifconfig wlan0 | grep 'inet ' | awk '{print $2}'  > /home/pi/ip.number
read -r IP_NUMBER < /home/pi/ip.number
echo $IP_NUMBER

# remove previous IP info
sudo rm /boot/*.assigned_ip &>/dev/null
# sudo rm /home/pi/Desktop/*.assigned_ip &>/dev/null

# remove previous Failed IP
FAILED=/home/pi/failedIP
if test -f "$FAILED"; then
    sudo rm $FAILED &>/dev/null
fi
# sudo rm /home/pi/Desktop/failedIP &>/dev/null

for i in $(seq 1 100);
do
	if [ ! -z "$IP_NUMBER" ]
	then
		echo "saving IP info"
		sudo bash -c "echo $IP_NUMBER > /boot/firmware/$IP_NUMBER.assigned_ip"
		echo "IP info saved"

		su -c "espeak-ng -s 180 -p 70 -g 5 -v mb-us2 'WiFi eye pee'" pi
		speak_ip_with_pauses "$IP_NUMBER" "pi"
		su -c "espeak-ng -s 180 -p 70 -g 5 -v mb-us2 'repeating'" pi
		speak_ip_with_pauses "$IP_NUMBER" "pi"
		sleep 1;
	else
		su -c "espeak-ng -s 180 -p 70 -g 5 -v mb-us2 'No IP number'" pi
		echo "no IP number"
		echo "no IP" > /home/pi/failedIP
		sleep 1;

	fi
done

echo "done with IP feedback"
