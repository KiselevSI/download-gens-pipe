#!/bin/bash
# Скрипт для скачивания полных геномов из NCBI по списку accession’ов.
# Использование: ./download_genomes.sh -i accessions.txt -o output_dir

# Обработка аргументов командной строки
while getopts ":i:o:" opt; do
    case $opt in
        i) ACCESSION_FILE="$OPTARG" ;;
        o) OUTPUT_DIR="$OPTARG" ;;
        \?) echo "Неверный флаг: -$OPTARG" >&2; exit 1 ;;
        :) echo "Опция -$OPTARG требует аргумента." >&2; exit 1 ;;
    esac
done

# Проверка обязательных аргументов
if [ -z "$ACCESSION_FILE" ] || [ -z "$OUTPUT_DIR" ]; then
    echo "Использование: $0 -i accessions.txt -o output_dir"
    exit 1
fi

# Создание выходной директории, если не существует
mkdir -p "$OUTPUT_DIR"

ASSEMBLY_SUMMARY="assembly_summary_refseq.txt"

# Если файл с описанием сборок не существует, скачиваем его
if [ ! -f "$ASSEMBLY_SUMMARY" ]; then
    echo "Скачиваем assembly summary файл..."
    wget ftp://ftp.ncbi.nlm.nih.gov/genomes/ASSEMBLY_REPORTS/assembly_summary_refseq.txt
    if [ $? -ne 0 ]; then
        echo "Ошибка скачивания assembly summary файла. Проверьте соединение."
        exit 1
    fi
fi

# Обработка каждого accession’а из входного файла
while read -r accession; do
    # Пропускаем пустые строки или строки, начинающиеся с #
    if [[ -z "$accession" || "$accession" == \#* ]]; then
        continue
    fi
    echo "Обрабатываем accession: $accession"

    # Ищем строку, содержащую нужный accession (точное совпадение)
    line=$(grep -w "$accession" "$ASSEMBLY_SUMMARY")
    if [ -z "$line" ]; then
        echo "Сборка с accession $accession не найдена в assembly summary файле."
        continue
    fi

    # Извлекаем FTP-ссылку (последний столбец, разделённый табуляцией)
    ftp_path=$(echo "$line" | awk -F "\t" '{print $20}')
    if [ -z "$ftp_path" ]; then
        echo "FTP-ссылка не найдена для accession $accession."
        continue
    fi

    # Получаем file_prefix для формирования URL (но не для имени папки)
    file_prefix=$(basename "$ftp_path")

    # Создаём поддиректорию для данного генома, используя accession из входного файла
    genome_dir="$OUTPUT_DIR/$accession"
    mkdir -p "$genome_dir"

    # Формируем URL для скачивания полного генома (FASTA, сжатый gzip-ом)
    file_url="$ftp_path/${file_prefix}_genomic.fna.gz"
    echo "Обрабатываем URL: $file_url"

    # Проверяем, существует ли уже файл, и если нет, скачиваем его
    if [ ! -f "$genome_dir/${accession}_genomic.fna.gz" ]; then
        wget -O "$genome_dir/${accession}_genomic.fna.gz" "$file_url"
        if [ $? -eq 0 ]; then
            echo "Скачивание сборки $accession успешно завершено и сохранено в $genome_dir."
        else
            echo "Ошибка при скачивании сборки $accession!"
        fi
    else
        echo "Файл уже существует, пропускаем скачивание."
    fi
    echo "---------------------------------------------"
done < "$ACCESSION_FILE"
