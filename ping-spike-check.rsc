#######################################
#      -PING SPIKE CHECK SCRIPT-      #
#              by MAZNET              #
#               v1.2.0                #
#           mikrotik script           #
#######################################

#:log info ""
#:delay 1;
#:log info ">>> [PING SPIKE CHECK SCRIPT] v1.2.0 - by Maznet <<<"
#:delay 1;
#:log info ""

#######################
#   ZMIENNE SKRYPTU   #
#######################
:global lastpingspike
:global pingstatus
:local pingtest1
:local pingtest2
:local pingtest3
:local pingtest4
:local pingtest5
:local flag 0

#|-------------------------------|
#|     USTAWIENIA SPRAWDZANIA    |
#|-------------------------------|
:local address "1.1.1.1"
:local address2 "8.8.8.8"
:local maxspike 50

###################
#   KOD SKRYPTU   #
###################

:local pingresult1 ([ping $address count=1 as-value]->"time")
:local pingtest1 [:tonum ([:pick $pingresult1 7] . [:pick $pingresult1 9 12])]

:local pingresult2 ([ping $address2 count=1 as-value]->"time")
:local pingtest2 [:tonum ([:pick $pingresult2 7] . [:pick $pingresult2 9 12])]

:local pingresult3 ([ping $address count=1 as-value]->"time")
:local pingtest3 [:tonum ([:pick $pingresult3 7] . [:pick $pingresult3 9 12])]

:local pingresult4 ([ping $address2 count=1 as-value]->"time")
:local pingtest4 [:tonum ([:pick $pingresult4 7] . [:pick $pingresult4 9 12])]

:local pingresult5 ([ping $address count=1 as-value]->"time")
:local pingtest5 [:tonum ([:pick $pingresult5 7] . [:pick $pingresult5 9 12])]

:local pingresult6 ([ping $address2 count=1 as-value]->"time")
:local pingtest6 [:tonum ([:pick $pingresult6 7] . [:pick $pingresult6 9 12])]

if ([:len $pingtest1] = 0) do={
    :set pingtest1 "999"
    :set flag ($flag + 1)
} else={
    if ($pingtest1 > $maxspike ) do={
    :set flag ($flag + 1)
    }
}

if ([:len $pingtest2] = 0) do={
    :set pingtest2 "999"
    :set flag ($flag + 1)
} else={
    if ($pingtest2 > $maxspike ) do={
        :set flag ($flag + 1)
    }
}

if ([:len $pingtest3] = 0) do={
    :set pingtest3 "999"
    :set flag ($flag + 1)
} else={
    if ($pingtest3 > $maxspike ) do={
        :set flag ($flag + 1)
    }
}

if ([:len $pingtest4] = 0) do={
    :set pingtest4 "999"
    :set flag ($flag + 1)
} else={
    if ($pingtest4 > $maxspike ) do={
        :set flag ($flag + 1)
    }
}

if ([:len $pingtest5] = 0) do={
    :set pingtest5 "999"
    :set flag ($flag + 1)
} else={
    if ($pingtest5 > $maxspike ) do={
        :set flag ($flag + 1)
    }
}

if ([:len $pingtest6] = 0) do={
    :set pingtest6 "999"
    :set flag ($flag + 1)
} else={
    if ($pingtest6 > $maxspike ) do={
        :set flag ($flag + 1)
    }
}

:local pingaverage ((($pingtest1 + $pingtest2 + $pingtest3 + $pingtest4 + $pingtest5 + $pingtest6) / 6))
:set pingstatus ($pingaverage . " ms")

if ($flag > 3 ) do={
    :log warning "[PING SPIKE CHECK] Wykryto fluktuacje lacza!"
    delay 1;
    :log warning ("[PING SPIKE CHECK] " . $pingtest1 . "ms | " . $pingtest2 . "ms | " . $pingtest3 . "ms | " . $pingtest4 . "ms | " . $pingtest5 . "ms | " . $pingtest6 . "ms")
    :set lastpingspike ([/system clock get date] . " (" . [/system clock get time] . ")")
}