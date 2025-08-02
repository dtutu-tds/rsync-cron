#!/bin/bash

# Скрипт автоматического резервного копирования домашней директории
# Создает зеркальную копию в /tmp/backup с исключением скрытых файлов

# Настройки
SOURCE_DIR="$HOME/"
BACKUP_DIR="/tmp/backup"
LOG_TAG="backup_home"

# Функция логирования
log_message() {
    local level="$1"
    local message="$2"
    logger -t "$LOG_TAG" "$level: $message"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$LOG_TAG] $level: $message"
}

# Проверка существования исходной директории
if [ ! -d "$SOURCE_DIR" ]; then
    log_message "ERROR" "Исходная директория $SOURCE_DIR не существует"
    exit 1
fi

# Создание целевой директории если она не существует
if [ ! -d "$BACKUP_DIR" ]; then
    log_message "INFO" "Создание целевой директории $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Не удалось создать целевую директорию $BACKUP_DIR"
        exit 2
    fi
fi

# Проверка прав доступа к целевой директории
if [ ! -w "$BACKUP_DIR" ]; then
    log_message "ERROR" "Нет прав записи в целевую директорию $BACKUP_DIR"
    exit 3
fi

log_message "INFO" "Начало резервного копирования из $SOURCE_DIR в $BACKUP_DIR"

# Выполнение rsync с параметрами согласно требованиям
rsync --archive \
      --delete \
      --exclude='.*' \
      --checksum \
      --verbose \
      "$SOURCE_DIR" \
      "$BACKUP_DIR"

# Проверка результата выполнения rsync
RSYNC_EXIT_CODE=$?

case $RSYNC_EXIT_CODE in
    0)
        log_message "SUCCESS" "Резервное копирование завершено успешно"
        ;;
    1)
        log_message "ERROR" "Синтаксические ошибки или ошибки использования rsync"
        exit 4
        ;;
    2)
        log_message "ERROR" "Ошибки протокола rsync"
        exit 5
        ;;
    23)
        log_message "WARNING" "Частичная передача - некоторые файлы не были переданы"
        ;;
    *)
        log_message "ERROR" "Неизвестная ошибка rsync (код: $RSYNC_EXIT_CODE)"
        exit 6
        ;;
esac

# Подсчет статистики
if [ -d "$BACKUP_DIR" ]; then
    BACKUP_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
    FILE_COUNT=$(find "$BACKUP_DIR" -type f 2>/dev/null | wc -l)
    log_message "INFO" "Статистика: размер резервной копии $BACKUP_SIZE, количество файлов: $FILE_COUNT"
fi

log_message "INFO" "Скрипт резервного копирования завершен"
exit $RSYNC_EXIT_CODE