#!/bin/zsh
set -euo pipefail

config_dir="$HOME/.config/karabiner/assets/complex_modifications"
config_file="$config_dir/windows-left-ctrl-shortcuts.json"

mkdir -p "$config_dir"

# 这里必须保留双反斜杠，因为该字符串最终要写入 JSON。
excluded_apps='^(com\\.apple\\.Terminal|com\\.googlecode\\.iterm2|dev\\.warp\\..*|com\\.mitchellh\\.ghostty|com\\.github\\.wez\\.wezterm|org\\.alacritty|net\\.kovidgoyal\\.kitty|co\\.zeit\\.hyper|org\\.tabby.*|com\\.parallels\\..*|com\\.vmware\\..*|org\\.virtualbox\\.app\\..*|com\\.utmapp\\..*|com\\.microsoft\\.rdc\\.macos.*|com\\.citrix\\..*|com\\.philandro\\.anydesk|com\\.carriez\\.RustDesk|com\\.teamviewer\\..*)$'

keys=(c x v a z f s w)

tmp_file="$(mktemp "${config_file}.XXXXXX")"
trap 'rm -f "$tmp_file"' EXIT

{
  cat <<'JSON_HEADER'
{
  "title": "Windows-like left Ctrl shortcuts",
  "rules": [
    {
      "description": "左 Ctrl+C/X/V/A/Z/F/S/W → Command；排除终端、虚拟机和远程桌面",
      "manipulators": [
JSON_HEADER

  separator=""

  for key in "${keys[@]}"; do
    print -rn -- "$separator"
    separator=","

    cat <<JSON_MANIPULATOR
        {
          "type": "basic",
          "from": {
            "key_code": "$key",
            "modifiers": {
              "mandatory": [
                "left_control"
              ]
            }
          },
          "to": [
            {
              "key_code": "$key",
              "modifiers": [
                "left_command"
              ]
            }
          ],
          "conditions": [
            {
              "type": "frontmost_application_unless",
              "bundle_identifiers": [
                "$excluded_apps"
              ]
            }
          ]
        }
JSON_MANIPULATOR
  done

  cat <<'JSON_FOOTER'

      ]
    }
  ]
}
JSON_FOOTER
} > "$tmp_file"

mv "$tmp_file" "$config_file"

echo "配置已经生成："
echo "$config_file"
echo
echo "下一步："
echo "1. 打开 Karabiner-Elements"
echo "2. 进入 Complex Modifications"
echo "3. 点击 Add predefined rule"
echo "4. 启用“左 Ctrl+C/X/V/A/Z/F/S/W → Command”规则"
