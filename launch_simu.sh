#!/bin/bash
# Launch FDEM simulations
# by Qi Zhao @ U of T, 2018
# Version V07 Feb 1, 2018

# TODO
# 1. Improve time estimation accuracy
# 2. multi-computer job distribution and fetch job submitted to website
# 3. in case of more than 1 simulation running at the same time?
# 4. allow this code to be launched from any directory
# 5. write a log file

if [ ! -t 0 ]; then
  echo "This script must be run from a terminal"
  exit 1
fi

service_2d=irazu_2d_bin
service_3d=irazu_3d_bin

# version
V=V07

# email for email notification [disabled]
# email=

host=`hostname -f`
n=0
moni_str=_basic_

function ProgressBar {
    # Process data
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*3)/10
    let _left=30-$_done
    # Build progressbar string lengths
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")
    printf "\rProgress: [${_fill// />}${_empty// /-}] ${_progress}%% Time remaining: %-12s" "${3}"
}

esc=0
while [ "$esc" -eq "0" ]
do
  if [ -f ~/.simu_list ]; then
    nn=$(cat ~/.simu_list | wc -l)
    while [ $nn -gt 0 ]
    do
      echo -e "\n\nLaunch code [$V] --> $nn simulation(s) in the list\n"
      bash submit_simu.sh -c
      # If a simulation is running
      if (( $(ps -ef | grep -v grep | grep $service_2d | wc -l) > 0 | $(ps -ef | grep -v grep | grep $service_3d | wc -l) > 0 ))
	      then # wait for running models to finish
			  while (( $(ps -ef | grep -v grep | grep $service_2d | wc -l) > 0  | $(ps -ef | grep -v grep | grep $service_3d | wc -l) > 0 ))
				  do
            printf "\rLaunch code [$V] Waiting for the running simulation to finish.    "
            sleep 0.5s
            printf "\rLaunch code [$V] Waiting for the running simulation to finish..   "
            sleep 0.5s
            printf "\rLaunch code [$V] Waiting for the running simulation to finish...  "
            sleep 0.5s
            printf "\rLaunch code [$V] Waiting for the running simulation to finish.... "
            sleep 0.5s
            printf "\rLaunch code [$V] Waiting for the running simulation to finish....."
            sleep 0.5s
          done
      else # If no simulations running
        cur_simu=$(head -n 1 ~/.simu_list)
        cur_dir=$(dirname $cur_simu)
	      printf "Launching simulation:\n$cur_simu\noutput to directory:\n$cur_dir\n"
        # check 2D or 3D
        if [[ ${cur_simu:(-4)} = .r2m ]]; then
          service=$service_2d
          irazu_2d --in $cur_simu --out $cur_dir &
        else
          service=$service_3d
          irazu_3d --in $cur_simu --out $cur_dir &
        fi
	sleep 0.5s
	if (( $(ps -ef | grep -v grep | grep $service | wc -l) > 0 ))
	  then
	  t_start=$(date +%s)
	  n=0
	  echo -e "\n$cur_simu on $host has been started"
	  echo "Press s to stop the current simulation."
	  echo "Press p to stop the current simulation and stop launching pending jobs."
    
    if [ $nn -eq 1 ]; then
	    rm ~/.simu_list
      nn=0
    else
      tail -n +2 ~/.simu_list > ~/.simu_list_tmp
	    echo "$(cat ~/.simu_list_tmp)" > ~/.simu_list
	    nn=$(cat ~/.simu_list_tmp | wc -l)
    fi
    
	  # subject="$service at $host has been started"
	  # echo "$cur_simu at $host has been started" | mail -s "$subject" $email
	      # check progress and show
	      t_total_line=$(grep 'Number of Time Steps' $cur_simu)
	      f_output_line=$(grep 'Output Frequency' $cur_simu)
	      seis_output_line=$(grep 'Seismic Monitoring' $cur_simu)
	      fem_or_femdem=$(grep 'fem-or-femdem' $cur_simu)
	      
	      t_total=${t_total_line//[^0-9]/}
	      f_output=${f_output_line//[^0-9]/}
	      seis_output=${seis_output_line//[^0-9]/}
	      let n_total=($t_total+$f_output-1)/$f_output+1
		  
	  #   if [ $fem_or_femdem -eq 0 ]; then
	  #    	let n_total=3*$n_total
	  #     else
	  #	  let n_total=($seis_output+4)*$n_total
	  #   fi
	      
	  if [ -t 0 ]; then stty -echo -icanon -icrnl time 0 min 0; fi
	  keypress=''
	  status=$(ps -ef | grep -v grep | grep $service | wc -l)

	  while [[ $status -eq 1 ]] && [[ "$keypress" != "s" ]] && [[ "$keypress" != "p" ]]
	    do
	      nf_basic=$(printf "%s\n" $cur_dir/* | grep -c $cur_simu$moni_str)
		  
	      pcent=$(echo "scale=6 ; $nf_basic * 100 / $n_total" | bc)
	      t_now=$(date +%s)
	      t_elapsed=$[ $t_now - $t_start ]
	      
	      keypress="`cat -v`"
	      MODDATE=$(stat -c %Y $cur_dir)
	      MODDATE=${MODDATE%% *}
	      
			  if [ $nf_basic -gt 1 ] && [ $MODDATE -gt $t_start ]; then
					t_est=$(echo "scale=0 ; $t_elapsed *100/ $pcent" | bc)
					t_rem=$[ $t_est - $t_elapsed ]
				  if [[ $t_rem -gt 120 ]] && [[ $t_rem -le 3600 ]];then
					t_rem_disp="$(echo "scale=0 ; $t_rem / 60" | bc) min $(expr $t_rem % 60) s"
				  elif [[ $t_rem -gt 3600 ]];then
					rem=$(expr $t_rem % 3600)
					t_rem_disp="$(echo "scale=0 ; $t_rem / 3600" | bc) h $(echo "scale=0 ; $rem / 60" | bc) min"
				  elif [[ $t_rem -gt 0 ]] && [[ $t_rem -le 120 ]]; then
					t_rem_disp="$t_rem s"
				  else
					t_rem_disp="--"
				  fi  
					ProgressBar ${nf_basic} ${n_total} "${t_rem_disp}"
			  else
				  sleep 2s
					MODDATE=$(stat -c %Y $cur_dir)
					MODDATE=${MODDATE%% *}
					printf "\rSimulation running. Waiting for outputs..."
			  fi
		sleep 1s
	  	status=$(ps -ef | grep -v grep | grep $service | wc -l)
	  done
	  
	  if [ -t 0 ]; then stty sane; fi
	  if [[ "$keypress" == "s" ]]; then
	    echo " "
	    pkill -f "$service"
	    echo "Simulation stopped by user."
	    # subject="$service on $host has been stopped"
	    # echo "$cur_simu at $host has been stopped by user at $pcent% " | mail -s "$subject" $email
	    sleep 0.5s
	  elif [[ "$keypress" == "p" ]]; then
	    echo " "
	    pkill -f "$service"
	    echo "Simulation stopped by user. Simulation launching stopped."
	    # subject="$service on $host has been stopped"
	    # echo "$cur_simu at $host has been stopped by user at $pcent%. Simulation launching stopped. " | mail -s "$subject" $email
	    exit 0
	  else
	    t_now=$(date +%s)
	    t_elapsed=$[ $t_now - $t_start ]
	    if [[ $t_elapsed -gt 60 ]] && [[ $t_elapsed -le 3600 ]];then
		  t_elapsed_disp="$(echo "scale=0 ; $t_elapsed / 60" | bc) min $(expr $t_elapsed % 60) s"
	    elif [[ $t_elapsed -gt 3600 ]];then
		  t_elapsed_rem=$(expr $t_elapsed % 3600)
		  t_elapsed_disp="$(echo "scale=0 ; $t_elapsed / 3600" | bc) h $(echo "scale=0 ; $t_elapsed_rem / 60" | bc) min"
	    else
		  t_elapsed_disp="$t_elapsed s"
	    fi      
	    printf "\rSimulation done. Time elapsed: %-45s" "${t_elapsed_disp}"
	    echo " "
	    # subject="$service on $host has been finished"
	    # echo "$cur_simu at $host has been finished" | mail -s "$subject" $email
	  fi
	  echo " "
	else
	  ((n ++))
	  if [ "$n" -eq "1" ]; then
	    echo "Error! $cur_simu on $host cannot be started. Please check..."
	    # subject="$service at $host cannot be started"
	    # echo "$cur_simu at $host cannot be started" | mail -s "$subject" $email
	    exit 0
	  fi
	fi
      fi
    done
    rm ~/.simu_list
    rm ~/.simu_list_tmp

  else
      printf "\rLaunch code [$V] Waiting for simulation job.    "
      sleep 0.5s
      printf "\rLaunch code [$V] Waiting for simulation job..   "
      sleep 0.5s
      printf "\rLaunch code [$V] Waiting for simulation job...  "
      sleep 0.5s
	  printf "\rLaunch code [$V] Waiting for simulation job.... "
      sleep 0.5s
	  printf "\rLaunch code [$V] Waiting for simulation job....."
      sleep 0.5s
  fi
done

exit 0