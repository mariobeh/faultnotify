# faultnotify (Debian / 07.25)

## Vorwort

`faultnotify.sh` ist ein modular aufgebautes Bash-Skript zur Überwachung von Geräten und Diensten in einem Netzwerk. Es erkennt Ausfälle zuverlässig und benachrichtigt wahlweise per E-Mail oder Telegram. Es richtet sich vor allem an Admins, die ihre Systeme ohne aufwendige Tools im Blick behalten wollen – ideal für headless Server oder embedded Systeme.

## Hauptfunktionen

- Geräteprüfung via Ping oder Netcat (TCP/UDP)
- Zwei-Stufen-Erkennung für Störungen (R1 → R2)
- Wieder-Online-Erkennung mit automatischem Reset
- Benachrichtigung per Telegram oder Mail mit Rückfallmechanismus
- Dauerhafte Schleife (per `on`/`off` steuerbar) oder Einzeltest
- Logfile-Erstellung im CSV-Format

## Aufbau und Einrichtung

Nach dem Aufruf mit `./faultnotify.sh install` wird ein geführter Installationsprozess gestartet:

- Abfrage der Benachrichtigungsmethode (Mail oder Telegram)
- Versand eines Verifizierungscodes zur Bestätigung
- Automatische Paketinstallation (`ssmtp`, `mailutils`, `curl`, `netcat-traditional`)

Anschließend werden Geräte mit `./faultnotify.sh add` zur Überwachung hinzugefügt. Dabei werden Name, IP-Adresse, optional ein Port und ggf. das Protokoll (UDP) angegeben. Alle Daten landen strukturiert in `config.txt`.

## Nutzung und Bedienung

- **Testlauf**: `./faultnotify.sh test` führt eine einmalige Prüfung aus.
- **Automatikbetrieb**: Durch `./faultnotify.sh on` wird eine Endlosschleife aktiviert, `off` beendet sie.
- **Modifikation**: Mit `./faultnotify.sh mod` lassen sich Einträge gezielt ändern oder löschen.
- **Logik:**
  - Offline-Erkennung durch zwei Ping-/Portprüfungen
  - Wird ein Gerät zweimal in Folge als nicht erreichbar erkannt, wird es als gestört markiert (R1 → R2)
  - Sobald es wieder erreichbar ist, erfolgt die Rückmeldung und die Jail-Datei wird gelöscht

## Speicherort & Struktur

Daten werden im Benutzerverzeichnis unter `/home/$USER/script-data/faultnotify.sh/` abgelegt. Dort befinden sich:

- `config.txt` – Konfigurationsdatei inkl. Geräte
- `jail/` – temporäre Markerdateien für gestörte Geräte
- `logs/` – CSV-Logs aller Events

## Sonstiges

- Die Geräteliste wird automatisch durchnummeriert (ID001, ID002, …)
- Einfache Migration alter Daten durch Update-Routinen
- Updatefähig durch eigene Versionslogik (`scriptversion`)

---

*Nur in Deutsch verfügbar, Umbau auf andere Sprachen auf Anfrage. In diesem Falle werden alle Ausgaben (`echo`) in eine Sprachen-Datei extrahiert und es wird so ermöglicht, unbegrenzte Sprachen zu integrieren.*

<br>

**Vielen Dank,**  
mariobeh
