#! /bin/sh

# Setup argument variables
psql_host=$1
psql_port=$2
db_name=$3
psql_user=$4
psql_password=$5

# Check # of arguments
if [ $# -ne 5 ]; then
	echo "Illegal number of parameters"
	exit 1
fi

# Save machine states in MB and current machine hostname to variables
vmUsage=$(vmstat --unit M | tail -1)
hostname=$(hostname -f)

# Retrieve Hardware specification variables
memory_free=$(echo "$vmUsage" | awk -v col="4" '{print $col}')
cpu_idle=$(echo "$vmUsage" | awk '{print $15}')
cpu_kernel=$(echo "$vmUsage" | awk '{print $14}')
disk_io=$(vmstat --unit M -d | tail -1 | awk -v col="10" '{print $col}')
disk_available=$(df -BM / | tail -1 | awk '{print $4}' | tr -d 'M')

# Current time in UTC format
timestamp=$(date +"%Y-%m-%d %H:%M:%S")

# Subquery to find matching id in host_info table 
find_host_id_stmt="(SELECT id FROM host_info WHERE hostname='$hostname')";

# PSQL Command: Check if hostname is in table and return id
host_id=$(psql -At -h "$psql_host" -p "$psql_port" -d "$db_name" -U "$psql_user" -c "$find_host_id_stmt")

# Check host exists already in db
if [ -z "$host_id" ]; then 
    echo "Host not found, exiting..."
else
    echo "Host found, updating data..."

    # Build the INSERT statement for host_usage
    insert_stmt="INSERT INTO host_usage(timestamp, host_id, memory_free, cpu_idle, cpu_kernel, disk_io, disk_available) VALUES ('$timestamp', '$host_id', '$memory_free', '$cpu_idle', '$cpu_kernel', '$disk_io', '$disk_available');"

    # PSQL Command: Inserts server usage data into host_usage table
    psql -h "$psql_host" -p "$psql_port" -d "$db_name" -U "$psql_user" -c "$insert_stmt"
fi
exit $?

