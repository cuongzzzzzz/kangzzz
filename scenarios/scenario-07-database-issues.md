# Tình huống 7: Database Issues - Cơ Sở Dữ Liệu Bị Lỗi

## 🚨 Mô tả tình huống
- Database không thể kết nối
- Queries chạy rất chậm hoặc timeout
- Database bị lock, không thể ghi dữ liệu
- Database service không start được
- Data corruption hoặc mất dữ liệu
- Replication lag hoặc failover issues

## 🔍 Các bước chẩn đoán

### Bước 1: Kiểm tra database service
```bash
# MySQL
sudo systemctl status mysql
sudo systemctl is-active mysql
sudo systemctl is-enabled mysql

# PostgreSQL
sudo systemctl status postgresql
sudo systemctl is-active postgresql
sudo systemctl is-enabled postgresql

# MongoDB
sudo systemctl status mongod
sudo systemctl is-active mongod
sudo systemctl is-enabled mongod
```

### Bước 2: Kiểm tra database logs
```bash
# MySQL logs
sudo tail -f /var/log/mysql/error.log
sudo journalctl -u mysql -f

# PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-*.log
sudo journalctl -u postgresql -f

# MongoDB logs
sudo tail -f /var/log/mongodb/mongod.log
sudo journalctl -u mongod -f
```

### Bước 3: Kiểm tra database connectivity
```bash
# MySQL connection test
mysql -u root -p -e "SELECT 1;"
mysql -u <username> -p -h <host> -e "SELECT 1;"

# PostgreSQL connection test
psql -U postgres -c "SELECT 1;"
psql -U <username> -h <host> -c "SELECT 1;"

# MongoDB connection test
mongo --eval "db.runCommand('ping')"
mongo <host>:<port>/<database> --eval "db.runCommand('ping')"
```

## 🛠️ Các nguyên nhân thường gặp và cách giải quyết

### 1. Database service không start
```bash
# MySQL
sudo systemctl start mysql
sudo systemctl restart mysql
sudo systemctl enable mysql

# PostgreSQL
sudo systemctl start postgresql
sudo systemctl restart postgresql
sudo systemctl enable postgresql

# MongoDB
sudo systemctl start mongod
sudo systemctl restart mongod
sudo systemctl enable mongod

# Kiểm tra config files
sudo mysql --help | grep -A 1 "Default options"
sudo -u postgres psql -c "SHOW config_file;"
sudo mongod --config /etc/mongod.conf --help
```

### 2. Database connection issues
```bash
# Kiểm tra port listening
sudo netstat -tulpn | grep :3306  # MySQL
sudo netstat -tulpn | grep :5432  # PostgreSQL
sudo netstat -tulpn | grep :27017 # MongoDB

# Kiểm tra firewall
sudo ufw status
sudo ufw allow 3306/tcp  # MySQL
sudo ufw allow 5432/tcp  # PostgreSQL
sudo ufw allow 27017/tcp # MongoDB

# Kiểm tra bind address
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
# bind-address = 0.0.0.0

sudo nano /etc/postgresql/*/main/postgresql.conf
# listen_addresses = '*'
```

### 3. Database performance issues
```bash
# MySQL - xem processes
mysql -u root -p -e "SHOW PROCESSLIST;"
mysql -u root -p -e "SHOW FULL PROCESSLIST;"

# Kill slow queries
mysql -u root -p -e "KILL <query_id>;"

# Xem slow queries
mysql -u root -p -e "SHOW VARIABLES LIKE 'slow_query_log';"
mysql -u root -p -e "SHOW VARIABLES LIKE 'long_query_time';"

# PostgreSQL - xem active queries
psql -U postgres -c "SELECT pid, now() - pg_stat_activity.query_start AS duration, query FROM pg_stat_activity WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes';"

# Kill query PostgreSQL
psql -U postgres -c "SELECT pg_terminate_backend(<pid>);"
```

