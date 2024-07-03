#! /bin/sh

# Setup arg variables
psql_host=$1
psql_port=$2
db_name=$3
psql_user=$4
psql_password=$5

# Check # of args is 5
if [ $# -ne 5 ]; then
	echo "Illegal number of parameters"
	exit 1
fi

# Save current machine hostname and cpu info to variables
hostname=$(hostname -f)
lscpu_out=`lscpu`

# Retrieve Hardware info variables
cpu_number=$(echo "$lscpu_out"  | egrep "^CPU\(s\):" | awk '{print $2}' | xargs)
cpu_architecture=$(echo "$lscpu_out"  | egrep "^Architecture:" | awk '{print $2}' | xargs)
cpu_model=$(echo "$lscpu_out"  | egrep "^Model name:" | awk '$1="";$2="";{print $0}' | xargs)
cpu_mhz=$(echo "$cpu_model" | awk '{print $5}' | sed 's/[^0-9.]//g' | awk '{printf "%.3f\n", $0 * 1000}' | xargs)
l2_cache=$(echo "$lscpu_out"  | egrep "^L2 cache:" | awk '{print $3}' | xargs)
total_mem=$(vmstat --unit M | tail -1 | awk '{print $4}')

# Current time in UTC format
timestamp=$(date +"%Y-%m-%d %H:%M:%S")

# Setup env var for psql cmd
export PGPASSWORD=$psql_password

# Subquery to find matching id in host_info table 
find_host_id_stmt="(SELECT id FROM host_info WHERE hostname='$hostname')";

# PSQL Command: Check if hostname is in table and return id
host_id=$(psql -At -h "$psql_host" -p "$psql_port" -d "$db_name" -U "$psql_user" -c "$find_host_id_stmt")

# Check host exists already in db
if [ -z "$host_id" ]; then 
    echo "Host not found, inserting new host into host_info..."

    # Generate a new ID key
    while true; do
	
	# Generate random id from 1 to 1000000
        new_host_id=$((1 + RANDOM % 1000000))

	# PSQL Command: Check if random id is in table and return id
        host_id=$(psql -At -h "$psql_host" -p "$psql_port" -d "$db_name" -U "$psql_user" -c "SELECT id FROM host_info WHERE id='$new_host_id'")

        if [ -z "$found_id" ]; then
		break
        fi
    done

    # Build the INSERT statement for host_info
    insert_stmt="INSERT INTO host_info(id, hostname, cpu_number, cpu_architecture, cpu_model, cpu_mhz, l2_cache, timestamp, total_mem) VALUES ('$new_host_id', '$hostname', '$cpu_number', '$cpu_architecture', '$cpu_model', '$cpu_mhz', '$l2_cache', '$timestamp', '$total_mem');"

    # PSQL Command: Inserts server info data into host_info table
    psql -h "$psql_host" -p "$psql_port" -d "$db_name" -U "$psql_user" -c "$insert_stmt"

else
    echo "Host found, exiting..."
fi
exit $?
