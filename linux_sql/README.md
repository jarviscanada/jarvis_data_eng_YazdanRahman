# Introduction
The Linux Cluster Monitoring Agent (LCMA) aims to record hardware specification data on each node in a Linux Cluster. The solution records real-time hardware info and usage (CPU, Memory) on multiple Rocky 9 servers and stores them within an RDBMS. This data is vital to plan for capacity and optimization by a Linux Cluster Administration (LCA) team.

The LCMA utilizes a PostgreSQL database hosted within docker to store data. Bash scripts act as agents to collect data on all nodes and gather that data into the database. The scripts are run within the cron periodically for real-time updates. The data can then be queried using SQL to inform future decision-making. Lastly, Git (GitFlow) was used for version control.

# Quick Start 
- Start a psql instance using psql_docker.sh 
```
./scripts/psql_docker.sh start
```
- Create tables using ddl.sql
```
psql -h localhost -U postgres -d host_agent -f sql/ddl.sql
```
- Insert hardware specs data into the DB using host_info.sh
```
bash scripts/host_info.sh <psql_host> <psql_port> <db_name> <db_username> <db_password>
```
- Insert hardware usage data into the DB using host_usage.sh
```
bash scripts/host_usage.sh <psql_host> <psql_port> <db_name> <db_username> <db_password>
```
- Crontab setup
```
* * * * * bash /home/rocky/dev/jarvis_data_eng_yazdanrahman
/linux_sql/scripts/host_usage.sh <psql_host> <psql_port> <db_name> <db_username> <db_password> > /tmp/host_usage.log  
```

# Implemenation
The first phase of the project involves setting up a PostgreSQL database instance using docker. This is to provide an isolated and robust environment to handle data storage. The bash script was developed to handle the creation, starting, and stopping fo the docker container hosting the script. In addition, this script simplifies the process of managing the database instance, especially for users who not be so familiar with docker.

The second phase involves instantiating the RDBMS PostgreSQL database. This is done through a script that creates 2 tables on the static and dynamic data on the hardware specifications. This includes CPU model, cores, cache, total memory, memory usage, CPU usage, and disk usage. A DDL script was created to automate the process of creating the tables within the database to ensure efficiency and reliability.

In the next phase, a monitoring agent is developed for specification collection. This is done with 2 scripts, each one to obtain the static and dynamic data collection on the hardware specifications respectively (see above for more information). These scripts take advantage of the psql tool to insert the data into the respective tables using an INSERT SQL statement. The dynamic script is also designed to run multiple times to provide real-time information on the usage statistics. This ensures convenience by having each server node execute the script to obtain all necessary information.

The final phase of the project involves deploying and automating the app. This is through crontabs on each server node to automate the monitoring agent. This is to ensure continuous data collection when necessary.

In addition, the project's codebase is managed using Git and hosted with GitHub. This is to enable collaboration, version control, and easy deployment across server nodes. The GitFlow methodology is also used for a feature branch workflow to ensure a structured development process and integration of new features or bug fixes.

## Architecture
![Architecture](/assets/Architecture.png)

## Scripts
### psql_docker.sh
The `psql_docker.sh` script handles setting up a PostgreSQL database instance using docker. The script has 3 functionalities, starting, stopping, and creating the container. Keep in mind the script assumes the container name will be `jrvs-psql`.

See usage below:
```
./scripts/psql_docker.sh create <db_username> <db_password>
./scripts/psql_docker.sh start
./scripts/psql_docker.sh stop
```

### host_info.sh
The `host_info.sh` script is known as a monitoring agent, it handles collecting the `static` hardware specification on the host. The script takes in positional arguments to specify the PostgreSQL network address, database name, and user credentials. The `lscpu` and `hostname` commands are used to collect the static data and the `psql` command tool is used to connect to and manipulate the database.

See usage below:
```
bash scripts/host_info.sh <psql_host> <psql_port> <db_name> <db_username> <db_password>
```
Example
```
bash scripts/host_info.sh localhost 5432 host_agent postgres password
```

### host_usage.sh
The `host_usage.sh` script is known as a monitoring agent, it handles collecting the `dynamic` hardware specification on the host. The script takes in positional arguments to specify the PostgreSQL network address, database name, and user credentials. The `vmstat` and `hostname` commands are used to collect the static data and the `psql` command tool is used to connect to and manipulate the database.

See usage below:
```
bash scripts/host_usage.sh <psql_host> <psql_port> <db_name> <db_username> <db_password>
```
Example
```
bash scripts/host_usage.sh localhost 5432 host_agent postgres password
```

### crontab
The crontab is responsible for periodically running the monitoring agent (`host_usage.sh`). To edit the crontab you can type in `crontab -e` in the bash terminal. You can also type `crontab -l` to see any running jobs on the crontab. Use the `#` symbol to comment out any unwanted jobs.

See usage below:
```
* * * * * bash <script_path> <psql_host> <psql_port> <db_name> <db_username> <db_password> > <logfile_path>
```
Example
```
* * * * * bash /home/centos/dev/jrvs/bootcamp/linux_sql/host_agent/scripts/host_usage.sh localhost 5432 host_agent postgres password > /tmp/host_usage.log  
```

## Database Modeling
- `host_info`
| Column Name        | Data Type | Description                  |
|--------------------|-----------|------------------------------|
| `id`               | SERIAL    | Unique identifier for a host |
| `hostname`         | VARCHAR   | Name of host                 |
| `cpu_number`       | INT2      | Number of CPU cores          |
| `cpu_architecture` | VARCHAR   | CPU architecture (eg. x86)   |
| `cpu_model`        | VARCHAR   | CPU model name               |
| `cpu_mhz`          | FLOAT8    | CPU clock speed in MHz       |
| `l2_cache`         | INT4      | L2 cache size in kB          |
| `timestamp`        | TIMESTAMP | Date & Time of collection    |
| `total_mem`        | INT4      | Total Memory in MB           |

- `host_usage`
| Column Name      | Data Type | Description                               |
|------------------|-----------|-------------------------------------------|
| `timestamp`      | TIMESTAMP | Date and Time of collection               |
| `host_id`        | SERIAL    | Foreign key referencing `host_info.id`    |
| `memory_free`    | INT4      | Available memory in MB                    |
| `cpu_idle`       | INT2      | CPU idle utilization in percentage        |
| `cpu_kernel`     | INT2      | CPU kernel mode utilization in percentage |
| `disk_io`        | INT2      | Number of current disk I/O operations     |
| `disk_available` | INT4      | Available disk space in MB                |

# Test
Each of the scripts was manually tested on a single machine but from 3 separate terminals, simulating the architecture in the diagram above. Additionally, the `ddl.sql` script was executed to verify table creation and insertion of sample data for normalized testing. Additionally, SQL queries (`SELECT * FROM host_info;` and `SELECT * FROM host_usage;`) were used to ensure the data was properly updated in the database.

# Deployment
The application was deployed using the following:
- GitHub: For version control, collaboration, and easy deployment 
- Docker: For hosting the PostgreSQL instance for portability and easy setup (in `psql_docker.sh`)
- Crontab: For scheduling the `host_usage.sh` script for standard data collection

# Improvements
- Handle Hardware Updates: Update the monitoring agent scripts to handle hardware changes such as a new CPU.
- PSQL Script Robustness: Make the `psql_docker.sh` script able to create a database with custom names, multiple databases, and container removal.
- Alert System: Integrate warnings for unusual resource usage or changes such as high CPU utilization, new hard drive, etc.
- Containerization: Make the entire LCMA into a single docker container to help with scalability and convenience.

