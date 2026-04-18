#####################################
#      -CERTIFICATES GENERATOR-     #
#             by MAZNET             #
#              v1.3.0               #
#          mikrotik script          #
#####################################

:local Prefix "[CERT GENERATOR]"
:local ScriptVerInfo ">>> [CERT GENERATOR] v1.3.0 - by Maznet <<<"
:local ScripVer "7.1.0"

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
:local VersionCheck [/system package get routeros version]
if ([:len $VersionCheck] < 5) do={
    :set VersionCheck ($VersionCheck . ".0")
}

#|---------------------------|
#|  USTAWIENIA CERTYFIKATOW  |
#|---------------------------|
:local year "ROK"
:local company "NAZWA"
:local daysValid "WAZNOSC_W_DNIACH"
:local keySize "2048"
:local pass "HASLO_DO_EXPORTU"
:local amount (ILOSC)
:local startAmount (POCZATEK_NUMERACJI)
:local ip "IP/DOMENA WAN ROUTERA (W PRZYPADKU SSTP)"

#|-----------------------|
#|  USTAWIENIA GLOBALNE  |
#|-----------------------|
:local cert "ovpn/sstp"



###################
#   KOD SKRYPTU   #
###################

#SPRAWDZANIE NAZWY SKRYPTU ORAZ WERSJI ROS
if ($VersionCheck < $ScripVer) do={
    :log error "$Prefix Skrypt nie wspiera obecnej wersji RoS - $VersionCheck"
    :return
}

#CERTYFIKATY OVPN
if ($cert = "ovpn") do={
    #USTAWIANIE NAZW CERTYFIKATOW
    :local nameCA ($company . "-" . $year . "-CA")
    :local nameSRV ($company . "-" . $year . "-SRV")
    :local nameCLIENT ($company . "-" . $year . "-client")
    :local loop ($startAmount + $amount - 1)
    :delay 1;

    #GENEROWANIE I PODPISYWANIE CERTYFIKATU CA
    :log info "$Prefix Tworzenie certyfikatu CA"
    /certificate add name="CA--temp" common-name="$nameCA" organization="$company" key-usage=key-cert-sign,crl-sign key-size="$keySize" days-valid="$daysValid"
    :delay 1;
    :log info "$Prefix Podpisywanie certyfikatu CA"
    /certificate sign "CA--temp" name="$nameCA"
    :delay 2;

    #GENEROWANIE I PODPISYWANIE CERTYFIKATU SERWERA
    :log info "$Prefix Tworzenie certyfikatu Serwera"
    /certificate add name="SRV--temp" common-name="$nameSRV" organization="$company" key-usage=digital-signature,key-encipherment,data-encipherment,tls-server key-size="$keySize" days-valid="$daysValid"
    :delay 1;
    :log info "$Prefix Podpisywanie certyfikatu Serwera"
    /certificate sign "SRV--temp" name="$nameSRV" ca="$nameCA"
    :delay 2;

    #GENEROWANIE CERTYFIKATOW KLIENTA
    :log info "$Prefix Rozpoczeto generowanie certyfikatow dla $amount klientow"
    :for i from="$startAmount" to="$loop" do={
        /certificate add name="Client-$i--temp" common-name=($nameCLIENT . $i) organization="$company" key-usage=tls-client key-size="$keySize" days-valid="$daysValid"
    }

    :log info "$Prefix Wszytkie certyfikaty wygenerowane prawidlowo."
    :delay 2;

    #PODPISYWANIE CERTYFIKATOW KLIENTA
    :log info "$Prefix Rozpoczeto podpisywanie certyfikatow dla $amount klientow"
    :for i from=$startAmount to=$loop do={
        /certificate sign "Client-$i--temp" name=($nameCLIENT . $i) ca="$nameCA"
    }
    :delay 2;
    :log info "$Prefix Certyfikaty dla OVPN zostały poprawnie wygenerowane i podpisane!"
}

#CERTYFIKATY SSTP
if ($cert = "sstp") do={
    #USTAWIANIE NAZW CERTYFIKATOW
    :local nameCA ($company . "-" . $year . "-CA")
    :local nameSRV ($company . "-" . $year . "-SRV")
    :local nameCLIENT ($company . "-" . $year . "-client")
    :local loop ($startAmount + $amount - 1)
    :delay 1;

    #GENEROWANIE I PODPISYWANIE CERTYFIKATU CA
    :log info "$Prefix Tworzenie certyfikatu CA"
    /certificate add name="CA--temp" common-name="$ip" subject-alt-name=IP::: organization="$company" key-usage=key-cert-sign,crl-sign key-size="$keySize" days-valid="$daysValid"
    :delay 1;
    :log info "$Prefix Podpisywanie certyfikatu CA"
    /certificate sign "CA--temp" name="$nameCA"
    :delay 2;

    #GENEROWANIE I PODPISYWANIE CERTYFIKATU SERWERA
    :log info "$Prefix Tworzenie certyfikatu Serwera"
    /certificate add name="SRV--temp" common-name="$ip" subject-alt-name=IP::: organization="$company" key-usage=digital-signature,key-encipherment,tls-server key-size="$keySize" days-valid="$daysValid"
    :delay 1;
    :log info "$Prefix Podpisywanie certyfikatu Serwera"
    /certificate sign "SRV--temp" name="$nameSRV" ca="$nameCA"
    :delay 2;

    #GENEROWANIE CERTYFIKATOW KLIENTA
    :log info "$Prefix Rozpoczeto generowanie certyfikatow dla $amount klientow"
    :for i from="$startAmount" to="$loop" do={
        /certificate add name="Client-$i--temp" common-name=($nameCLIENT . $i) subject-alt-name=IP::: organization="$company" key-usage=tls-client key-size="$keySize" days-valid="$daysValid"
    }

    :log info "$Prefix Wszytkie certyfikaty wygenerowane prawidlowo."
    :delay 2;

    #PODPISYWANIE CERTYFIKATOW KLIENTA
    :log info "$Prefix Rozpoczeto podpisywanie certyfikatow dla $amount klientow"
    :for i from=$startAmount to=$loop do={
        /certificate sign "Client-$i--temp" name=($nameCLIENT . $i) ca="$nameCA" ca-crl-host="$ip"
    }
    :delay 2;
    :log info "$Prefix Certyfikaty dla SSTP zostały poprawnie wygenerowane i podpisane!"
}