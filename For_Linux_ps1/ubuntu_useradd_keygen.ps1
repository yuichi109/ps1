#For Ubuntu Useradd sshkey gen
#$USERと $TGTIPを対象に合わせてくください
$USER="username"    #changeme
$TGTIP="10.10.10.10"    #changeme
$KEYPATH=[Environment]::GetFolderPath('MyDocuments') + "\KEY-GEN"
$TGT="/home/${USER}/.ssh"
$PUBKEY="$KEYPATH\$USER.pub"

mkdir $KEYPATH -force
ssh-keygen -N '""' -m PEM -f $KEYPATH\$USER
cat $PUBKEY | ssh user@${TGTIP} "sudo -S adduser ${USER} --disabled-password --gecos '""';\
sudo -S mkdir -p ${TGT};\
sudo -S chown ${USER}:${USER} ${TGT};\
sudo -S tee -a ${TGT}/authorized_keys;\
sudo -S chown ${USER}:${USER} ${TGT}/authorized_keys;\
sudo -S chmod 600 ${TGT}/authorized_keys"