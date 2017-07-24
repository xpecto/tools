# mattermost updater
#
# running in ~/mattermost/
# data in    ~/mattermost_data/
# backup in  ~/mattermost_bak/

# query running version
VOLD=$(egrep -o "[0-9\.]+" ~/mattermost/version.txt)
echo $VOLD

# query available version
VNEW=$(wget -O- https://docs.mattermost.com/administration/changelog.html --no-check-certificate | egrep -o 'Release v([0-9\.]+)'  | sort -V  | tail -1 | egrep -o "[0-9\.]+")
echo $VNEW

read -rsp $"Press enter to update from $VOLD to $VNEW\n"

# query db settings
USER=$(cat ~/mattermost/config/config.json | jq .SqlSettings.DataSource | egrep -o "[[:alnum:]]+" | head -1 | tail -1)
PASS=$(cat ~/mattermost/config/config.json | jq .SqlSettings.DataSource | egrep -o "[[:alnum:]]+" | head -2 | tail -1)
DB=$(cat ~/mattermost/config/config.json | jq .SqlSettings.DataSource | egrep -o "[[:alnum:]]+" | head -6 | tail -1)

# backup running                     (to ~/mattermost_bak/mattermost-X.X.X/)
cd ~/mattermost_bak/
rm -R mattermost-$VOLD
mkdir mattermost-$VOLD
mv ~/mattermost/* ~/mattermost_bak/mattermost-$VOLD/
mysqldump -u$USER -p$PASS $DB > ~/mattermost_bak/mattermost-$VOLD/dbdump.sql

# download and unpack                (to ~/mattermost_bak/mattermost-update/)
cd ~/mattermost_bak/
rm -R mattermost-update
wget --no-check-certificate wget https://releases.mattermost.com/$VNEW/mattermost-team-$VNEW-linux-amd64.tar.gz
tar xfz mattermost-team-$VNEW-linux-amd64.tar.gz
rm mattermost-team-$VNEW-linux-amd64.tar.gz
mv mattermost mattermost-update

# install
mv ~/mattermost_bak/mattermost-update/* ~/mattermost/
cp ~/mattermost_bak/mattermost-$VOLD/config/config.json ~/mattermost/config/config.json
echo $VNEW > ~/mattermost/version.txt

# done
echo you need to stop/start mattermost
