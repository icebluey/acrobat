#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
TZ='UTC'; export TZ
umask 022

_install_7z() {
    set -euo pipefail
    local _tmp_dir="$(mktemp -d)"
    cd "${_tmp_dir}"
    _7zip_loc=$(wget -qO- 'https://www.7-zip.org/download.html' | grep -i '\-linux-x64.tar' | grep -i 'href="' | sed 's|"|\n|g' | grep -i '\-linux-x64.tar' | sort -V | tail -n 1)
    #_7zip_ver=$(echo ${_7zip_loc} | sed -e 's|.*7z||g' -e 's|-linux.*||g')
    wget -c -t 9 -T 9 "https://www.7-zip.org/${_7zip_loc}"
    sleep 1
    tar -xof *.tar*
    sleep 1
    rm -f *.tar*
    find 7zzs -type f -exec file '{}' \; | sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | xargs --no-run-if-empty -I '{}' strip '{}'
    rm -f /usr/bin/7z
    rm -f /usr/local/bin/7z
    install -v -c -m 0755 7zzs /usr/bin/7z
    cd /tmp
    rm -fr "${_tmp_dir}"
}
_install_7z

set -euo pipefail
_tmp_dir="$(mktemp -d)"
cd "${_tmp_dir}"
wget -c -t 9 -T 9 'https://trials.adobe.com/AdobeProducts/APRO/Acrobat_HelpX/win32/Acrobat_DC_Web_x64_WWMUI.zip'
sleep 2
/usr/bin/7z x Acrobat_DC_Web_x64_WWMUI.zip
sleep 2
rm -f Acrobat_DC_Web_x64_WWMUI.zip
/bin/ls -la
mv *cro* .1.tmp
sleep 1
mv .1.tmp AdobeAcrobat
/bin/ls -la

_org_msp_ver=$(ls -1 AdobeAcrobat/AcrobatDCx64Upd*.msp | sort -V | tail -n1 | sed -e 's|.*Upd||g' -e 's|\.msp.*||g')
_patch_release_note="$(curl 'https://www.adobe.com/devnet-docs/acrobatetk/tools/ReleaseNotesDC/index.html#installers' 2>&1 | grep -i '<link rel="next" title=.*" href="continuous/' | sed 's/"/\n/g' | grep -i '^continuous/dccontinuous.*20[23][0-9].*.html')"
_msp_url="$(curl "https://www.adobe.com/devnet-docs/acrobatetk/tools/ReleaseNotesDC/${_patch_release_note}" 2>&1 | grep -i 'Windows installers (64-bit)' -A 30 | grep -i 'https://.*/AcrobatDC' | sed 's|"|\n|g' | sed 's/^[ \t]//g' | sed 's/[ \t]*$//g' | grep -i 'https://.*/AcrobatDC.*.msp' | sort -V | uniq | tail -n1)"
_new_msp_ver=$(echo "${_msp_url}" | sed -e 's|.*Upd||g' -e 's|\.msp.*||g')
echo
echo '###################################'
echo "original MSP patch: ${_org_msp_ver}"
echo "new MSP patch: ${_new_msp_ver}"
echo '###################################'
echo
if [ "${_new_msp_ver}" -gt "${_org_msp_ver}" ]; then
    wget -c -t 9 -T 9 "${_msp_url}"
    sleep 2
    _new_msp_filename="$(ls -1 AcrobatDCx64Upd*.msp | sort -V | tail -n1)"
    rm -f AdobeAcrobat/AcrobatDCx64Upd*.msp
    mv -fv AcrobatDCx64Upd*.msp AdobeAcrobat/
    sed "s@PATCH=Acrobat.*.msp@PATCH=${_new_msp_filename}@g" -i AdobeAcrobat/setup.ini
    _patch_ver="${_new_msp_ver}"
else
    _patch_ver="${_org_msp_ver}"
fi
/bin/ls -la AdobeAcrobat/
cat AdobeAcrobat/setup.ini | grep '^PATCH='
sleep 2
/usr/bin/7z a -r -mmt=$(nproc) -tzip "Acrobat_DC_Web_x64_WWMUI-${_patch_ver}.zip" AdobeAcrobat
sleep 2
openssl dgst -r -sha256 "Acrobat_DC_Web_x64_WWMUI-${_patch_ver}.zip" > "Acrobat_DC_Web_x64_WWMUI-${_patch_ver}.zip".sha256
rm -fr AdobeAcrobat
rm -fr /tmp/_output
mkdir /tmp/_output
mv -f *.zip* /tmp/_output/
sleep 1
cd /tmp
rm -fr "${_tmp_dir}"
echo ' done'
exit

