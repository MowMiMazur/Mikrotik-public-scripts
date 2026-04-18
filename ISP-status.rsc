#####################################
#        -ISP STATUS SCRIPT-        #
#             by MAZNET             #
#              v1.6.0               #
#          mikrotik script          #
#####################################

:local Prefix "[ISP STATUS]"
:local ScriptVerInfo ">>> [ISP STATUS SCRIPT] v1.6.0 - by Maznet <<<"
:local ScriptVerMail "#             v1.6.0              #"
:local ScripVer "7.1.0"

#:log info ""
#:delay 1;
#:log info "$ScriptVerInfo"
#:delay 1;
#:log info ""



#######################
#   ZMIENNE SKRYPTU   #
#######################
:local date [/system clock get date]
:local time [/system clock get time]
:local boardname [/system/resource get board-name]
:local version [/system/resource get version]
:local hostname [/system identity get name]
:local smtpcheck [/tool e-mail get user]
:local schcheck [/system scheduler find name="scheduler_isp_status"]
:local VersionCheck [/system package get routeros version]
:local ScriptNumber [/system script job find script="isp-status"]
if ([:len $VersionCheck] < 5) do={
    :set VersionCheck ($VersionCheck . ".0")
}
:local DevEmail [/system device-mode get email]
if ([:len $DevEmail] = 0) do={
    :set $DevEmail "true"
}
:local DevFetch [/system device-mode get fetch]
if ([:len $DevFetch] = 0) do={
    :set $DevFetch "true"
}
:local DevTraffic [/system device-mode get traffic-gen]
if ([:len $DevTraffic] = 0) do={
    :set $DevTraffic "true"
}
:local DevScheduler [/system device-mode get scheduler]
if ([:len $DevScheduler] = 0) do={
    :set $DevScheduler "true"
}

:local ping1timeavg
:local ping1timemin
:local ping1timemax
:local ping1se
:local ping1re
:local ping2timeavg
:local ping2timemin
:local ping2timemax
:local ping2se
:local ping2re
:local jitternow
:local jitter1
:local jitter2
:local pingspikenow
:local nowcheck
:local flucdetect 0

:global StatusISP
:global StatusRTT
:global StatusJitter
:global StatusPacketLost
:global LastNetBack
:global LastNetError
:global LastFluctuation
:global LastFluctuationDetails

#|----------------------------|
#|     USTAWIENIA GLOBALNE    |
#|----------------------------|
:local fluctuationcheck "yes/no"
:local internetcheck "yes/no"
:local PushOverFlucEnable "yes/no"
:local PushOverISPEnable "yes/no"

#|-------------------------------|
#|     USTAWIENIA SPRAWDZANIA    |
#|-------------------------------|
:local pingaddress1 "ADRES_1"
:local pingaddress2 "ADRES_2"
:local pingcount "15"

:local FLUCJitterMAX "40"
:local FLUCLostMAX "2"
:local FLUCRTTAvgMAX "70"
:local ISPDownDetect "90"
:local FLUCdetectSens "2"

:local fetchaddress "https://ADRES_URL"
:local fetchprotocol "http/https"

#|----------------------------|
#|     USTAWIENIA PUSHOVER    |
#|----------------------------|
:local PushOverToken "API_TOKEN"
:local PushOverUser "USER_TOKEN"
:local PushOverPriority "1"
:local PushOverSound "siren"
:local PushOverTitle "TYTUL_POWIADOMIENIA"

:local PushOverMessageFluc "TRESC_POWIADOMIENIA_PRZY_FLUKTUACJI"
:local PushOverMessageISP "TRESC_POWIADOMIENIA_PRZY_POWROCIE_LACZA"

#|--------------------------------|
#|     USTAWIENIA HARMONOGRAMU    |
#|--------------------------------|
:local scheduler "yes/no"

:local schStartData "Oct/13/2024"
:local schStartTime "01:00:00"
:local schInterval "00:00:30"
:local schOnEvent "/system script run isp-status"



###################
#   KOD SKRYPTU   #
###################

#SPRAWDZANIE NAZWY SKRYPTU ORAZ WERSJI ROS
if (([:len $ScriptNumber] = 0) && ($scheduler = "yes")) do={
    :log error "$Prefix Prawdopodobnie nazwa skryptu jest nieprawidlowa"
    :log error "$Prefix Prawidlowa nazwa skryptu > isp-status"
    :return
} else={
    if ($VersionCheck < $ScripVer) do={
        :log error "$Prefix Skrypt nie wspiera obecnej wersji RoS - $VersionCheck"
        :return
    }
}

#SPRAWDZANIE DEVICE-MODE
if (($DevEmail = false) || ($DevFetch = false) || ($DevTraffic = false) || ($DevScheduler = false)) do={
    :log error "$Prefix Wykryto wylaczona opcje w device-mode, ktora jest potrzebna do dzialania skryptu"
    :delay 1;
    if ($DevEmail = false) do={
        :log error "$Prefix Device-mode email >> $DevEmail"
        :return
    }
    if ($DevFetch = false) do={
        :log error "$Prefix Device-mode fetch >> $DevFetch"
        :return
    }
    if ($DevTraffic = false) do={
        :log error "$Prefix Device-mode traffic-gen >> $DevTraffic"
        :return
    }
    if ($DevScheduler = false) do={
        :log error "$Prefix Device-mode scheduler >> $DevScheduler"
        :return
    }
}

#WYKONYWANIE PROCEDURY PING
/tool flood-ping address=$pingaddress1 count=$pingcount size=56 timeout=00:00:00.030 do={
:set ping1timeavg ($"avg-rtt");
:set ping1timemin ($"min-rtt");
:set ping1timemax ($"max-rtt");
:set ping1se ($sent);
:set ping1re ($received);
}

