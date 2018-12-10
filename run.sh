# Automates running the experiments.

# Username to connect to the VMs with.
user=$1

# Note the Experiment needs to be changed if vm ips or ports change.
# This is because currently the experiment has hardcoded ips.
function declare_common {
  # IP address of all VMs.
  vm1="13.68.179.205"
  vm2="40.87.91.240"
  vm3="40.76.37.110"
  vm4="40.76.40.194"
  vm5="168.62.58.101"
  vm6="168.62.61.62"
  vms=($vm1 $vm2 $vm3 $vm4 $vm5 $vm6)

  # IP address for each process.
  cmi_vms=($vm1 $vm2 $vm3 $vm4)
  zookeeper_vms=($vm1 $vm5 $vm6)
  db_vm=$vm5
  coordinator_writer_vm=$vm5
  coordinator_reader_vm=$vm6
  ycsb_vm=$vm6
  experiment_vm=$vm5

  # Common ports
  cmi_ports=("11220" "11221" "11222" "11223" "11224")
  zookeeper_quorum_port="12220"
  zookeeper_leader_port="12221"
  zookeeper_client_port="12223"
  coordinator_reader_port="50031"
  coordinator_writer_port="50032"

  # YCSB attrs
  workloads=("workloada" "workloadb" "workloadc")
  threads=(1 10 100)
  exp_timeouts=(60 30 15 8)
  access_pattern="zipfian"
}

# Install dependencies
function install {
  sudo apt-get update
  sudo apt-get --yes install maven
  sudo apt-get install -y mysql-server
  sudo apt-get install -y sysstat

  # Install from repo
  local PROJECT_PATH="$PWD/RejigMemcached/"
  rm -rf $PROJECT_PATH
  mkdir -p $PROJECT_PATH
  git clone "https://github.com/Likhit/RejigMemcached.git"
  cd $PROJECT_PATH
  git submodule update --init --recursive
  local MEMCACHED_PATH="${PROJECT_PATH}distribution/memcached"
  local EXP_PATH="${PROJECT_PATH}distribution/Experiments/bin/Experiments"
  local COORD_PATH="${PROJECT_PATH}distribution/RejigCoordinator/bin/RejigCoordinator"
  sudo chmod u+x $MEMCACHED_PATH
  sudo chmod u+x $EXP_PATH
  sudo chmod u+x $COORD_PATH

  # Build YCSB
  local YCSB_PATH="${PROJECT_PATH}YCSB/"
  cd $YCSB_PATH
  sudo mvn -pl com.yahoo.ycsb:jdbc-binding -am clean package -DskipTests
  cd $PROJECT_PATH

  # Install zookeeper
  local ZOO_PATH="${PROJECT_PATH}distribution/zookeeper/"
  mkdir -p $ZOO_PATH
  wget -O zookeeper.tar.gz "https://www-eu.apache.org/dist/zookeeper/zookeeper-3.5.4-beta/zookeeper-3.5.4-beta.tar.gz"
  sudo tar -zxvf zookeeper.tar.gz -C $ZOO_PATH --strip-components=1
}

function start_db {
  sudo service mysql start
  sudo mysql -u root --execute="DROP USER 'user'@'%';"
  sudo mysql -u root --execute="CREATE USER 'user'@'%' IDENTIFIED BY '123456';"
  sudo mysql -u root --execute="GRANT ALL PRIVILEGES on *.* to 'user'@'%' IDENTIFIED BY '123456';"
  sudo mysql -u root --execute="FLUSH PRIVILEGES;"
  sudo mysql -u user --password="123456" --execute="CREATE SCHEMA IF NOT EXISTS ycsb;"
  sudo mysql -u root --password="123456" --execute="CREATE TABLE ycsb.usertable (YCSB_KEY VARCHAR(255) PRIMARY KEY, FIELD0 TEXT, FIELD1 TEXT,FIELD2 TEXT, FIELD3 TEXT, FIELD4 TEXT, FIELD5 TEXT, FIELD6 TEXT, FIELD7 TEXT, FIELD8 TEXT, FIELD9 TEXT);"
}

function stop_db {
  sudo service mysql stop
}