### 4. Database lock issues
```bash
# MySQL - xem locks
mysql -u root -p -e "SHOW ENGINE INNODB STATUS\G"
mysql -u root -p -e "SELECT * FROM information_schema.INNODB_LOCKS;"
mysql -u root -p -e "SELECT * FROM information_schema.INNODB_LOCK_WAITS;"

# Kill locked processes
mysql -u root -p -e "KILL <process_id>;"

# PostgreSQL - xem locks
psql -U postgres -c "SELECT * FROM pg_locks;"
psql -U postgres -c "SELECT * FROM pg_stat_activity WHERE state = 'active';"
```

### 5. Database corruption
```bash
# MySQL - check tables
mysql -u root -p -e "CHECK TABLE <table_name>;"
mysql -u root -p -e "REPAIR TABLE <table_name>;"

# MySQL - check database
mysqlcheck -u root -p --check <database_name>
mysqlcheck -u root -p --repair <database_name>

# PostgreSQL - check database
psql -U postgres -c "SELECT datname FROM pg_database WHERE datname = '<database_name>';"
psql -U postgres -c "VACUUM ANALYZE;"

# MongoDB - check database
mongo <database_name> --eval "db.runCommand('dbStats')"
mongo <database_name> --eval "db.runCommand('repairDatabase')"
```

### 6. Replication issues
```bash
# MySQL - xem replication status
mysql -u root -p -e "SHOW MASTER STATUS;"
mysql -u root -p -e "SHOW SLAVE STATUS\G"

# Start/stop replication
mysql -u root -p -e "START SLAVE;"
mysql -u root -p -e "STOP SLAVE;"

# Reset replication
mysql -u root -p -e "RESET SLAVE;"
mysql -u root -p -e "CHANGE MASTER TO MASTER_HOST='<master_host>', MASTER_USER='<user>', MASTER_PASSWORD='<password>', MASTER_LOG_FILE='<log_file>', MASTER_LOG_POS=<position>;"

# PostgreSQL - xem replication status
psql -U postgres -c "SELECT * FROM pg_stat_replication;"
psql -U postgres -c "SELECT * FROM pg_replication_slots;"
```

## 🚀 Các lệnh khôi phục nhanh

### Emergency database recovery
```bash
# 1. Restart database service
sudo systemctl restart mysql
sudo systemctl restart postgresql
sudo systemctl restart mongod

# 2. Check service status
sudo systemctl status mysql
sudo systemctl status postgresql
sudo systemctl status mongod

# 3. Test connection
mysql -u root -p -e "SELECT 1;"
psql -U postgres -c "SELECT 1;"
mongo --eval "db.runCommand('ping')"
```

### Database optimization
```bash
# MySQL - optimize tables
mysql -u root -p -e "OPTIMIZE TABLE <table_name>;"
mysql -u root -p -e "ANALYZE TABLE <table_name>;"

# MySQL - clear query cache
mysql -u root -p -e "FLUSH QUERY CACHE;"
mysql -u root -p -e "RESET QUERY CACHE;"

# PostgreSQL - vacuum và analyze
psql -U postgres -c "VACUUM ANALYZE;"
psql -U postgres -c "REINDEX DATABASE <database_name>;"

# MongoDB - compact database
mongo <database_name> --eval "db.runCommand('compact')"
```

### Database backup và restore
```bash
# MySQL backup
mysqldump -u root -p <database_name> > backup.sql
mysqldump -u root -p --all-databases > full_backup.sql

# MySQL restore
mysql -u root -p <database_name> < backup.sql
mysql -u root -p < full_backup.sql

# PostgreSQL backup
pg_dump -U postgres <database_name> > backup.sql
pg_dumpall -U postgres > full_backup.sql

# PostgreSQL restore
psql -U postgres <database_name> < backup.sql
psql -U postgres < full_backup.sql

# MongoDB backup
mongodump --db <database_name> --out /backup/
mongodump --out /backup/

# MongoDB restore
mongorestore --db <database_name> /backup/<database_name>/
mongorestore /backup/
```

