#!/bin/bash
clear

###############################
#
# Parametros:
#  - Lista Dominios y URL
#
# Tareas:
#  - Crear la estructura de directorios adecuada
#  - Generar los archivos de logs requeridos.
#
###############################

# Archivo con la lista de dominios y URLs
LISTA=$1

# Log global para registrar el estado HTTP de todas las URLs
LOG_FILE="/var/log/status_url.log"

# Crear estructura de directorios base
BASE_DIR="/tmp/head-check"
OK_DIR="$BASE_DIR/ok"
ERROR_DIR="$BASE_DIR/Error"
CLIENTE_DIR="$ERROR_DIR/cliente"
SERVIDOR_DIR="$ERROR_DIR/servidor"

# Crear la estructura de directorios
sudo mkdir -p "$OK_DIR" "$CLIENTE_DIR" "$SERVIDOR_DIR"

# Guardar el estado previo de IFS (Internal Field Separator)
ANT_IFS=$IFS
IFS=$'\n'

# Iterar sobre cada línea del archivo LISTA, comenzando desde la segunda línea (ignorando encabezados)

for LINEA in `cat $LISTA |  grep -v ^#` 
do
     DOMINIO=$(echo $LINEA |awk '{print $1}')
     URL=$(echo $LINEA | awk '{print $2}')
     

     # Obtener el código de estado HTTP de la URL
     STATUS_CODE=$(curl -LI -o /dev/null -w '%{http_code}\n' -s "$URL")

     # Fecha y hora actual en formato yyyymmdd_hhmmss
     TIMESTAMP=$(date +"%Y%m%d_%H%M%S") 

     # Determinar el directorio según el código de estado
     if [ "$STATUS_CODE" -eq 200 ]; then
	  TARGET_DIR="$OK_DIR"
     elif [ "$STATUS_CODE" -ge 400 ] && [ "$STATUS_CODE" -le 499 ]; then
          TARGET_DIR="$CLIENTE_DIR"
     elif [ "$STATUS_CODE" -ge 500 ] && [ "$STATUS_CODE" -le 599 ]; then
          TARGET_DIR="$SERVIDOR_DIR"
     else			              
# Si el código de estado no entra en ninguna de las categorías anteriores, se pone en OK por defecto
          TARGET_DIR="$OK_DIR"         
      fi

  # Crear el archivo de log para el dominio en el directorio correspondiente
     DOMINIO_LOG="$TARGET_DIR/$DOMINIO.log"
     echo "$TIMESTAMP - Code:$STATUS_CODE - URL:$URL" |sudo tee -a "$DOMINIO_LOG"

  # Registrar en el archivo global de logs
     echo "$TIMESTAMP - Code:$STATUS_CODE - URL:$URL" |sudo tee -a "$LOG_FILE"
done


# Restaurar el valor original de IFS
IFS=$ANT_IFS
