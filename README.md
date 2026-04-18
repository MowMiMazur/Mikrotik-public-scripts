# 🔧 MikroTik Public Scripts - by MAZNET

Zbiór publicznych skryptów RouterOS do routerów MikroTik. Każdy skrypt jest gotowy do użycia - wystarczy uzupełnić zmienne konfiguracyjne oznaczone w sekcji ustawień.

Wszystkie skrypty wspierają **RouterOS 7.x** i posiadają wbudowaną walidację wersji systemu.

> **Piszę również skrypty MikroTik na zlecenie** - jeśli potrzebujesz dedykowanego rozwiązania dopasowanego do Twojej infrastruktury, skontaktuj się ze mną przez [maznet.pl](https://maznet.pl).

---

## 📋 Lista skryptów

| Skrypt | Wersja | Opis |
|--------|--------|------|
| [sftp-backup.rsc](sftp-backup.rsc) | `v3.5.0` | Automatyczny backup na serwer SFTP |
| [internet-check.rsc](internet-check.rsc) | `v2.0.0` | Monitoring dostępności internetu |
| [ISP-status.rsc](ISP-status.rsc) | `v1.6.0` | Zaawansowany monitoring jakości łącza ISP |
| [cert-generator.rsc](cert-generator.rsc) | `v1.3.0` | Generator certyfikatów OpenVPN / SSTP |
| [ping-spike-check.rsc](ping-spike-check.rsc) | `v1.2.0` | Wykrywanie skoków opóźnień (ping spike) |

---

## 📦 Opisy skryptów

### 🔒 sftp-backup.rsc - `v3.5.0`

Kompleksowy skrypt automatycznego backupu konfiguracji routera na zewnętrzny serwer SFTP.

**Funkcje:**
- Tworzenie plików `.backup` (binarny) oraz `.rsc` (eksport tekstowy)
- Wysyłanie backupu na serwer SFTP z konfigurowalnymi danymi dostępowymi
- Powiadomienia e-mail o statusie backupu (sukces / błąd)
- **ICMP Size Knocking** - otwieranie portu SFTP na serwerze poprzez sekwencję pingów o określonych rozmiarach
- Automatyczna konfiguracja harmonogramu (Scheduler)
- Walidacja ustawień SMTP, device-mode i wersji RouterOS
- Szczegółowa obsługa błędów na każdym etapie

---

### 🌐 internet-check.rsc - `v2.0.0`

Skrypt monitorujący dostępność połączenia internetowego poprzez cykliczne odpytywanie wskazanego adresu URL.

**Funkcje:**
- Sprawdzanie dostępności internetu przez HTTP/HTTPS fetch
- Konfigurowalna liczba prób i próg wykrycia awarii
- Wykrywanie zerwania i przywrócenia łącza
- Powiadomienia e-mail z datą/godziną awarii i przywrócenia
- Automatyczna konfiguracja serwera SMTP
- Przechowywanie statusu w zmiennych globalnych (`netstatus`, `lastnetback`, `lastneterror`)

---

### 📊 ISP-status.rsc - `v1.6.0`

Zaawansowany skrypt monitoringu jakości łącza internetowego z analizą RTT, jittera i packet loss.

**Funkcje:**
- Pomiar RTT (avg/min/max) z użyciem flood-ping na dwa niezależne adresy
- Obliczanie **jittera** i **packet loss**
- Wykrywanie fluktuacji łącza na podstawie konfigurowalnych progów (RTT, jitter, packet loss)
- Powiadomienia **PushOver** przy wykryciu fluktuacji oraz przy powrocie łącza
- Monitorowanie statusu ISP (UP/DOWN) z zapisem czasu zdarzeń
- Automatyczna konfiguracja harmonogramu
- Walidacja device-mode (email, fetch, traffic-gen, scheduler)
- Status dostępny w zmiennych globalnych (`StatusISP`, `StatusRTT`, `StatusJitter`, `StatusPacketLost`)

---

### 📜 cert-generator.rsc - `v1.3.0`

Generator certyfikatów SSL/TLS dla tuneli VPN - obsługuje zarówno OpenVPN, jak i SSTP.

**Funkcje:**
- Generowanie pełnego zestawu certyfikatów: **CA**, **Server**, **Client**
- Obsługa **OpenVPN** i **SSTP** (z subject-alt-name dla IP/domeny)
- Konfigurowalny rozmiar klucza, okres ważności, numeracja klientów
- Automatyczne podpisywanie certyfikatów odpowiednim CA
- Generowanie dowolnej liczby certyfikatów klienckich w pętli

---

### 📈 ping-spike-check.rsc - `v1.2.0`

Lekki skrypt do wykrywania skoków opóźnień (ping spike) na łączu internetowym.

**Funkcje:**
- Pingowanie dwóch niezależnych adresów (domyślnie `1.1.1.1` i `8.8.8.8`)
- 6 pomiarów w jednym cyklu z obliczaniem średniej
- Konfigurowalna wartość progowa spike'a (ms)
- Logowanie szczegółowych wyników przy wykryciu fluktuacji
- Zapis czasu ostatniego spike'a w zmiennej globalnej (`lastpingspike`)

---

## ⚙️ Jak używać

1. Skopiuj zawartość wybranego skryptu `.rsc`
2. W RouterOS przejdź do **System → Scripts** i utwórz nowy skrypt
3. Uzupełnij zmienne w sekcji **USTAWIENIA** (oznaczone wielkimi literami, np. `"IP"`, `"USER"`, `"PASS"`)
4. Uruchom skrypt ręcznie lub skonfiguruj **Scheduler** (większość skryptów posiada wbudowaną automatyczną konfigurację harmonogramu)

---

## 📬 Kontakt i zlecenia

Potrzebujesz dedykowanego skryptu MikroTik, automatyzacji sieci lub integracji z zewnętrznymi systemami?

Realizuję zlecenia dla firm i klientów indywidualnych - od prostych skryptów po zaawansowane rozwiązania sieciowe.

**Skontaktuj się ze mną:** [maznet.pl](https://maznet.pl)

---

## 📄 Licencja

Skrypty udostępnione publicznie. Przy wykorzystaniu proszę o zachowanie informacji o autorze (**MAZNET**).