function start_zookeeper {
  local ZOO_PATH="$PWD/RejigMemcached/distribution/zookeeper/"
  local data_dir="/var/lib/zookeeper"
  sudo rm -rf $data_dir
  sudo mkdir -p $data_dir
  local conf_path="${ZOO_PATH}conf/zoo.cfg"
  sudo rm -f $conf_path
  echo "tickTime=2000" | sudo tee $conf_path
  echo "dataDir=$data_dir" | sudo tee -a $conf_path
  echo "clientPort=$zookeeper_client_port" | sudo tee -a $conf_path
  echo "initLimit=10" | sudo tee -a $conf_path
  echo "syncLimit=2" | sudo tee -a $conf_path
  for i in "${!zookeeper_vms[@]}"
  do
    echo "server.$((i+1))=${zookeeper_vms[$i]}:${zookeeper_quorum_port}:${zookeeper_leader_port}" | sudo tee -a $conf_path
  done
  cat $conf_path
  sudo "${ZOO_PATH}bin/zkServer.sh" start
}

function stop_zookeeper {
  local ZOO_PATH="$PWD/RejigMemcached/distribution/zookeeper/"
  sudo "${ZOO_PATH}bin/zkServer.sh" stop
}

function start_memcached {
  local user=$1
  local mem=$2
  local port=$3
  local MEMCACHED_PATH="$PWD/RejigMemcached/distribution/memcached"
  sudo $MEMCACHED_PATH -d -A -u $user -m $mem -p $port
}

function stop_memcached {
  local host=$1
  local port=$2
  local workload=$3
  local threads=$4
  local timeout=$5
  local LOG_PATH="$PWD/Logs/memcached_${workload}_${threads}_${timeout}_${port}.txt"
  { echo "stats"; sleep 2; echo "shutdown"; sleep 2; } | telnet $host $port | tee $LOG_PATH
  echo "Done!!"
}

function start_coordinator_reader {
  local zoo_addr=$1
  local zoo_port=$2
  local COORD_PATH="${PWD}/RejigMemcached/distribution/RejigCoordinator/bin/RejigCoordinator"
  sudo $COORD_PATH zookeeper-reader $zoo_addr $zoo_port
}

function start_coordinator_writer {
  local zoo_addr=$1
  local zoo_port=$2
  local COORD_PATH="${PWD}/RejigMemcached/distribution/RejigCoordinator/bin/RejigCoordinator"
  sudo $COORD_PATH zookeeper-writer $zoo_addr $zoo_port
}

function setup_logs {
  # Setup log dir
  local LOG_PATH="$PWD/Logs/"
  rm -rf $LOG_PATH
  mkdir -p $LOG_PATH
}

function load_db {
  local db_host=$1
  local YCSB_PATH="${PWD}/RejigMemcached/YCSB/"
  local LOG_PATH="$PWD/Logs/load.txt"
  cd $YCSB_PATH
  sudo "./bin/ycsb" load jdbc \
    -P "./workloads/workloada" -p recordcount=100000 \
    -p operationcount=0 -p maxexecutiontime=0 \
    -p db.driver=com.mysql.jdbc.Driver \
    -p db.url="jdbc:mysql://$db_host:3306/ycsb?useSSL=false" \
    -p db.user=user -p db.passwd=123456 -p status.interval=1 > $LOG_PATH
}

function run_workload {
  local workload=$1
  local threads=$2
  local db_host=$3
  local coordinator_host=$4
  local coordinator_port=$5
  local timeout=$6
  local access_pattern=$7
  local LOG_PATH="$PWD/Logs/"
  local YCSB_PATH="${PWD}/RejigMemcached/YCSB/"
  cd $YCSB_PATH

  # Run warmup
  sudo "./bin/ycsb" run jdbc-memcached \
    -P "./workloads/$workload" -p recordcount=0 \
    -p operationcount=0 -p maxexecutiontime=60 \
    -p db.driver=com.mysql.jdbc.Driver \
    -p db.url="jdbc:mysql://$db_host:3306/ycsb?useSSL=false" \
    -p db.user=user -p db.passwd=123456 -p status.interval=1 \
    -p requestdistribution=$access_pattern \
    -p coordinator.host="$coordinator_host" \
    -p coordinator.port="$coordinator_port" > "$LOG_PATH/warmup_${workload}_${threads}_${timeout}.txt"

  # Run workload
  sudo "./bin/ycsb" run jdbc-memcached \
    -P "./workloads/$workload" -p recordcount=100000 \
    -p operationcount=0 -p maxexecutiontime=300 \
    -p db.driver=com.mysql.jdbc.Driver \
    -p db.url="jdbc:mysql://$db_host:3306/ycsb?useSSL=false" \
    -p db.user=user -p db.passwd=123456 -p status.interval=1 \
    -p requestdistribution=$access_pattern \
    -p coordinator.host="$coordinator_host" \
    -p coordinator.port="$coordinator_port" \
    -s -threads "$threads" > "$LOG_PATH/run_${workload}_${threads}_${timeout}.txt"
}

