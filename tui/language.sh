#!/bin/env bash

message="
Please select a language:
"

active_language="English"
available_languages=(English French)

whiptail_args=(
  --title "Open Voice OS Installation - Language"
  --radiolist "$message"
  --cancel-button "Exit"
  25 80 "${#available_languages[@]}"
)

for language in "${available_languages[@]}"; do
  whiptail_args+=("$language" "")
  if [[ $language = "$active_language" ]]; then
    whiptail_args+=("on")
  else
    whiptail_args+=("off")
  fi
done

# Retrieve language and make it lower case with "@L"
language=$(whiptail "${whiptail_args[@]}" 3>&1 1>&2 2>&3)
language="${language@L}"

if [ -z "$language" ]; then
  exit 0
fi

# Hash of locales
declare -A locales
locales=(["english"]="en-us" ["french"]="fr-fr")
export LOCALE="${locales[$language]}"
