
# gemini
gemini_path="/mnt/c/Users/dgoudene/Dev_prog/gemini"
backup_folder="/mnt/c/Users/dgoudene/Dev_prog/archive/gemini_bak"
mkdir -p ${backup_folder}
current_date=$(date +"%d-%m-%y")
backup_archive="${backup_folder}/gemini_${current_date}.tar.gz"
echo "GEMINI BACKUP => ${backup_archive}"
cd ${gemini_path}
tar --exclude='__pycache__' --exclude='desktop.ini' -czf ${backup_archive} *


# bashy
bashy_path="/mnt/c/Users/dgoudene/Dev_prog/bashy"
backup_folder="/mnt/c/Users/dgoudene/Dev_prog/archive/bashy_bak"
mkdir -p ${backup_folder}
current_date=$(date +"%d-%m-%y")
backup_archive="${backup_folder}/bashy_${current_date}.tar.gz"
echo "BASHY BACKUP => ${backup_archive}"
cd ${bashy_path}
tar --exclude='desktop.ini' -czf ${backup_archive} *