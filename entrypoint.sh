#!/bin/bash
server_path=/mnt/vrising/server
data_path=/mnt/vrising/data
echo "Setting timezone to $TZ"
echo $TZ > /etc/timezone 2>&1
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime 2>&1
dpkg-reconfigure -f noninteractive tzdata 2>&1
if [ ! -z $UID ]; then
  usermod -u $UID docker 2>&1
fi 
if [ ! -z $GID ]; then
  groupmod -g $GID docker 2>&1
fi
mkdir -p /root/.steam 2>/dev/null
chmod -R 777 /root/.steam 2>/dev/null
echo " "
echo "Updating V-Rising Dedicated Server files..."
echo " "
/usr/bin/steamcmd +force_install_dir "$server_path" +login anonymous +app_update 1829350 +quit
echo "steam_appid: "`cat $server_path/steam_appid.txt`
echo " "
mkdir "$data_path/Settings" 2>/dev/null
if [ ! -f "$data_path/Settings/ServerHostSettings.json" ]; then
  echo "$data_path/Settings/ServerHostSettings.json not found. Copying default file."
  cp "$server_path/VRisingServer_Data/StreamingAssets/Settings/ServerHostSettings.json" "$data_path/Settings/" 2>&1
fi
for var in "${!VRisingHost_@}"; do
  IFS='_' read -r -a path <<< "$var"
  path=${path[@]:1}
  echo "Overrinding Host setting .${path// /.}: ${!var}"
  cat <<< $( jq ".${path// /.} = ${!var}" "$data_path/Settings/ServerHostSettings.json" ) > "$data_path/Settings/ServerHostSettings.json"
done
if [ ! -f "$data_path/Settings/ServerGameSettings.json" ]; then
  echo "$data_path/Settings/ServerGameSettings.json not found. Copying default file."
  cp "$server_path/VRisingServer_Data/StreamingAssets/Settings/ServerGameSettings.json" "$data_path/Settings/" 2>&1
fi
for var in "${!VRisingGame_@}"; do
  IFS='_' read -r -a path <<< "$var"
  path=${path[@]:1}
  echo "Overrinding Game setting .${path// /.}: ${!var}"
  cat <<< $( jq ".${path// /.} = ${!var}" "$data_path/Settings/ServerGameSettings.json" ) > "$data_path/Settings/ServerGameSettings.json"
done
cd "$server_path"
echo "Starting V Rising Dedicated Server with name $VRisingHost_Name"
echo "Trying to remove /tmp/.X0-lock"
rm /tmp/.X0-lock 2>&1
echo " "
echo "Starting Xvfb"
Xvfb :0 -screen 0 1024x768x16 &
echo "Launching wine64 V Rising { Name: $VRisingHost_Name, Port: $VRisingHost_Port, QueryPort: $VRisingHost_QueryPort }"
echo " "
DISPLAY=:0.0 wine64 /mnt/vrising/server/VRisingServer.exe -persistentDataPath $data_path -serverName "$VRisingHost_Name" -saveName "$VRisingHost_SaveName" -logFile "$data_path/VRisingServer.log" "$VRisingHost_Port" "$VRisingHost_QueryPort" 2>&1
/usr/bin/tail -f /mnt/vrising/persistentdata/VRisingServer.log