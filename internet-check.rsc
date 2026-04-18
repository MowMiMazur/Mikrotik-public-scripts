#####################################
#      -INTERNET CHECK SCRIPT-      #
#             by MAZNET             #
#              v2.0.0               #
#          mikrotik script          #
#####################################

#:log info ""
#:delay 1;
#:log info ">>> [INTERNET CHECK SCRIPT] v2.0.0 - by Maznet <<<"
#:delay 1;
#:log info ""

#######################
#   ZMIENNE SKRYPTU   #
#######################
:global netstatus
:global lastnetback
:global lastneterror
:local nowcheck
:local CheckThisRound (0)
:local date [/system clock get date]
:local time [/system clock get time]
:local boardname [/system/resource get board-name]
:local version [/system/resource get version]
:local hostname [/system identity get name]
:local smtpcheck [/tool e-mail get user]

#|-------------------------------|
#|     USTAWIENIA SPRAWDZANIA    |
#|-------------------------------|
:local address "https://ADRES_STRONY.pl"
:local protocol "http/https"
:local count 5
:local limit 3

#|--------------------------------|
#|  USTAWIENIA POWIADOMIEN EMAIL  |
#|--------------------------------|
:local mailnotify "yes/no"

:local mailserver "ADRES SERWERA"
:local mailport "PORT"
:local mailtls "yes"
:local mailfrom "OD KOGO"
:local mailto "DO KOGO"
:local mailuser "UZYTKOWNIK"
:local mailpass "HASLO"

###################
#   KOD SKRYPTU   #
###################

if ($mailnotify = "yes") do={
    if ($smtpcheck = "") do={
        :log info "[INTERNET CHECK] Brak skonfigurowanego serwera SMTP!"
        :delay 1s;
        /tool e-mail set server=$mailserver port=$mailport tls=$mailtls from=$mailfrom user=$mailuser password=$mailpass
        :log info "[INTERNET CHECK] Skonfigurowano serwer SMTP."
        :delay 1s;
    }
}

:for i from=1 to=$count do={
    :do {
        /tool fetch url="$address" mode=$protocol output=none idle-timeout=2s
    } on-error={
        :set CheckThisRound ($CheckThisRound + 1)
    }
}

if ($CheckThisRound < $limit) do={
    :set nowcheck "1"
} else={
    :set nowcheck "0"
}

if ([:len $netstatus] = 0) do={
    if ($nowcheck = "1") do={
        :set netstatus "UP"
    } else={
        :set netstatus "DOWN"
    }
}

if (($netstatus = "UP") && ($nowcheck = "0")) do={
    :set netstatus "DOWN"
    :log error "[INTERNET CHECK] Polaczenie z internetem zostalo zerwane!"
    :set lastneterror ($date . " (" . $time . ")")
}

if (($netstatus = "DOWN") && ($nowcheck = "1")) do={
    :set netstatus "UP"
    :log warning "[INTERNET CHECK] Polaczenie z internetem zostalo przywrocone!"
    :set lastnetback ($date . " (" . $time . ")")
    :delay 2;
    if ($mailnotify = "yes") do={
        :local mailsubject "Utrata polaczenia $hostname"
        :local mailbody ">>> [INTERNET CHECK SCRIPT] <<<\n\nPolaczenie z internetem zostalo zerwane!\nZerwanie nastapilo: $lastneterror\nPowrot polaczenia nastapil: $lastnetback\n \nHOSTNAME: $hostname\nBOARDNAME: $boardname\nVERSION: $version"
        /tool e-mail send to="$mailto" subject="$mailsubject" body="$mailbody";
    }
}