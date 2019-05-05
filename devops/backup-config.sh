
cd

for t in bampfa botgarden ucjeps pahma cinefiles
do 
  cd ~/$t
  mkdir -p ~/backup/$t/config
  cp -p config/*.cfg ~/backup/$t/config/
  cp -p config/*.csv ~/backup/$t/config/
  cp -p config/*.xml ~/backup/$t/config/
  cp -p config/*.json ~/backup/$t/config/
  grep -r xxxx ~/backup/
  #grep -r -i prod ~/backup
done
