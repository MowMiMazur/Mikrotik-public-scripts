#################################
#      -SFTP BACKUP SCRIPT-     #
#           by MAZNET           #
#            v3.5.0             #
#        mikrotik script        #
#################################

:local Prefix "[SFTP BACKUP SCRIPT]"
:local ScriptVerInfo ">>> [SFTP BACKUP SCRIPT] v3.5.0 - by Maznet <<<"
:local ScriptVerMail "#           v3.5.0            #"
:local ScripVer "7.12.0"

:log info ""
:delay 1;
:log info "$ScriptVerInfo"
:delay 1;
:log info ""



#######################
#   ZMIENNE SKRYPTU   #
#######################
:local hostname [/system identity get name]
:local boardname [/system/resource get board-name]
:local version [/system/resource get version]
:local date [/system clock get date]
:local time [/system clock get time]
:local localfilename "$hostname-Backup-Temp"
:local remotefilename "BACKUP-$hostname--$boardname--$version--$date--$time"
:local schcheck [/system scheduler find name="scheduler_backup"]
:local VersionCheck [/system package get routeros version]
:local ScriptNumber [/system script job find script="backup"]
:local mailbody
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
:local DevScheduler [/system device-mode get scheduler]
if ([:len $DevScheduler] = 0) do={
    :set $DevScheduler "true"
}

:local errorOccured "no"
:local errorCreate ""
:local errorICMP ""
:local errorSendBak ""
:local errorSendExp ""
:local errorDelete ""

#|-------------------------------|
#|  USTAWIENIA SERWERA FTP/SFTP  |
#|-------------------------------|
:local serverip "IP"
:local username "USER"
:local password "PASS"
:local serverport "PORT"
:local dstpath "SCIEZKA_DOCELOWA"

#|--------------------------------|
#|  USTAWIENIA POWIADOMIEN EMAIL  |
#|--------------------------------|
:local mailnotify "yes/no"

:local mailserver "ADRES_SERWERA"
:local mailport "PORT"
:local mailtls "yes/no"
:local mailfrom "MAIL OD"
:local mailto "MAIL DO"
:local mailuser "USER"
:local mailpass "PASS"
:local mailsubject "BACKUP FAILED - $hostname--$date--$time"

#|---------------------------------|
#|  USTAWIENIA ICMP-SIZE-KNOCKING  |
#|---------------------------------|
:local pkenable "yes/no"

:local icmpsize1 "111"
:local icmpsize2 "89"
:local icmpsize3 "69"

#|----------------------------|
#|  USTAWIENIA AUTOMATYZACJI  |
#|----------------------------|
:local scheduler "yes/no"

:local schStartData "Jul/21/2024"
:local schStartTime "23:30:00"
:local schInterval "7d 00:00:00"
:local schOnEvent "/system script run backup"



###################
#   KOD SKRYPTU   #
###################

#SPRAWDZANIE NAZWY SKRYPTU ORAZ WERSJI ROS
if (([:len $ScriptNumber] = 0) && ($scheduler = "yes")) do={
    :log error "$Prefix Prawdopodobnie nazwa skryptu jest nieprawidlowa"
    :log error "$Prefix Prawidlowa nazwa skryptu > backup"
    :return
} else={
    if ($VersionCheck < $ScripVer) do={
        :log error "$Prefix Skrypt nie wspiera obecnej wersji RoS - $VersionCheck"
        :return
    }
}

#SPRAWDZANIE DEVICE-MODE
if (($DevEmail = false) || ($DevFetch = false) || ($DevScheduler = false)) do={
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
    if ($DevScheduler = false) do={
        :log error "$Prefix Device-mode scheduler >> $DevScheduler"
        :return
    }
}

#SPRAWDZANIE USTAWIEN EMAIL
if ($mailnotify = "yes") do={
    :local smtpSrvCheck [/tool e-mail get server]
    :local smtpPortCheck [/tool e-mail get port]
    :local smtpTlsCheck [/tool e-mail get tls]
    :local smtpFromCheck [/tool e-mail get from]
    :local smtpUserCheck [/tool e-mail get user]
    :local smtpPassCheck [/tool e-mail get password]

    if (($smtpSrvCheck = $mailserver) && ($smtpPortCheck = $mailport) && ($smtpTlsCheck = $mailtls) && ($smtpFromCheck = $mailfrom) && ($smtpUserCheck = $mailuser) && ($smtpPassCheck = $mailpass)) do={
    } else={
        :log info "$Prefix Wykryto blad w konfiguracji SMTP lub jej brak!"
        :delay 1s;
        /tool e-mail set server=$mailserver port=$mailport tls=$mailtls from=$mailfrom user=$mailuser password=$mailpass
        :log info "$Prefix Skonfigurowano serwer SMTP."
        :delay 1s;
    }
}

