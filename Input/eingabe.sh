#!/bin/bash

# Shell-Skript zur Verarbeitung von Formular-Eingaben
# Speichert Daten in CSV und XML

# Pfade relativ zum Skript-Verzeichnis
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
CSV_FILE="$BASE_DIR/formulareingaben.csv"
XML_FILE="$BASE_DIR/formulareingaben.xml"
DTD_FILE="$BASE_DIR/formulareingaben.dtd"

# URL-Decodierung Funktion
url_decode() {
    local url_encoded="${1//+/ }"
    printf '%b' "${url_encoded//%/\\x}"
}

# HTML-Escape Funktion
html_escape() {
    echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g'
}

# Query-String lesen
QUERY_STRING="${QUERY_STRING:-}"

# Wenn kein Query-String vorhanden, aus stdin lesen (für GET-Requests)
if [ -z "$QUERY_STRING" ]; then
    read -r QUERY_STRING
fi

# Aktuelles Datum
DATUM=$(date +"%Y-%m-%d %H:%M:%S")

# Variablen initialisieren
TYP=""
NAME=""

# Query-Parameter parsen
IFS='&' read -ra PARAMS <<< "$QUERY_STRING"
declare -A VALUES

for param in "${PARAMS[@]}"; do
    IFS='=' read -r key value <<< "$param"
    key=$(url_decode "$key")
    value=$(url_decode "$value")
    VALUES["$key"]="$value"
done

# Formular-Typ erkennen
if [ -n "${VALUES[nameL]}" ]; then
    TYP="Lara"
    NAME="${VALUES[nameL]}"
    
    # CSV-Zeile für Lara erstellen
    CSV_LINE="$TYP,\"$NAME\",\"${VALUES[Buch1]}\",\"${VALUES[Autor1]}\",\"${VALUES[Warum1]}\",\"${VALUES[Buch2]}\",\"${VALUES[Autor2]}\",\"${VALUES[Warum2]}\",\"${VALUES[Buch3]}\",\"${VALUES[Autor3]}\",\"${VALUES[Warum3]}\",,,,,\"$DATUM\""
    
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
    
    # CSV-Zeile für Marco erstellen
    CSV_LINE="$TYP,\"$NAME\",,,,,,,,,\"${VALUES[ticker]}\",\"${VALUES[sektor]}\",\"${VALUES[investmentThese]}\",\"${VALUES[chance]}\",\"${VALUES[risiko]}\",\"${VALUES[upside]}\",\"$DATUM\""
    
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

fi

# CSV-Zeile zur Datei hinzufügen
echo "$CSV_LINE" >> "$CSV_FILE"

# XML-Eintrag zur Datei hinzufügen (vor dem schließenden Tag)
if [ -f "$XML_FILE" ]; then
    # Letzte Zeile (</formulareingaben>) entfernen, Eintrag hinzufügen, dann wieder schließen
    sed -i'' '$ d' "$XML_FILE" 2>/dev/null || sed -i '$ d' "$XML_FILE"
    echo "$XML_ENTRY" >> "$XML_FILE"
    echo "</formulareingaben>" >> "$XML_FILE"
else
    # XML-Datei neu erstellen
    cat > "$XML_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE formulareingaben SYSTEM "formulareingaben.dtd">
<formulareingaben version="1.0">
$XML_ENTRY
</formulareingaben>
EOF
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