/tool flood-ping address=$pingaddress2 count=$pingcount size=56 timeout=00:00:00.030 do={
:set ping2timeavg ($"avg-rtt");
:set ping2timemin ($"min-rtt");
:set ping2timemax ($"max-rtt");
:set ping2se ($sent);
:set ping2re ($received);
}

#GENEROWANIE ZMIENNYCH WYLICZENIOWYCH
:local pingse ($ping1se + $ping2se)
:local pingre ($ping1re + $ping2re)
:local pingdif ($pingse - $pingre)
:local pingtimeavg (($ping1timeavg + $ping2timeavg) / 2)
:local packetlosttemp (($pingre * 100) / $pingse)
:local packetlost (100 - $packetlosttemp)


#LICZENIE JITTERA
if ($ping1timemax > $ping1timemin) do={
    :set jitter1 ($ping1timemax - $ping1timemin)
} else={
    :set jitter1 ($ping1timemin - $ping1timemax)
}
if ($ping2timemax > $ping2timemin) do={
    :set jitter2 ($ping2timemax - $ping2timemin)
} else={
    :set jitter2 ($ping2timemin - $ping2timemax)
}
:set jitternow (($jitter1 + $jitter2)/2)

#LICZENIE MAKSYMALNEGO PINGU
if ($ping1timemax > $ping2timemax) do={
    :set pingspikenow "$ping1timemax"
} else={
    :set pingspikenow "$ping2timemax"
}

#DEBUG ZMIENNYCH OPOZNIEN
if ($pingtimeavg = 0) do={
    :set $pingtimeavg 999
}
if ($jitternow = 0) do={
    :set $jitternow 999
}

#ZAPISYWANIE ZMIENNYCH GLOBALNYCH
:set StatusRTT ($pingtimeavg . "ms")
:set StatusJitter ($jitternow . "ms")
:set StatusPacketLost ($packetlost . "%")

#DETEKCJA FLUKTUACJI
if ($jitternow >= $FLUCJitterMAX) do={
    :set flucdetect ($flucdetect + 1)
}
if ($packetlost >= $FLUCLostMAX) do={
    :set flucdetect ($flucdetect + 1)
}
if ($pingtimeavg >= $FLUCRTTAvgMAX) do={
    :set flucdetect ($flucdetect + 1)
}

#SPRAWDZANIE STATUSU LACZA
if ($internetcheck = "yes") do={
    if ($packetlost >= $ISPDownDetect) do={
        :set nowcheck "0"
    } else={
        :set nowcheck "1"
    }

    if ([:len $StatusISP] = 0) do={
        if ($nowcheck = "1") do={
            :set StatusISP "UP"
        } else={
            :set StatusISP "DOWN"
        }
    }

    if (($StatusISP = "UP") && ($nowcheck = "0")) do={
        :do {
                /tool fetch url="$fetchaddress" mode=$fetchprotocol output=none
            } on-error={
                :set StatusISP "DOWN"
                :log error "$Prefix Polaczenie z internetem zostalo zerwane!"
                :set LastNetError ($date . " (" . $time . ")")
            }
    }

    if (($StatusISP = "DOWN") && ($nowcheck = "1")) do={
        :set StatusISP "UP"
        :log warning "$Prefix Polaczenie z internetem zostalo przywrocone!"
        :set LastNetBack ($date . " (" . $time . ")")

        if ($PushOverISPEnable = "yes") do={
            :local postData "token=$PushOverToken&user=$PushOverUser&title=$PushOverTitle&message=$PushOverMessageISP&priority=$PushOverPriority&sound=$PushOverSound"
            /tool fetch url="https://api.pushover.net/1/messages.json" http-method=post http-data=$postData output=none http-header-field="Content-Type: application/x-www-form-urlencoded"
        }
    }
}

#SPRAWDZANIE FLUKTUACJI LACZA
if (($fluctuationcheck = "yes") && ($flucdetect >= $FLUCdetectSens) && ($StatusISP = "UP")) do={
    :set LastFluctuation ([/system clock get date] . " (" . [/system clock get time] . ")")
    :set LastFluctuationDetails ("JITTER: " . $jitternow . "ms" . " || " . "PacketLost: " . $packetlost . "%" . " || " . "RTT: " . $pingtimeavg . "ms")
    :log warning "$Prefix Wykryto fluktuacje lacza!"
    :log warning ($Prefix . " Pakiety: " . $pingre . "/" . $pingse . " (" . $packetlost . " %)" . " || " . "Srednie RTT: " . $pingtimeavg . "ms" . " || " . "Maksymalne RTT: " . $pingspikenow . "ms" . " || " . "Jitter: " . $jitternow . "ms")

    if ($PushOverFlucEnable = "yes") do={
        :local postData "token=$PushOverToken&user=$PushOverUser&title=$PushOverTitle&message=$PushOverMessageFluc&priority=$PushOverPriority&sound=$PushOverSound"
        /tool fetch url="https://api.pushover.net/1/messages.json" http-method=post http-data=$postData output=none http-header-field="Content-Type: application/x-www-form-urlencoded"
    }
}

#SPRAWDZANIE USTAWIONEGO HARMONOGRAMU
if ($scheduler = "yes") do={
    if ($schcheck = "") do={
        :log info "$Prefix Brak ustawionego harmonogramu!"
        :delay 1s;
        /system/scheduler/add name="scheduler_isp_status" start-date="$schStartData" start-time="$schStartTime" interval="$schInterval" on-event="$schOnEvent"
        :log info "$Prefix Ustawiono harmonogram sprawdzania lacza."
        :delay 1s;
        :log info "$Prefix Rozpoczecie: $schStartData o godzinie: $schStartTime || Interwal: $schInterval"
    }
}