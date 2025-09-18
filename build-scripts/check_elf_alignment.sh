#!/bin/bash
progname="${0##*/}"
progname="${progname%.sh}"

# usage: check_elf_alignment.sh [path to *.so files|path to *.apk]

cleanup_trap() {
  if [ -n "${tmp}" -a -d "${tmp}" ]; then
    rm -rf ${tmp}
  fi
  exit $1
}

usage() {
  echo "Host side script to check the ELF alignment of shared libraries."
  echo "Shared libraries are reported ALIGNED when their ELF regions are"
  echo "16 KB or 64 KB aligned. Otherwise they are reported as UNALIGNED."
  echo
  echo "Usage: ${progname} [input-path|input-APK|input-APEX]"
}

if [ ${#} -ne 1 ]; then
  usage
  exit
fi

case ${1} in
  --help | -h | -\?)
    usage
    exit
    ;;

  *)
    dir="${1}"
    ;;
esac

if ! [ -f "${dir}" -o -d "${dir}" ]; then
  echo "Invalid file: ${dir}" >&2
  exit 1
fi

if [[ "${dir}" == *.apk ]]; then
  trap 'cleanup_trap' EXIT

  echo
  echo "Recursively analyzing $dir"
  echo

  if { zipalign --help 2>&1 | grep -q "\-P <pagesize_kb>"; }; then
    echo "=== APK zip-alignment (64 bit libs) ==="
    zipalign -v -c -P 16 4 "${dir}" | egrep 'lib/arm64-v8a|lib/x86_64|Verification'
    echo "========================="
  else
    echo "NOTICE: Zip alignment check requires build-tools version 35.0.0-rc3 or higher."
    echo "  You can install the latest build-tools by running the below command"
    echo "  and updating your \$PATH:"
    echo
    echo "    sdkmanager \"build-tools;35.0.0-rc3\""
  fi

  dir_filename=$(basename "${dir}")
  tmp=$(mktemp -d -t "${dir_filename%.apk}_out_XXXXX")
  unzip "${dir}" lib/* -d "${tmp}" >/dev/null 2>&1
  dir="${tmp}"
fi

if [[ "${dir}" == *.apex ]]; then
  trap 'cleanup_trap' EXIT

  echo
  echo "Recursively analyzing $dir"
  echo

  dir_filename=$(basename "${dir}")
  tmp=$(mktemp -d -t "${dir_filename%.apex}_out_XXXXX")
  deapexer extract "${dir}" "${tmp}" || { echo "Failed to deapex." && exit 1; }
  dir="${tmp}"
fi

RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"
ARCHITECTURE_64=("arm64-v8a" "x86_64")

unaligned_32_bit_libs=()
aligned_64_bit_libs=()
unaligned_64_bit_libs=()

echo
echo "=== ELF alignment ==="

matches="$(find "${dir}" -type f)"
IFS=$'\n'
for match in $matches; do
  # We could recursively call this script or rewrite it to though.
  [[ "${match}" == *".apk" ]] && echo "WARNING: doesn't recursively inspect .apk file: ${match}"
  [[ "${match}" == *".apex" ]] && echo "WARNING: doesn't recursively inspect .apex file: ${match}"

  [[ $(file "${match}") == *"ELF"* ]] || continue

  # Check if this is a 64-bit architecture (arm64-v8a or x86_64)
  is_64_bit=false
  for arch in "${ARCHITECTURE_64[@]}"; do
      if [[ "${match}" == *"$arch"* ]]; then
          is_64_bit=true
          break
      fi
  done

  res="$(objdump -p "${match}" | grep LOAD | awk '{ print $NF }' | head -1)"
  if [[ $res =~ 2\*\*(1[4-9]|[2-9][0-9]|[1-9][0-9]{2,}) ]]; then
    if $is_64_bit; then
      aligned_64_bit_libs+=("${match}")
    fi

    echo -e "${match}: ${GREEN}ALIGNED${ENDCOLOR} ($res)"
  else
    if $is_64_bit; then
      unaligned_64_bit_libs+=("${match}")
      echo -e "${match}: ${RED}UNALIGNED${ENDCOLOR} ($res)"
    else
      unaligned_32_bit_libs+=("${match}")
      echo -e "${match}: UNALIGNED ($res)"
    fi
  fi
done

# Exit with appropriate code: 1 if no 64-bit libs were found
if [[ ${#aligned_64_bit_libs[@]} -eq 0 ]] && [[ ${#unaligned_64_bit_libs[@]} -eq 0 ]]; then
  echo -e "${RED}Found no 64-bit (${ARCHITECTURE_64[@]}) libs.${ENDCOLOR}"
  echo -e "${RED}ELF Verification Failed${ENDCOLOR}"
  echo "====================="
  exit 1
fi

echo -e "${GREEN}Found ${#aligned_64_bit_libs[@]} aligned 64-bit (${ARCHITECTURE_64[@]}) libs.${ENDCOLOR}"

# Exit with appropriate code: 1 if any unaligned 64-bit libs were found
if [ ${#unaligned_64_bit_libs[@]} -gt 0 ]; then
  echo -e "${RED}Found ${#unaligned_64_bit_libs[@]} unaligned 64-bit (${ARCHITECTURE_64[@]}) libs.${ENDCOLOR}"
  echo -e "${RED}ELF Verification Failed${ENDCOLOR}"
  echo "====================="
  exit 1
fi

if [ ${#unaligned_32_bit_libs[@]} -gt 0 ]; then
  echo -e "Found ${#unaligned_32_bit_libs[@]} unaligned 32-bit libs (which do not need to be aligned)."
fi

echo -e "${GREEN}ELF Verification Successful${ENDCOLOR}"
echo "====================="

# Exit with appropriate code: 0 if 64-bit libs were present and were aligned
exit 0
