#!/bin/bash
# Скрипт для скачивания последовательностей фагов по списку id.
# Использование: ./download_phages.sh -i phage_ids.txt -o output_dir
# Файл phage_ids.txt должен содержать один id (например, NC_003288) на строку.

# Обработка аргументов командной строки
while getopts ":i:o:" opt; do
    case $opt in
        i) PHAGE_ID_FILE="$OPTARG" ;;
        o) OUTPUT_DIR="$OPTARG" ;;
        \?) echo "Неверный флаг: -$OPTARG" >&2; exit 1 ;;
        :) echo "Опция -$OPTARG требует аргумента." >&2; exit 1 ;;
    esac
done

# Проверка обязательных аргументов
if [ -z "$PHAGE_ID_FILE" ] || [ -z "$OUTPUT_DIR" ]; then
    echo "Использование: $0 -i phage_ids.txt -o output_dir"
    exit 1
fi

# Создание выходной директории, если не существует
mkdir -p "$OUTPUT_DIR"

# Обработка каждого id фага из входного файла
while read -r phage_id; do
    # Пропускаем пустые строки или строки, начинающиеся с #
    if [[ -z "$phage_id" || "$phage_id" == \#* ]]; then
        continue
    fi
    echo "Обрабатываем фаг: $phage_id"

    # Создаём поддиректорию с именем id из входного файла
    phage_dir="$OUTPUT_DIR/$phage_id"
    mkdir -p "$phage_dir"

    # Определяем имя файла для сохранения последовательности в формате FASTA
    output_file="$phage_dir/${phage_id}.fasta"

    # Если файл ещё не существует, скачиваем его с помощью NCBI efetch
    if [ ! -f "$output_file" ]; then
        wget -O "$output_file" "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=${phage_id}&rettype=fasta&retmode=text"
        if [ $? -eq 0 ]; then
            echo "Скачивание фага $phage_id успешно завершено."
        else
            echo "Ошибка при скачивании фага $phage_id!"
        fi
    else
        echo "Файл уже существует, пропускаем скачивание."
    fi
    echo "---------------------------------------------"
done < "$PHAGE_ID_FILE"
