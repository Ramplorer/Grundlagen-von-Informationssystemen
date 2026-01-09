#!/bin/bash

# Shell-Skript zur Verarbeitung von Formular-Eingaben
# Speichert Daten in CSV und XML
# Für Apache CGI auf Linux optimiert

# Pfade relativ zum Skript-Verzeichnis
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$BASE_DIR/data"
CSV_FILE="$DATA_DIR/formulareingaben.csv"
XML_FILE="$DATA_DIR/formulareingaben.xml"
DTD_FILE="$DATA_DIR/formulareingaben.dtd"

# Fehler-Funktion
error_exit() {
    echo "Content-Type: text/html; charset=UTF-8"
    echo ""
    echo "<!DOCTYPE html>"
    echo "<html><head><title>Fehler</title></head><body>"
    echo "<h1>Fehler</h1><p>$1</p>"
    echo "<p><a href=\"../index.html\">Zurück zur Startseite</a></p>"
    echo "</body></html>"
    exit 1
}

# Pfad-Validierung
if [ ! -d "$BASE_DIR" ]; then
    error_exit "Basis-Verzeichnis nicht gefunden."
fi

# Data-Verzeichnis erstellen, falls es nicht existiert
if [ ! -d "$DATA_DIR" ]; then
    mkdir -p "$DATA_DIR" || error_exit "Konnte Data-Verzeichnis nicht erstellen."
fi

# Prüfe ob CSV-Datei beschreibbar ist (oder erstellt werden kann)
if [ -f "$CSV_FILE" ] && [ ! -w "$CSV_FILE" ]; then
    error_exit "CSV-Datei ist nicht beschreibbar. Bitte Berechtigungen prüfen."
fi

# Prüfe ob XML-Datei beschreibbar ist (oder erstellt werden kann)
if [ -f "$XML_FILE" ] && [ ! -w "$XML_FILE" ]; then
    error_exit "XML-Datei ist nicht beschreibbar. Bitte Berechtigungen prüfen."
fi

# Verbesserte URL-Decodierung Funktion
url_decode() {
    local url_encoded="$1"
    # + durch Leerzeichen ersetzen
    url_encoded="${url_encoded//+/ }"
    # %XX durch entsprechende Zeichen ersetzen
    printf '%b' "${url_encoded//%/\\x}" 2>/dev/null || echo "$1"
}

# HTML-Escape Funktion
html_escape() {
    local text="$1"
    # Leere Eingaben als leerer String zurückgeben
    if [ -z "$text" ]; then
        echo ""
        return
    fi
    echo "$text" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g'
}

# CSV-Escape Funktion (für Anführungszeichen und Zeilenumbrüche)
csv_escape() {
    local text="$1"
    # Leere Eingaben als leere Anführungszeichen behandeln
    [ -z "$text" ] && echo "\"\"" && return
    # Anführungszeichen verdoppeln und in Anführungszeichen einschließen
    text="${text//\"/\"\"}"
    echo "\"$text\""
}

# Sicherheitsprüfung: Entferne gefährliche Zeichen
sanitize_input() {
    local input="$1"
    # Entferne Steuerzeichen und potenziell gefährliche Zeichen
    echo "$input" | tr -d '\000-\037' | sed 's/[<>]//g'
}

# Query-String lesen
QUERY_STRING="${QUERY_STRING:-}"

# Wenn kein Query-String vorhanden, aus stdin lesen (für GET-Requests)
if [ -z "$QUERY_STRING" ]; then
    read -r QUERY_STRING || true
fi

# Aktuelles Datum
DATUM=$(date +"%Y-%m-%d %H:%M:%S")

# Variablen initialisieren
TYP=""
NAME=""
CSV_LINE=""
XML_ENTRY=""

# Query-Parameter parsen
IFS='&' read -ra PARAMS <<< "$QUERY_STRING"
declare -A VALUES

