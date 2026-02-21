#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
TZ='UTC'; export TZ
umask 022

_install_7z() {
    set -euo pipefail
    local _tmp_dir="$(mktemp -d)"
    cd "${_tmp_dir}"
    #_7zip_loc="$(wget -qO- 'https://www.7-zip.org/download.html' | grep -i '\-linux-x64.tar' | grep -i 'href="' | sed 's|"|\n|g' | grep -i '\-linux-x64.tar' | sort -V | tail -n 1)"
    #wget -q -c -t 9 -T 9 "https://www.7-zip.org/${_7zip_loc}"
    #tar -xof *.tar*
    #sleep 1
    #rm -f *.tar*
    #file 7zzs | sed -n -E 's/^(.*):[[:space:]]*ELF.*, not stripped.*/\1/p' | xargs --no-run-if-empty -I '{}' strip '{}'
    #rm -f 7z && mv 7zzs 7z
    wget -q -c -t 9 -T 9 'https://github.com/icebluey/7zip-zstd/releases/latest/download/7z.tar'
    wget -q -c -t 9 -T 9 'https://github.com/icebluey/7zip-zstd/releases/latest/download/7z.tar.sha256'
    sha256sum -c 7z.tar.sha256
    tar -xof 7z.tar
    rm -f /usr/bin/7z /usr/local/bin/7z
    install -v -c -m 0755 7z /usr/bin/7z
    cp -f /usr/bin/7z /usr/local/bin/7z
    /usr/bin/7z --version 2>/dev/null || true
    cd /tmp
    rm -fr "${_tmp_dir}"
}
_install_7z

set -euo pipefail
_tmp_dir="$(mktemp -d)"
cd "${_tmp_dir}"
wget -q -c -t 9 -T 9 'https://trials.adobe.com/AdobeProducts/APRO/Acrobat_HelpX/win32/Acrobat_DC_Web_x64_WWMUI.zip'
/bin/ls -la
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
echo " old MSP patch: ${_org_msp_ver:0:2}.${_org_msp_ver:2:3}.${_org_msp_ver:5:2}.${_org_msp_ver:7}"
echo " new MSP patch: ${_new_msp_ver:0:2}.${_new_msp_ver:2:3}.${_new_msp_ver:5:2}.${_new_msp_ver:7}"
echo '###################################'
echo
if [ "${_new_msp_ver}" -gt "${_org_msp_ver}" ]; then
    wget -q -c -t 9 -T 9 "${_msp_url}"
    /bin/ls -la
    sleep 2
    _new_msp_filename="$(/bin/ls -1 AcrobatDCx64Upd*.msp | sort -V | tail -n1)"
    rm -fv AdobeAcrobat/AcrobatDCx64Upd*.msp
    mv -fv AcrobatDCx64Upd*.msp AdobeAcrobat/
    sed "s@PATCH=Acrobat.*.msp@PATCH=${_new_msp_filename}@g" -i AdobeAcrobat/setup.ini
    _patch_ver="${_new_msp_ver}"
else
    _patch_ver="${_org_msp_ver}"
fi
/bin/ls -la AdobeAcrobat/
cat AdobeAcrobat/setup.ini | grep '^PATCH='
sleep 2
/usr/bin/7z a -mmt$(($(nproc) - 1)) -mx9 -t7z "Acrobat_DC_Web_x64_WWMUI-${_patch_ver}.7z" AdobeAcrobat
sleep 2
sha256sum -b "Acrobat_DC_Web_x64_WWMUI-${_patch_ver}.7z" > "Acrobat_DC_Web_x64_WWMUI-${_patch_ver}.7z".sha256
rm -fr AdobeAcrobat
rm -fr /tmp/_output
mkdir /tmp/_output
mv -f *.7z* /tmp/_output/
sleep 1
/bin/ls -la /tmp/_output/
cd /tmp
rm -fr "${_tmp_dir}"
echo ' done'
exit
