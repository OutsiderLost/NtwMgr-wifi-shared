# NtwMgr-wifi-shared.sh
NetworkManager wifi hotspot automatization script (required two adapters).
==========================================================================
(--help, -h)
use predefined -> ./NtwMgr-wifi-shared.sh <iface> <ESSID> <PSK>
use autorunner -> ./NtwMgr-wifi-shared.sh <ESSID> <PSK>"
use autorunner -> ./NtwMgr-wifi-shared.sh"

(More input options!)
--------------------------------------------------------------------------

Considering several things -> is the adapter used more than once, is the basic setting normal, etc...

Required two adapters -> I couldn't split the card with nmcli, it doesn't work well with iw! So both are mandatory, or use wpa_supplicant..!

