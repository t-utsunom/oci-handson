#!/bin/bash

# OCIDとリージョン識別子を対話的に入力
read -p "テナンシのOCIDを入力してください: " tenancy_ocid
read -p "使用するリージョンの識別子を入力してください（ap-tokyo-1, ap-osaka-1など）: " region
echo -e "\n処理中...\n"

# JSON出力の準備
echo "[" > temp_handson_limits.json
first_entry=true

# サービス制限をOCI CLIで取得してJSONに追記
commands=(
    "oci limits value list --service-name compartments --name compartment-count -c $tenancy_ocid --region $region"
    "oci limits value list --service-name vcn --name vcn-count -c $tenancy_ocid --region $region"
    "oci limits value list --service-name compute --name standard-e5-core-count -c $tenancy_ocid --region $region"
    "oci limits value list --service-name compute --name standard-e5-memory-count -c $tenancy_ocid --region $region"
    "oci limits value list --service-name compute --name standard-e4-core-count -c $tenancy_ocid --region $region"
    "oci limits value list --service-name compute --name standard-e4-memory-count -c $tenancy_ocid --region $region"
    "oci limits value list --service-name block-storage --name total-storage-gb -c $tenancy_ocid --region $region"
    "oci limits value list --service-name block-storage --name volume-count -c $tenancy_ocid --region $region"
    "oci limits value list --service-name object-storage --name bucket-count -c $tenancy_ocid --region $region"
    "oci limits value list --service-name object-storage --name storage-bytes -c $tenancy_ocid --region $region"
    "oci limits value list --service-name database --name vm-standard-e5-ocpu-count -c $tenancy_ocid --region $region"
    "oci limits value list --service-name database --name vm-standard-e4-ocpu-count -c $tenancy_ocid --region $region"
    "oci limits value list --service-name database --name vm-standard3-ocpu-count -c $tenancy_ocid --region $region"
)

for cmd in "${commands[@]}"; do
    if [ "$first_entry" = false ]; then
        echo "," >> temp_handson_limits.json
    fi
    $cmd | jq -c '.data[]' >> temp_handson_limits.json
    first_entry=false
done

echo "]" >> temp_handson_limits.json

# PythonでJSONからnameとvalueの値を抽出してCSVに書き出し
python3 - << EOF
import json
import csv

# JSONデータを直接読み取る
with open("temp_handson_limits.json", "r") as json_file:
    data = json.load(json_file)

# CSV出力
csv_filename = "result_handson_limits.csv"
with open(csv_filename, mode="w", newline="") as csvfile:
    csv_writer = csv.writer(csvfile)
    csv_writer.writerow(["limit-name", "value"])  # ヘッダー行

    for item in data:
        name = item.get("name")
        value = item.get("value")
        csv_writer.writerow([name, value])

# CSVの内容を表示
with open(csv_filename, mode="r") as csvfile:
    for row in csv.reader(csvfile):
        print(f"{row[0]}: {row[1]}")

print(f" \nCSVファイル:{csv_filename}に出力しました。")

EOF

# JSON出力ファイルを削除
rm temp_handson_limits.json
