#!/bin/bash
# Submit FDEM simulations
# by Qi Zhao @ U of T, 2018
# Version V07 Feb 1, 2018

#TODO
# add user option (and an email list)
# Example: -u qz

if [ ! -t 0 ]; then
  echo "This script must be run from a terminal"
  exit 1
fi

usage="$(basename "$0") -option [input]
    -h show help text
    -a [*.r2m or *.r3m] add a simulation to the end of the queue
    -r [int] remove a simulation from the queue, input is the simulation ID in the list
    -l [filename] load simulation(s) from text file
    -c check current queue, with ID shown"

while getopts 'ha:r:l:c' OPT; do
 case "$OPT" in
   h) echo "$usage"
      exit
      ;;
   a) if [[ ! -f $2 ]]; then
   		echo "Input error. Run file $2 does not exit."
   		exit 0
   	  fi
	  if [[ ${2:(-4)} != .r2m ]]; then
	  	if [[ ${2:(-4)} != .r3m ]]; then
   			echo "Input error. Run file (in the format of /path/filename.r2m[or .r3m]) is required."
   			exit 0
		fi
   	  fi
	  
   	 if [ -f ~/.simu_list ]; then 
         echo "$2" >> ~/.simu_list
         echo "Add $2 to the list"
         echo -n "$(grep -v '^$' ~/.simu_list)" > ~/.simu_list_tmp
	 echo "$(cat ~/.simu_list_tmp)" > ~/.simu_list
	 echo -e "Current list:\n     ID Name"
      	 echo "$(cat -n ~/.simu_list)"
      else 
         echo "A new list is created"
         echo "Add $2 to the list"
         touch ~/.simu_list
         echo $2 >> ~/.simu_list
         #echo -n "$(grep -v '^$' ~/.simu_list)" > ~/.simu_list
	 echo -e "Current list:\n     ID Name"
      	 echo "$(cat -n ~/.simu_list)"
      fi
      ;;
   r) simu_rm=$(head -n $2 ~/.simu_list | tail -1)
      echo "remove $simu_rm from the list"
      nn=$(cat ~/.simu_list | wc -l)
      #echo $nn
      if [ $nn -eq 1 ]; then
	        rm ~/.simu_list
          echo "No pending simulation job"
        exit 0
      fi
      nn=$((nn+1))
      nhr=$(($2-1))
      ntr=$((nn-$2))
      echo -e "$(sed "$2d" ~/.simu_list)" > ~/.simu_list_tmp
      echo "$(cat ~/.simu_list_tmp)" > ./.simu_list
      #echo -e "$(head -n $nhr ~/.simu_list)\n$(tail -n $ntr ~/.simu_list)" > ~/.simu_list_tmp
      #echo -e "$(grep -v '^$' ~/.simu_list_tmp)" > ~/.simu_list

      echo -e "Current list:\n     ID Name"
      echo "$(cat -n ~/.simu_list)"
      ;;
   l) if [ -f ~/.simu_list ];
      then
		 echo "Add simulations in $2 to the list"
		 echo -e "$(cat ~/.simu_list)\n$(cat $2)" > ~/.simu_list
			 echo -n "$(grep -v '^$' ~/.simu_list)" > ~/.simu_list_tmp
		 echo "$(cat ~/.simu_list_tmp)" > ~/.simu_list
		 echo -e "Current list:\n     ID Name"
      	 echo "$(cat -n ~/.simu_list)"
      else
         echo "A new list is created"
		 echo "Add simulations in $2 to the list"
			 touch ~/.simu_list
		 echo "$(cat $2)" > ~/.simu_list
			 echo -n "$(grep -v '^$' ~/.simu_list)" > ~/.simu_list_tmp
		 echo "$(cat ~/.simu_list_tmp)" > ~/.simu_list
		 echo -e "Current list:\n     ID Name"
      	 echo "$(cat -n ~/.simu_list)"
      fi
      ;;
   c) if [ -f ~/.simu_list ];
      then
      	echo -e "Current list:\n     ID Name"
      	echo "$(cat -n ~/.simu_list)"
      else
      	echo "No pending simulation job"
      fi
      ;;
   \?) printf "Illegal option\n"
      echo "$usage"
      exit 1
      ;;
   :) printf "Input options:"
      echo "$usage"
      exit 1
      ;;
 esac
done

shift $(($OPTIND - 1))

