#!/bin/bash

API_KEY="302fe8d70896eaa32da38c93b91545c1"
BASE_URL="http://api.openweathermap.org/data/2.5/weather"
ICON_BASE_URL="http://openweathermap.org/img/wn"

# Şehir Bilgisi Al
CITY=$(zenity --entry --title="City Input" --text="Enter the city name:")
if [ -z "$CITY" ]; then
  zenity --error --title="Error" --text="City name cannot be empty."
  exit 1
fi

# Sıcaklık Birimi Al
TEMP_UNIT=$(zenity --list --radiolist --title="Select Temperature Unit" \
    --column="Select" --column="Unit" TRUE "Celsius" FALSE "Fahrenheit")
if [[ "$TEMP_UNIT" == "Celsius" ]]; then
  UNIT="metric"
  UNIT_SYMBOL="°C"
else
  UNIT="imperial"
  UNIT_SYMBOL="°F"
fi

# Hava Durumu Bilgisi Al
RESPONSE=$(curl -s "${BASE_URL}?q=${CITY}&appid=${API_KEY}&units=${UNIT}")
if [[ $(echo "$RESPONSE" | jq -r '.cod') != "200" ]]; then
  ERROR_MESSAGE=$(echo "$RESPONSE" | jq -r '.message')
  zenity --error --title="Error" --text="Failed to fetch weather data: $ERROR_MESSAGE"
  exit 1
fi

# Hava Durumu Bilgilerini Çözümle
WEATHER=$(echo "$RESPONSE" | jq -r '.weather[0].description')
TEMP=$(echo "$RESPONSE" | jq -r '.main.temp')
ICON=$(echo "$RESPONSE" | jq -r '.weather[0].icon')
SUNRISE=$(date -d "@$(echo "$RESPONSE" | jq -r '.sys.sunrise')" +"%H:%M:%S")
SUNSET=$(date -d "@$(echo "$RESPONSE" | jq -r '.sys.sunset')" +"%H:%M:%S")

# İkonu İndir ve Kaydet
ICON_PATH="$(pwd)/icon_iconset/${ICON}.png"
if [[ ! -f "$ICON_PATH" ]]; then
  mkdir -p "$(pwd)/icon_iconset"
  curl -s "${ICON_BASE_URL}/${ICON}@2x.png" -o "$ICON_PATH"
fi

# Sonuçları Göster
RESULT="Weather: $WEATHER\nTemperature: $TEMP$UNIT_SYMBOL\nSunrise: $SUNRISE\nSunset: $SUNSET"
zenity --info --title="Weather Info" --text="$RESULT" --window-icon="$ICON_PATH"

# Kaydetme Seçeneği Sun
zenity --question --title="Save Weather Info" --text="Do you want to save the weather information?"
if [[ $? -eq 0 ]]; then
  LOG_FILE="weather_log.txt"
  echo -e "City: $CITY\n$RESULT\n" >> "$LOG_FILE"
  zenity --info --title="Saved" --text="Weather information saved to $LOG_FILE"
fi