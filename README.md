(Linux Debian/Ubuntu)

Die faultnotify.sh kontrolliert bei Aufruf alle eingerichteten IP-Geräte, um den Online-Status sicherheitsrelevanter Geräte zu überwachen. Bis zu 25 Geräte. Crontab-Job (userbasiert) automatisch über das Script möglich.

Bei erstem Aufruf beginnt eine Art Wizard, der die Geräte einrichten lässt und benötigte Programme per sudo apt-get installiert. Es entsteht eine Config-File, die jederzeit manuell geändert werden kann.

Ist der Wizard abgeschlossen und die Config eingerichtet, werden beim Aufrufen des Bash-Scripts alle Geräte überprüft. Ist ein Gerät offline, erhält man eine Benachrichtigung. Diese erfolgt wahlweise per Telegram oder Email. Je nachdem ist die Einrichtigung eines Telegram-Bots erforderlich oder der Server muss in der Lage sein, eine Email zu versenden.

Hierbei ist zu unterscheiden, ob das Gerät das erste Mal offline, dauerhaft offline, oder wieder online ist. Die Benachrichtigung erfolgt bei erstem Offline-Status und beim Wiederonline-Status. Im dauerhaftem Offline-Status ist die Benachrichtigung ausgesetzt.

Es gibt 3 Modis. Der manuelle Aufruf-Modus ohne Crontab, der Crontab-Modus nach Belieben und der Permanent-Modus, der permanent das Script selbst aufruft. Im normalen Crontab-Modus mit maximal einem Aufruf pro Minute kann eine Unterbrechung eher verwirren als im Permanent-Modus. Letzteres ist aber ressourcenunfreundlich.

Mit integriertem Updater, der bei neuerer Version auf dem Server direkt die Bash-File mit der neuen automatisch ersetzt.

Alle mit diesem Bash-File zusammenhängende Config-Files werden ausgelagert nach /home/$Benutzer/script-data/störungsbenachrichtigung.

Garantiert lauffähig auf Debian und Ubuntu und alle Zwischendistributionen (Xubuntu, Kubuntu, ...)

Nur in Deutsch verfügbar, Umbau auf anderen Sprachen auf Anfrage. Only available in German, conversion to other languages on request.
