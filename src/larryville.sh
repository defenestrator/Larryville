#!/bin/bash

# pretty colors
red=$'\e[31m'
grn=$'\e[32m'
red_bold=$'\e[1;31m'
yel=$'\e[33m'
blu=$'\e[34m'
mag=$'\e[35m'
cyn=$'\e[36m'
cyn_bold=$'\e[1;36m'
wh_bold=$'\e[1;97m'
end=$'\e[0m'

printf "${wh_bold}Welcome to Larryville, a real nice place to raise your kids up!\n${end}${grn}Larryville helps you set up a new Laravel project on GitHub.\n${yel}If you do not care for Laravel and GitHub, scram!${end}\n"
read -p "${cyn}In which (empty or new) directory shall we do a Larryville?${end} " DIRECTORY

if [[ ${#DIRECTORY} == 0 ]]
then
    printf "${red_bold}You must specify a directory.\n${end}"
    read -p "${cyn}In which (empty or new) directory do you want to Larryville?${end} " DIRECTORY
    if [[ ${#DIRECTORY} == 0 ]]
    then
        printf "${red_bold}You must specify a directory.\nExiting.\nFigure it out.\n${end}"
        exit 1
    fi
fi

read -p "${cyn}What's the name of your new thing?${end} " APP
APP=${APP:-'Generic Larryville Test App'}

read -p "${cyn}What purpose does this thing serve?${end} " DESCRIPTION
DESCRIPTION=${DESCRIPTION:-'This thing is for personal edification or just a lark, probably, nobody knows!'}

read -p "${cyn}If you have a domain, please enter it, otheriwse, hit [ENTER]${end} " DOMAIN
DOMAIN=${DOMAIN:-'https://shmogramming.net'}

printf "${yel}${APP} is a nice name for a thing. ${DOMAIN} is a good domain, you might be a genius.\n" 

read -p "${cyn}Why in the world would you want to do such a thing?${end} " DETAILS
DETAILS=${DETAILS:-'This is a toy project. There is no bigger tragedy than taking oneself to seriously.'}

if [[ -f .larryville.config ]] 
then
    . .larryville.config
    TOKEN=$GH_TOKEN
    NAME=$GH_NAME
else
    read -p "${cyn}What is your Github Name?${end} " NAME
    echo ${NAME}
    read -p "${cyn}Is that the correct name? y/n: ${end} " -n 1 -r CORRECT
    echo
        if [[ ! $CORRECT =~ ^[Yy]$ ]]
    then
        read -p "${cyn}What is your Github Name?${end} " NAME
        echo ${NAME}
        read -p "Is that the correct name? y/n:" -n 1 -r CORRECT
        echo 
        if [[ ! $CORRECT =~ ^[Yy]$ ]]
        then                
            echo "${red_bold}Exiting; GitHub configuration is incorrect ${end} "
            printf "${yel}You must be able to type your github username to ride this ride.\nExiting.\n${red_bold}Figure it out.\n${end}"
            exit 0
        fi
    fi
    read -p "${cyn}Github Access Token?${end} " TOKEN
    if [[ ${#TOKEN} == 40 ]]
    then
        STATUS=$(http -hdo ./response_body https://api.github.com/user/repos\?access_token\=${TOKEN} 2>&1 | grep HTTP/  | cut -d ' ' -f 2)
        if [[ ${STATUS} != 200 ]]
        then
            printf "${red_bold}Your github access token or username appears to be invalid.\n Received HTTP error response ${STATUS}\n Name:${NAME}\nToken:${TOKEN}\n${end}" 
            exit 0
        else
            echo "${cyn}Those credentials appear to be valid, saving config.${end}"            
            printf "GH_TOKEN=${TOKEN}\nGH_NAME=${NAME}\n" > .larryville.config
        fi
        if [[ -f response_body ]]
        then
            rm response_body    
        fi
    else
        printf "${yel}Your github access token appears to be invalid.\n${end}"
        read -p "${red_bold}Do you want to continue without GitHub? y/n: ${end} " -n 1 -r REPLY
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]
        then
            echo "${cyn}Exiting; GitHub configuration is incorrect ${end}"
            exit 0
        fi
    fi
fi

if [[ -d ${DIRECTORY} ]] 
then
    cd ./${DIRECTORY}
    laravel new --prompt-jetstream ./ 
else
    laravel new --prompt-jetstream ${DIRECTORY}
    cd ./${DIRECTORY}
fi

printf "# ${APP}\n\n## ${DESCRIPTION}\n\n ### ${DETAILS}\n" > README.md
printf "# ${APP} License\n\n## Source Visible\n\n ### You can see the source\n\n #### No other license is granted\n\nThis work is not suitable for anything, it has no implied nor explicit value, nor any warranties of any kind. It is not suitable to a particular purpose, nor does it make any claims.\n\nThis agreement may be updated by the copyright holder at any time.\n\n&copy; $NAME 2021, rights reserved.\n" > LICENSE.md
php artisan key:generate 
git init
git add .
git commit -m "initial"

if [[ ${#TOKEN} == 40 ]]
then
    STATUS=$(http -hdo ./response_body https://api.github.com/user/repos\?access_token\=${TOKEN} 2>&1 | grep HTTP/  | cut -d ' ' -f 2)
    if [[ ${STATUS} != 200 ]]
    then
        printf "${red_bold}Your github name and or access token appear to be invalid.\n Received HTTP error response ${STATUS}\n Name:${NAME}\nToken:${TOKEN}\n${end}"
        if [[ -f response_body ]]
        then 
            rm response_body    
        fi
        exit 1
    fi
    http post https://api.github.com/user/repos\?access_token\=${TOKEN} name="${DIRECTORY}" description="${DESCRIPTION}" homepage="${DOMAIN}" private:=false
    git remote add origin git@github.com:${NAME}/${DIRECTORY}.git
    git push -u origin main
fi
if [[ -f response_body ]]
then 
    rm response_body    
fi
echo "${yel}Welcome to${end} ${red_bold}Larryville${end}${yel}, let's get to work on ${APP}!${end}"
exit 0