## 📊 Monitoring và Analysis

### Database monitoring
```bash
# MySQL monitoring
mysql -u root -p -e "SHOW STATUS;"
mysql -u root -p -e "SHOW VARIABLES;"
mysql -u root -p -e "SHOW ENGINE INNODB STATUS\G"

# PostgreSQL monitoring
psql -U postgres -c "SELECT * FROM pg_stat_database;"
psql -U postgres -c "SELECT * FROM pg_stat_user_tables;"
psql -U postgres -c "SELECT * FROM pg_stat_activity;"

# MongoDB monitoring
mongo --eval "db.runCommand('serverStatus')"
mongo --eval "db.runCommand('dbStats')"
mongo --eval "db.runCommand('collStats', '<collection_name>')"
```

### Performance analysis
```bash
# MySQL - slow query log
mysql -u root -p -e "SET GLOBAL slow_query_log = 'ON';"
mysql -u root -p -e "SET GLOBAL long_query_time = 2;"
tail -f /var/log/mysql/slow.log

# PostgreSQL - log slow queries
sudo nano /etc/postgresql/*/main/postgresql.conf
# log_min_duration_statement = 1000
# log_statement = 'all'
sudo systemctl restart postgresql
```

### Log analysis
```bash
# Xem database logs
sudo tail -f /var/log/mysql/error.log
sudo tail -f /var/log/postgresql/postgresql-*.log
sudo tail -f /var/log/mongodb/mongod.log

# Tìm errors trong logs
grep -i "error" /var/log/mysql/error.log
grep -i "error" /var/log/postgresql/postgresql-*.log
grep -i "error" /var/log/mongodb/mongod.log
```

## 🔧 Advanced Solutions

### Database configuration optimization
```bash
# MySQL optimization
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf

[mysqld]
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
innodb_flush_log_at_trx_commit = 2
query_cache_size = 64M
max_connections = 200
slow_query_log = 1
long_query_time = 2

# PostgreSQL optimization
sudo nano /etc/postgresql/*/main/postgresql.conf

shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
```

### Database clustering và high availability
```bash
# MySQL Master-Slave setup
# Master
mysql -u root -p -e "CREATE USER 'repl'@'%' IDENTIFIED BY 'password';"
mysql -u root -p -e "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';"
mysql -u root -p -e "FLUSH PRIVILEGES;"
mysql -u root -p -e "SHOW MASTER STATUS;"

# Slave
mysql -u root -p -e "CHANGE MASTER TO MASTER_HOST='<master_host>', MASTER_USER='repl', MASTER_PASSWORD='password', MASTER_LOG_FILE='<log_file>', MASTER_LOG_POS=<position>;"
mysql -u root -p -e "START SLAVE;"
mysql -u root -p -e "SHOW SLAVE STATUS\G"
```

## 📝 Checklist khôi phục

- [ ] Kiểm tra database service status
- [ ] Kiểm tra database logs
- [ ] Kiểm tra database connectivity
- [ ] Kiểm tra database performance
- [ ] Kiểm tra database locks
- [ ] Restart database service
- [ ] Optimize database configuration
- [ ] Test database functionality
- [ ] Monitor database performance
- [ ] Document incident và solution

## 🎯 Best Practices

1. **Thiết lập database monitoring** và alerts
2. **Implement proper backup strategies** và test restore
3. **Optimize database configuration** cho workload
4. **Monitor database performance** thường xuyên
5. **Implement proper indexing** và query optimization
6. **Use connection pooling** để manage connections
7. **Implement proper security** và access controls
8. **Test disaster recovery procedures** định kỳ

---

*Tình huống này cần xử lý nhanh để restore database functionality. Luôn backup dữ liệu quan trọng và test recovery procedures.*
