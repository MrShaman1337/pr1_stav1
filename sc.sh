#!/bin/bash

# Инициализация переменных
error_occurred=false
log_path=""
error_path=""
command=""

# Функция для отображения справки
show_help() {
    cat << EOF
Использование: $0 [опции]

Опции:
  -h, --help        Показать это сообщение
  -u, --users       Показать список пользователей и их домашние директории
  -p, --processes   Показать список процессов с их PID
  -l PATH           Перенаправить вывод в файл
  -e PATH           Перенаправить ошибки в файл

Пример:
  $0 -u
  $0 --help
EOF
}

# Функция для вывода списка пользователей
list_users() {
    cut -d: -f1,6 /etc/passwd 2>/dev/null || {
        echo "Ошибка: Не удалось получить список пользователей." >&2
        error_occurred=true
    }
}

# Функция для вывода списка процессов
list_processes() {
    ps -eo pid,cmd --sort=pid 2>/dev/null || {
        echo "Ошибка: Не удалось получить список процессов." >&2
        error_occurred=true
    }
}

# Обработка аргументов командной строки
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -u|--users)
            command="users"
            ;;
        -p|--processes)
            command="processes"
            ;;
        -l)
            log_path="$2"
            shift  # Перейти к следующему аргументу
            ;;
        -e)
            error_path="$2"
            shift  # Перейти к следующему аргументу
            ;;
        *)
            echo "Неизвестный аргумент: $1" >&2
            show_help
            exit 1
            ;;
    esac
    shift  # Переход к следующему аргументу
done

# Функция для перенаправления ошибок
redirect_errors() {
    if [[ -n "$error_path" ]]; then
        if [[ -w "$(dirname "$error_path")" || ! -e "$error_path" ]]; then
            exec 2>"$error_path"
        else
            echo "Ошибка: Нет прав на запись в $error_path." >&2
            exit 1
        fi
    fi
}

# Функция для перенаправления вывода
redirect_output() {
    if [[ -n "$log_path" ]]; then
        if [[ -w "$(dirname "$log_path")" || ! -e "$log_path" ]]; then
            exec >"$log_path"
        else
            echo "Ошибка: Нет прав на запись в $log_path." >&2
            exit 1
        fi
    fi
}

# Перенаправление ошибок, если задан флаг -e
if [[ -n "$error_path" ]]; then
    redirect_errors
    echo "Ошибки не обнаружены, завершение скрипта."
    exit 0
fi

# Перенаправление вывода, если задан флаг -l
redirect_output

# Выполнение команд
if [[ -n "$command" && "$error_occurred" == false ]]; then
    case "$command" in
        "users")
            list_users
            ;;
        "processes")
            list_processes
            ;;
        *)
            echo "Команда не указана. Используйте -h для справки." >&2
            exit 1
            ;;
    esac
fi

# Если ошибок не было и лог не требуется
if [[ -z "$error_path" && "$error_occurred" == false ]]; then
    echo "Ошибки не обнаружены, завершение скрипта."
    exit 0
fi
