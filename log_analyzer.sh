#!/bin/bash

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Параметры по умолчанию
top_n=5
filter_date=""
logfile=""
output_file=""
debug=0

# Функция для справки
usage() {
    echo -e "${BLUE}Использование: $0 [-t top_n] [-d date] [-o output_file] [-D] <logfile>${NC}"
    echo "  -t top_n          Количество записей для вывода (по умолчанию 5)"
    echo "  -d date           Фильтрация по дате (например, '05/Feb/2025')"
    echo "  -o output_file    Сохранить результат в файл"
    echo "  -D                Включить режим отладки"
    echo "  <logfile>         Путь к лог-файлу"
    exit 1
}

# Обработка опций
while getopts "t:d:o:D" opt; do
    case $opt in
        t) top_n="$OPTARG" ;;
        d) filter_date="$OPTARG" ;;
        o) output_file="$OPTARG" ;;
        D) debug=1 ;;
        *) usage ;;
    esac
done

# Получаем последний аргумент как путь к лог-файлу
shift $((OPTIND - 1))
logfile="$1"

# Проверка на наличие лог-файла
if [ -z "$logfile" ] || [ ! -f "$logfile" ]; then
    echo -e "${RED}Ошибка: Укажите корректный лог-файл.${NC}"
    usage
fi

# Если включён режим отладки, выводим параметры
if [ $debug -eq 1 ]; then
    echo -e "${BLUE}Режим отладки включён...${NC}"
    echo "logfile: $logfile"
    echo "top_n: $top_n"
    echo "filter_date: $filter_date"
    echo "output_file: $output_file"
fi

# Если указана дата, фильтруем лог по дате
if [ -n "$filter_date" ]; then
    logfile="<(grep \"$filter_date\" $logfile)"
    if [ $debug -eq 1 ]; then
        echo "Фильтрация по дате: $filter_date"
    fi
fi

# Функция для вывода результатов
print_and_save() {
    local title="$1"
    local data="$2"

    # Вывод на экран
    echo -e "${GREEN}$title${NC}"
    echo -e "$data"

    # Сохранение в файл, если указан output_file
    if [ -n "$output_file" ]; then
        echo -e "$title" >> "$output_file"
        echo -e "$data" >> "$output_file"
        echo -e "\n" >> "$output_file"
    fi
}

# Топ-5 IP-адресов с наибольшим количеством запросов
top_ips=$(awk '{print $1}' "$logfile" | sort | uniq -c | sort -nr | head -n "$top_n" | awk '{print $2 " - " $1 " запросов"}')
print_and_save "Топ-$top_n IP-адресов с наибольшим количеством запросов:" "$top_ips"

# Топ-5 самых запрашиваемых путей
top_paths=$(awk -F'"' '{print $2}' "$logfile" | awk '{print $2}' | sort | uniq -c | sort -nr | head -n "$top_n" | awk '{print $2 " - " $1 " запросов"}')
print_and_save "Топ-$top_n самых запрашиваемых путей:" "$top_paths"

# Топ-5 кодов ответа
top_status_codes=$(awk '{print $9}' "$logfile" | sort | uniq -c | sort -nr | head -n "$top_n" | awk '{print $2 " - " $1 " запросов"}')
print_and_save "Топ-$top_n кодов ответа:" "$top_status_codes"

# Топ-5 пользовательских агентов
top_user_agents=$(awk -F'"' '{print $6}' "$logfile" | sort | uniq -c | sort -nr | head -n "$top_n" | awk '{print $2 " - " $1 " запросов"}')
print_and_save "Топ-$top_n пользовательских агентов:" "$top_user_agents"

# Завершаем скрипт
if [ -n "$output_file" ]; then
    echo -e "${GREEN}Результаты сохранены в файл: $output_file${NC}"
fi