for param in "${PARAMS[@]}"; do
    # Leere Parameter überspringen
    [ -z "$param" ] && continue
    # Parameter in Key und Value aufteilen
    if [[ "$param" == *"="* ]]; then
        IFS='=' read -r key value <<< "$param"
        # URL-decodieren und sanitizen
        key=$(url_decode "$key")
        value=$(url_decode "$value")
        key=$(sanitize_input "$key")
        value=$(sanitize_input "$value")
        VALUES["$key"]="$value"
    else
        # Parameter ohne Wert (nur Key)
        key=$(url_decode "$param")
        key=$(sanitize_input "$key")
        VALUES["$key"]=""
    fi
done

# Formular-Typ erkennen
if [ -n "${VALUES[nameL]}" ]; then
    TYP="Lara"
    NAME="${VALUES[nameL]}"
    
    # Validierung: Mindestens Name muss vorhanden sein
    if [ -z "$NAME" ]; then
        error_exit "Name ist erforderlich."
    fi
    
    # CSV-Zeile für Lara erstellen (mit CSV-Escaping, leere Felder für Marco-Spalten)
    CSV_LINE="$TYP,$(csv_escape "$NAME"),$(csv_escape "${VALUES[Buch1]}"),$(csv_escape "${VALUES[Autor1]}"),$(csv_escape "${VALUES[Warum1]}"),$(csv_escape "${VALUES[Buch2]}"),$(csv_escape "${VALUES[Autor2]}"),$(csv_escape "${VALUES[Warum2]}"),$(csv_escape "${VALUES[Buch3]}"),$(csv_escape "${VALUES[Autor3]}"),$(csv_escape "${VALUES[Warum3]}"),$(csv_escape ""),$(csv_escape ""),$(csv_escape ""),$(csv_escape ""),$(csv_escape ""),$(csv_escape "$DATUM")"
    
    # XML-Eintrag für Lara erstellen
    XML_ENTRY="  <eingabe>
    <nameL>$(html_escape "${VALUES[nameL]}")</nameL>
    <buch1>$(html_escape "${VALUES[Buch1]}")</buch1>
    <autor1>$(html_escape "${VALUES[Autor1]}")</autor1>
    <warum1>$(html_escape "${VALUES[Warum1]}")</warum1>
    <buch2>$(html_escape "${VALUES[Buch2]}")</buch2>
    <autor2>$(html_escape "${VALUES[Autor2]}")</autor2>
    <warum2>$(html_escape "${VALUES[Warum2]}")</warum2>
    <buch3>$(html_escape "${VALUES[Buch3]}")</buch3>
    <autor3>$(html_escape "${VALUES[Autor3]}")</autor3>
    <warum3>$(html_escape "${VALUES[Warum3]}")</warum3>
    <datum>$(html_escape "$DATUM")</datum>
  </eingabe>"
    
elif [ -n "${VALUES[nameM]}" ]; then
    TYP="Marco"
    NAME="${VALUES[nameM]}"
    
    # Validierung: Mindestens Name muss vorhanden sein
    if [ -z "$NAME" ]; then
        error_exit "Name ist erforderlich."
    fi
    
    # CSV-Zeile für Marco erstellen (mit CSV-Escaping, leere Felder für Lara-Spalten)
    CSV_LINE="$TYP,$(csv_escape "$NAME"),$(csv_escape ""),$(csv_escape ""),$(csv_escape ""),$(csv_escape ""),$(csv_escape ""),$(csv_escape ""),$(csv_escape ""),$(csv_escape ""),$(csv_escape ""),$(csv_escape "${VALUES[ticker]}"),$(csv_escape "${VALUES[sektor]}"),$(csv_escape "${VALUES[investmentThese]}"),$(csv_escape "${VALUES[chance]}"),$(csv_escape "${VALUES[risiko]}"),$(csv_escape "${VALUES[upside]}"),$(csv_escape "$DATUM")"
    
    # XML-Eintrag für Marco erstellen
    XML_ENTRY="  <eingabe>
    <nameM>$(html_escape "${VALUES[nameM]}")</nameM>
    <ticker>$(html_escape "${VALUES[ticker]}")</ticker>
    <sektor>$(html_escape "${VALUES[sektor]}")</sektor>
    <investmentThese>$(html_escape "${VALUES[investmentThese]}")</investmentThese>
    <chance>$(html_escape "${VALUES[chance]}")</chance>
    <risiko>$(html_escape "${VALUES[risiko]}")</risiko>
    <upside>$(html_escape "${VALUES[upside]}")</upside>
    <datum>$(html_escape "$DATUM")</datum>
  </eingabe>"