function run_experiment {
  local coord_host=$1
  local coord_port=$2
  local clearence=$3
  local timeout=$4
  local recovery=$5
  local death=$6
  local workload=$7
  local threads=$8
  local LOG_PATH="$PWD/Logs/"
  local EXP_PATH="${PWD}/RejigMemcached/distribution/Experiments/bin/Experiments"
  sudo $EXP_PATH changeEveryNSecs $coord_host $coord_port $clearence $timeout $recovery $death > "$LOG_PATH/exp_${workload}_${threads}_${timeout}.txt"
}

function start_trace {
  local workload=$1
  local threads=$2
  local timeout=$3
  local SAR_PATH="$PWD/Logs/sar_${workload}_${threads}_${timeout}.txt"
  local IOSTAT_PATH="$PWD/Logs/iostat_${workload}_${threads}_${timeout}.txt"
  sar -u 2 43200 > $SAR_PATH
  iostat -d 2 43200 > $IOSTAT_PATH
}

function stop_trace {
  sudo pkill -f sar
  sudo pkill -f iostat
}

function main {
  declare_common

  for vm in "${vms[@]}"
  do
    ssh "$user@$vm" "$(typeset -f install); install"
    ssh "$user@$vm" "$(typeset -f setup_logs); setup_logs"
  done

  ssh "$user@$db_vm" "$(typeset -f start_db); start_db"
  echo "You may need to change the bind-address on the mysql installation to connect remotely."

  ssh "$user@$ycsb_vm" "$(typeset -f load_db); load_db $db_vm"

  for workload in "${workloads[@]}"
  do
    for thread in "${threads[@]}"
    do
      for timeout in "${exp_timeouts[@]}"
      do
        echo "${workload}_${thread}_${timeout}"

        for cmi in "${cmi_vms[@]}"
        do
          for port in "${cmi_ports[@]}"
          do
            ssh "$user@$cmi" "$(typeset -f start_memcached); start_memcached $user 2048 $port"
          done
        done

        for vm in "${zookeeper_vms[@]}"
        do
          ssh "$user@$vm" "$(typeset -f start_zookeeper); $(typeset -f declare_common); declare_common; start_zookeeper"
        done

        ssh -f "$user@$coordinator_reader_vm" "sh -c '$(typeset -f start_coordinator_reader); start_coordinator_reader ${zookeeper_vms[0]}:$zookeeper_client_port $coordinator_reader_port'"
        ssh -f "$user@$coordinator_writer_vm" "sh -c '$(typeset -f start_coordinator_writer); start_coordinator_writer ${zookeeper_vms[0]}:$zookeeper_client_port $coordinator_writer_port'"

        sleep 2

        for vm in "${vms[@]}"
        do
          ssh -f "$user@$vm" "sh -c '$(typeset -f start_trace); start_trace $workload $thread $timeout'"
        done

        ssh -f "$user@$experiment_vm" "sh -c '$(typeset -f run_experiment); run_experiment $coordinator_writer_vm $coordinator_writer_port 180 $timeout 5 600 $workload $thread'"
        ssh "$user@$ycsb_vm" "$(typeset -f run_workload); run_workload $workload $thread $db_vm $coordinator_reader_vm $coordinator_reader_port $timeout $access_pattern"
        ssh "$user@$experiment_vm" "sudo pkill -f Experiments"

        for vm in "${vms[@]}"
        do
          ssh "$user@$vm" "$(typeset -f stop_trace); stop_trace"
        done

        ssh "$user@$coordinator_reader_vm" "sudo pkill -f RejigCoordinator"
        ssh "$user@$coordinator_writer_vm" "sudo pkill -f RejigCoordinator"

        for vm in "${zookeeper_vms[@]}"
        do
          ssh "$user@$vm" "$(typeset -f stop_zookeeper); stop_zookeeper"
        done

        for cmi in "${cmi_vms[@]}"
        do
          for port in "${cmi_ports[@]}"
          do
            ssh "$user@$cmi" "$(typeset -f stop_memcached); stop_memcached $cmi $port $workload $thread $timeout"
          done
        done

        echo "New iter!!!!!"
        sleep 5
      done
    done
  done

  ssh "$user@$db_vm" "$(typeset -f stop_db); stop_db"
}

main