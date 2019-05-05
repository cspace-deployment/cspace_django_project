cd /var/www
rm */*/*.pyc
for x in bampfa botgarden cinefiles pahma ucjeps; do tar czf ~/$x.tgz $x ; done
cd ~
mkdir tgz
mv *.tgz tgz
tar czvf all5.tgz tgz
rm -rf tgz