#TWORZENIE PLIKOW KOPII ZAPASOWEJ
:log info "$Prefix Rozpoczecie tworzenia backupu";
:delay 1;

:log info "$Prefix Tworzenie plikow backup lokalnie";
:do {
    export terse file="$localfilename"
    /system backup save name="$localfilename"
} on-error={
    :log error "$Prefix Blad podczas tworzenia plikow backup.";
    :set errorOccured "yes";
    :set errorCreate "Błąd podczas tworzenia plików backup"
}

:delay 1;

#PROCEDURA ICMP KNOCKING
if ($pkenable = "yes") do={
    :log info "$Prefix Rozpoczynanie procedury ICMP-Knocking na adres - $serverip";
    :do {
        ping $serverip count=1 interval=1 size=$icmpsize1
        delay 1;
        ping $serverip count=1 interval=1 size=$icmpsize2
        delay 1;
        ping $serverip count=1 interval=1 size=$icmpsize3
        delay 1;
        :log info "$Prefix ICMP-Knocking wykonany pomyslnie";
    } on-error={
        :log error "$Prefix Blad podczas procedury ICMP-Knocking.";
        :set errorOccured "yes";
        :set errorICMP "Błąd podczas procedury ICMP-Knocking"
    }
}

:delay 3;

#WYSYLANIE PLIKOW KOPII ZAPASOWEJ
:log info "$Prefix Wysylanie pliku .backup na serwer";
:do {
    /tool fetch address=$serverip port=$serverport src-path="$localfilename.backup" user=$username mode=sftp password=$password dst-path="$dstpath/$remotefilename.backup" upload=yes
} on-error={
    :log error "$Prefix Blad podczas wysylania pliku .backup na serwer.";
    :set errorOccured "yes";
    :set errorSendBak "Błąd podczas wysylania pliku .backup"
}

:delay 1;

:log info "$Prefix Wysylanie pliku .rsc na serwer";
:do {
    /tool fetch address=$serverip port=$serverport src-path="$localfilename.rsc" user=$username mode=sftp password=$password dst-path="$dstpath/$remotefilename.rsc" upload=yes
} on-error={
    :log error "$Prefix Blad podczas wysylania pliku .rsc na serwer.";
    :set errorOccured "yes";
    :set errorSendExp "Błąd podczas wysylania pliku .rsc"
}

:delay 1;

#USUWANIE LOKALNYCH PLIKOW KOPII ZAPASOWEJ
:log info "$Prefix Usuwanie lokalnych plikow backupu";
:do {
    /file remove "$localfilename.backup"
    /file remove "$localfilename.rsc"
} on-error={
    :log error "$Prefix Blad podczas usuwania lokalnych plikow backupu.";
    :set errorOccured "yes";
    :set errorDelete "Błąd podczas usuwania lokalnych plików backupu"
}

#DEFINIOWANIE ZAWARTOSCI EMAIL
:set mailbody "###############################\r\n#     -SFTP BACKUP SCRIPT-    #\r\n#          by MAZNET          #\r\n$ScriptVerMail\r\n#       mikrotik script       #\r\n###############################\r\n\r\n\r\n|---------NAPOTKANE BŁĘDY---------|\r\n\r\n|-| $errorCreate\r\n|-| $errorICMP\r\n|-| $errorSendBak\r\n|-| $errorSendExp\r\n|-| $errorDelete\r\n\r\n|---------------------------------|\r\n\r\n\r\n\r\n|---------DANE URZĄDZENIA---------|\r\n\r\n|-| MIKROTIK-$boardname\r\n|-| Nazwa: $hostname\r\n|-| Wersja: $version\r\n|-| Czas: $date ($time)\r\n\r\n|---------------------------------|"

#INFORMACJA O BLEDACH WYSYLANA NA MAILA
if (($mailnotify = "yes") && ($errorOccured = "yes")) do={
    :log info "$Prefix Wysylanie powiadomienia o bledach na adres e-mail: $mailto";
    /tool e-mail send to="$mailto" subject="$mailsubject" body="$mailbody";
} else={
    :log info "$Prefix Tworzenie i wysylanie backupu zakonczone powodzeniem!";
}

#SPRAWDZANIE USTAWIONEGO HARMONOGRAMU
if ($scheduler = "yes") do={
    if ($schcheck = "") do={
        :log info "$Prefix Brak ustawionego harmonogramu!"
        :delay 1s;
        /system/scheduler/add name="scheduler_backup" start-date="$schStartData" start-time="$schStartTime" interval="$schInterval" on-event="$schOnEvent"
        :log info "$Prefix Ustawiono harmonogram kopii zapasowej."
        :delay 1s;
        :log info "$Prefix Rozpoczecie: $schStartData o godzinie: $schStartTime || Interwal: $schInterval"
    }
}