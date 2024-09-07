#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

_unix2dos() {
vim -e "${1}" << EOF
set ff=dos
wq!
EOF
}

set -e

_tmp_dir="$(mktemp -d)"
cd "${_tmp_dir}"

wget -c -t 9 -T 9 'https://trials.adobe.com/AdobeProducts/APRO/Acrobat_HelpX/win32/Acrobat_DC_Web_x64_WWMUI.zip' -O Acrobat_DC_Web_x64_WWMUI.zip

_patch_release_note="$(curl 'https://www.adobe.com/devnet-docs/acrobatetk/tools/ReleaseNotesDC/index.html#installers' 2>&1 | grep -i '<link rel="next" title=.*" href="continuous/' | sed 's/"/\n/g' | grep -i '^continuous/dccontinuous.*20[23][0-9].*.html')"
_msp_url="$(curl "https://www.adobe.com/devnet-docs/acrobatetk/tools/ReleaseNotesDC/${_patch_release_note}" 2>&1 | grep -i 'Windows installers (64-bit)' -A 30 | grep -i 'https://.*/AcrobatDC' | sed 's|"|\n|g' | sed 's/^[ \t]//g' | sed 's/[ \t]*$//g' | grep -i 'https://.*/AcrobatDC.*.msp' | sort -V | uniq | tail -n 1)"
wget -c -t 9 -T 9 "${_msp_url}"

_old_file='Acrobat_DC_Web_x64_WWMUI.zip'
lastmsp="$(ls -1 AcrobatDC*.msp | sort -V | tail -n 1)"
echo
ls -la --color "${_old_file}"
ls -la --color "${lastmsp}"
echo
_MAJOR_ver="$(ls -1 ${lastmsp} | sort -V | tail -n 1 | sed 's|x64||' | tr -dc '0-9' | cut -c 1-2)"
_MINOR_ver="$(ls -1 ${lastmsp} | sort -V | tail -n 1 | sed 's|x64||' | tr -dc '0-9' | cut -c 3-5 | sed 's/^0*//g')"
_PATCH_ver="$(ls -1 ${lastmsp} | sort -V | tail -n 1 | sed 's|x64||' | tr -dc '0-9' | cut -c 6- | sed 's/^0*//g')"
echo "Version ${_MAJOR_ver}.${_MINOR_ver}.${_PATCH_ver}"
echo
mkdir Acrobat_DC_x64_${_MAJOR_ver}.${_MINOR_ver}.${_PATCH_ver}
cd Acrobat_DC_x64_${_MAJOR_ver}.${_MINOR_ver}.${_PATCH_ver}/
7z x -mmt2 ../"${_old_file}"
sleep 1
[[ -d "Adobe Acrobat" ]] && mv -v "Adobe Acrobat" Acrobat
rm -vfr Acrobat/AcrobatDC*.msp
sleep 1
cp -vfr ../"${lastmsp}" Acrobat/

echo 'old patch:'
grep --color=always -i '^PATCH=' Acrobat/setup.ini
sed "s@PATCH=Acrobat.*.msp@PATCH=${lastmsp}@g" -i Acrobat/setup.ini
sleep 1
echo 'new patch:'
grep --color=always -i '^PATCH=' Acrobat/setup.ini
echo
cd ../

echo
ls -lah --color
echo
7z a -mmt2 -tzip /tmp/"Acrobat_DC_x64_${_MAJOR_ver}.${_MINOR_ver}.${_PATCH_ver}".zip "Acrobat_DC_x64_${_MAJOR_ver}.${_MINOR_ver}.${_PATCH_ver}"
sleep 5
cd /tmp
sha256sum "Acrobat_DC_x64_${_MAJOR_ver}.${_MINOR_ver}.${_PATCH_ver}".zip > "Acrobat_DC_x64_${_MAJOR_ver}.${_MINOR_ver}.${_PATCH_ver}".zip.sha256

cd /tmp
rm -fr "${_tmp_dir}"
echo
echo ' done '
echo
exit
