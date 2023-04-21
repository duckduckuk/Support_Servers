If you have forgotten your password and need to reset it here is how you do it. This depends on what database you are using. If you have two docker containers one of which is a database, you are using MySQL, if you just have the single npm docker container, you probably use the SQLite database. Since November of 2021, the example docker-compose file is using SQLite, prior to that is was MySQL.
SQLite (default since November 2021)
Step 1

Run these commands on the machine running the docker container containing the database but replacing <container-name> with the name of the docker container containing your npm instance (It will most likely be something like nginxproxymanager_core):

docker exec -it <container-name> sh
apt update && apt install sqlite3 -y
sqlite3 /data/database.sqlite

You have now entered the SQL mode, where you set the status of all users to deleted:

UPDATE user SET is_deleted=1;
.exit
exit

Step 2

If your NPM container has been running, restart it. If it has not been running, start it now.
Step 3

You have now created an admin user you can login with by accessing your NPM in the browser and logging in with the default login information:
login: admin@example.com
pass: changeme
Step 4

You can now either just use this user, or you can re-enable the old account and use the new account to change the password of the old one. To re-enable it, once again execute the following commands:

docker exec -it <container-name> sh
sqlite3 /data/database.sqlite

Replace <container-name> again, as in step 1. Then set all users to not deleted by running:

UPDATE user SET is_deleted=0;
.exit
exit

MySQL (default prior to November 2021)
Step 1

Run these commands on the machine running the docker container containing the database but replacing <container-name> with the name of the docker container containing your database (It will most likely be something like nginxproxymanager_db_1):

docker exec -it <container-name> sh
mysql -u root -p

You will have to enter the root password of your database. You have set it in your docker-compose file through the MYSQL_ROOT_PASSWORD variable. Then continue entering the following commands:

USE npm;
UPDATE user SET is_deleted=1;
quit
exit

Step 2

If your NPM container has been running, restart it. If it has not been running, start it now.
Step 3

You have now created an admin user you can login with by accessing your NPM in the browser and logging in with the default login information:
login: admin@example.com
pass: changeme
Step 4

You can now either just use this user, or you can re-enable the old account and use the new account to change the password of the old one. To re-enable all previously disabled users, once again execute the following commands:

docker exec -it <container-name> sh
mysql -u root -p

Replace <container-name> and enter the root password again, as in step 1.

USE npm;
UPDATE user SET is_deleted=0;
quit
exit
