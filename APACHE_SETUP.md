# Apache CGI Setup für eingabe.sh

## Übersicht
Diese Anleitung beschreibt die Konfiguration des Apache-Webservers für die Ausführung des `eingabe.sh` CGI-Skripts auf einem Linux-System.

## Voraussetzungen

### Apache-Module
Folgende Module müssen aktiviert sein:
- `mod_cgi` - für die Ausführung von CGI-Skripten

### Aktivierung der Module
```bash
# Ubuntu/Debian
sudo a2enmod cgi
sudo systemctl restart apache2

# CentOS/RHEL
sudo systemctl restart httpd
```

## Apache-Konfiguration

### Option 1: ScriptAlias (Empfohlen)
Fügen Sie in Ihrer Apache-Konfiguration (z.B. `/etc/apache2/sites-available/000-default.conf` oder VirtualHost) hinzu:

```apache
ScriptAlias /cgi-bin/ /var/www/html/Input/
<Directory "/var/www/html/Input">
    Options +ExecCGI
    AddHandler cgi-script .sh
    Require all granted
</Directory>
```

Dann müssen die HTML-Formulare angepasst werden:
- `action="../Input/eingabe.sh"` → `action="/cgi-bin/eingabe.sh"`

### Option 2: Options +ExecCGI
Fügen Sie in Ihrer Apache-Konfiguration hinzu:

```apache
<Directory "/var/www/html/Input">
    Options +ExecCGI
    AddHandler cgi-script .sh
    Require all granted
</Directory>
```

## Dateiberechtigungen

### Skript ausführbar machen
```bash
chmod +x Input/eingabe.sh
```

### CSV- und XML-Dateien beschreibbar machen
```bash
# Dateien erstellen falls nicht vorhanden
touch formulareingaben.csv formulareingaben.xml

# Berechtigungen setzen (Apache-User kann je nach System unterschiedlich sein)
# Ubuntu/Debian: www-data
# CentOS/RHEL: apache

# Ubuntu/Debian:
sudo chown www-data:www-data formulareingaben.csv formulareingaben.xml
sudo chmod 664 formulareingaben.csv formulareingaben.xml

# CentOS/RHEL:
sudo chown apache:apache formulareingaben.csv formulareingaben.xml
sudo chmod 664 formulareingaben.csv formulareingaben.xml
```

### Verzeichnis-Berechtigungen
```bash
# Hauptverzeichnis muss lesbar sein
chmod 755 /var/www/html

# Input-Verzeichnis muss ausführbar sein
chmod 755 /var/www/html/Input
```

## Apache-User identifizieren

Um herauszufinden, welcher User Apache verwendet:

```bash
# Ubuntu/Debian
ps aux | grep apache2 | head -1

# CentOS/RHEL
ps aux | grep httpd | head -1
```

Oder in der Apache-Konfiguration:
```bash
grep -i "user\|group" /etc/apache2/apache2.conf
# oder
grep -i "user\|group" /etc/httpd/conf/httpd.conf
```

## Testen der Konfiguration

### 1. Skript direkt testen
```bash
cd /var/www/html/Input
QUERY_STRING="nameL=Test&Buch1=Testbuch" ./eingabe.sh
```

### 2. Über Browser testen
1. Öffnen Sie die Webseite im Browser
2. Füllen Sie das Lara- oder Marco-Formular aus
3. Senden Sie das Formular ab
4. Überprüfen Sie, ob die Daten in `formulareingaben.csv` und `formulareingaben.xml` gespeichert wurden

### 3. Apache Error-Log prüfen
```bash
# Ubuntu/Debian
sudo tail -f /var/log/apache2/error.log

# CentOS/RHEL
sudo tail -f /var/log/httpd/error_log
```

## Häufige Probleme

### Problem: "403 Forbidden"
**Lösung:**
- Überprüfen Sie die Dateiberechtigungen
- Stellen Sie sicher, dass `Options +ExecCGI` gesetzt ist
- Überprüfen Sie die Verzeichnis-Berechtigungen

### Problem: "500 Internal Server Error"
**Lösung:**
- Überprüfen Sie die Apache Error-Logs
- Stellen Sie sicher, dass das Skript ausführbar ist (`chmod +x`)
- Überprüfen Sie die Shebang-Zeile (`#!/bin/bash`)
- Überprüfen Sie, ob bash installiert ist

### Problem: "Datei nicht beschreibbar"
**Lösung:**
- Stellen Sie sicher, dass der Apache-User Schreibrechte hat
- Überprüfen Sie die Dateiberechtigungen mit `ls -la`
- Setzen Sie die Berechtigungen wie oben beschrieben

### Problem: "QUERY_STRING ist leer"
**Lösung:**
- Überprüfen Sie, ob die Formulare `method="get"` verwenden
- Überprüfen Sie die Form-Action-Pfade in den HTML-Dateien

## Sicherheitshinweise

1. **Dateiberechtigungen**: Nur der Apache-User sollte Schreibrechte auf CSV/XML-Dateien haben
2. **Verzeichnis-Listing**: Deaktivieren Sie Verzeichnis-Listing für das Input-Verzeichnis:
   ```apache
   <Directory "/var/www/html/Input">
       Options -Indexes +ExecCGI
       AddHandler cgi-script .sh
   </Directory>
   ```
3. **Input-Validierung**: Das Skript enthält bereits Basis-Validierung, aber für Produktionsumgebungen sollten zusätzliche Sicherheitsmaßnahmen implementiert werden

## Nach der Konfiguration

1. Apache neu starten:
   ```bash
   # Ubuntu/Debian
   sudo systemctl restart apache2
   
   # CentOS/RHEL
   sudo systemctl restart httpd
   ```

2. Testen Sie die Funktionalität über die Webseite

3. Überprüfen Sie die Logs auf Fehler
