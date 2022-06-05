#!/bin/bash
server_path=/mnt/vrising/server
data_path=/mnt/vrising/data
echo "Setting timezone to $TZ"
echo $TZ > /etc/timezone
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
dpkg-reconfigure -f noninteractive tzdata
if [ ! -z $UID ]; then
  usermod -u $UID docker
fi 
if [ ! -z $GID ]; then
  groupmod -g $GID docker
fi
if [ -z $ServerName ]; then
	ServerName="SyterVRisingServer"
fi
if [ -z $WorldName  ]; then
	WorldName="world1"
fi
host_port=""
if [ ! -z $VRisingHost_Port ]; then
	host_port=" -gamePort $VRisingHost_Port"
fi
host_query_port=""
if [ ! -z $VRisingHost_QueryPort ]; then
	host_query_port=" -queryPort $VRisingHost_QueryPort"
fi
mkdir -p /root/.steam
chmod -R 777 /root/.steam
echo " "
echo "Updating V-Rising Dedicated Server files..."
echo " "
/usr/bin/steamcmd +force_install_dir "$server_path" +login anonymous +app_update 1829350 +quit
echo "steam_appid: "`cat $server_path/steam_appid.txt`
echo " "
mkdir "$data_path/Settings"
if [ ! -f "$data_path/Settings/ServerHostSettings.json" ]; then
  echo "$data_path/Settings/ServerHostSettings.json not found. Copying default file."
  cp "$server_path/VRisingServer_Data/StreamingAssets/Settings/ServerHostSettings.json" "$data_path/Settings/"
fi
for var in "${!VRisingHost_@}"; do
  IFS='_' read -r -a path <<< "$var"
  path=${path[@]:1}
  echo "Overrinding Host setting .${path// /.}: ${!var}"
  cat <<< $( jq ".${path// /.} = ${!var}" "$data_path/Settings/ServerHostSettings.json" ) > "$data_path/Settings/ServerHostSettings.json"
done
if [ ! -f "$data_path/Settings/ServerGameSettings.json" ]; then
  echo "$data_path/Settings/ServerGameSettings.json not found. Copying default file."
  cp "$server_path/VRisingServer_Data/StreamingAssets/Settings/ServerGameSettings.json" "$data_path/Settings/"
fi
for var in "${!VRisingGame_@}"; do
  IFS='_' read -r -a path <<< "$var"
  path=${path[@]:1}
  echo "Overrinding Game setting .${path// /.}: ${!var}"
  cat <<< $( jq ".${path// /.} = ${!var}" "$data_path/Settings/ServerGameSettings.json" ) > "$data_path/Settings/ServerGameSettings.json"
done
cd "$server_path"
echo "Starting V Rising Dedicated Server with name $ServerName"
echo "Trying to remove /tmp/.X0-lock"
rm /tmp/.X0-lock
echo " "
echo "Starting Xvfb"
Xvfb :0 -screen 0 1024x768x16 &
echo "Launching wine64 V Rising { Name: $ServerName, SaveName: $WorldName, Port: $VRisingHost_Port, QueryPort: $VRisingHost_QueryPort }"
echo " "
DISPLAY=:0.0 wine64 "$server_path/VRisingServer.exe" -persistentDataPath $data_path -serverName "$ServerName" -saveName "$WorldName" -logFile "$data_path/VRisingServer.log" "$host_port" "$host_query_port"
/usr/bin/tail -f "$data_path/VRisingServer.log"