else
    # Fehler: Unbekannter Formular-Typ
    error_exit "Unbekannter Formular-Typ. Bitte verwenden Sie das Lara- oder Marco-Formular."
fi

# CSV-Zeile zur Datei hinzufügen (mit Fehlerbehandlung)
# Header hinzufügen, falls Datei neu erstellt wird
if [ ! -f "$CSV_FILE" ] || [ ! -s "$CSV_FILE" ]; then
    echo "Typ,Name,Buch1,Autor1,Warum1,Buch2,Autor2,Warum2,Buch3,Autor3,Warum3,Ticker,Sektor,InvestmentThese,Chance,Risiko,Upside,Datum" > "$CSV_FILE" || error_exit "Fehler beim Erstellen der CSV-Datei. Bitte Berechtigungen prüfen."
fi
if ! echo "$CSV_LINE" >> "$CSV_FILE" 2>/dev/null; then
    error_exit "Fehler beim Schreiben in die CSV-Datei. Bitte Berechtigungen prüfen."
fi

# XML-Eintrag zur Datei hinzufügen (vor dem schließenden Tag)
if [ -f "$XML_FILE" ]; then
    # Letzte Zeile (</formulareingaben>) entfernen, Eintrag hinzufügen, dann wieder schließen
    if ! sed -i'' '$ d' "$XML_FILE" 2>/dev/null && ! sed -i '$ d' "$XML_FILE" 2>/dev/null; then
        error_exit "Fehler beim Bearbeiten der XML-Datei. Bitte Berechtigungen prüfen."
    fi
    if ! echo "$XML_ENTRY" >> "$XML_FILE" 2>/dev/null; then
        error_exit "Fehler beim Schreiben in die XML-Datei. Bitte Berechtigungen prüfen."
    fi
    echo "</formulareingaben>" >> "$XML_FILE"
else
    # XML-Datei neu erstellen
    if ! cat > "$XML_FILE" << EOF 2>/dev/null; then
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE formulareingaben SYSTEM "formulareingaben.dtd">
<formulareingaben version="1.0">
$XML_ENTRY
</formulareingaben>
EOF
        error_exit "Fehler beim Erstellen der XML-Datei. Bitte Berechtigungen prüfen."
    fi
    # DTD-Datei in data-Verzeichnis kopieren, falls sie dort noch nicht existiert
    if [ ! -f "$DTD_FILE" ] && [ -f "$BASE_DIR/formulareingaben.dtd" ]; then
        cp "$BASE_DIR/formulareingaben.dtd" "$DTD_FILE" 2>/dev/null || true
    fi
fi

# HTML-Response zurückgeben
echo "Content-Type: text/html; charset=UTF-8"
echo ""
cat << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Eingabe gespeichert</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 600px; margin: 50px auto; padding: 20px; }
        h1 { color: #333; }
        .success { background-color: #d4edda; border: 1px solid #c3e6cb; padding: 15px; border-radius: 5px; margin: 20px 0; }
        a { color: #007bff; text-decoration: none; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <h1>Eingabe erfolgreich gespeichert!</h1>
    <div class="success">
        <p><strong>Typ:</strong> $TYP</p>
        <p><strong>Name:</strong> $(html_escape "$NAME")</p>
        <p><strong>Datum:</strong> $DATUM</p>
    </div>
    <p><a href="../index.html">Zurück zur Startseite</a></p>
    <p><a href="../html/Lara.html">Zurück zu Lara</a> | <a href="../html/Marco.html">Zurück zu Marco</a></p>
</body>
</html>
EOF
