sudo docker exec -it vaultwarden /vaultwarden hash --preset owaspdocker exec -it vwcontainer /vaultwarden hash --preset owasp

echo 'PASSWORD IN HERE' | sed 's#\$#\$\$#g'
