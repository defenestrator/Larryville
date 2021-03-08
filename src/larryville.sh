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
wh_bold=$'\e[1;1m'
end=$'\e[0m'

printf "${wh_bold}Welcome to Larryville, a real nice place to raise your kids up!\n${end}Larryville helps you set up a new Laravel project on GitHub!\nIf you do not care for Laravel and GitHub, this is not the town for you, buddy, scram!\n"
read -p "${cyn}In which (empty or new) directory shall we do a Larryville?${end} " DIRECTORY

if [ ${#DIRECTORY} == 0 ]
then
    printf "${red_bold}You must specify a directory.\n${end}"
    read -p "${cyn}In which (empty or new) directory do you want to Larryville?${end} " DIRECTORY
    if [ ${#DIRECTORY} == 0 ]
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

printf "${cyn}${APP} is a nice name for a thing. ${DOMAIN} is a good domain, you might be a genius.\n\n" 

read -p "Why in the world would you want to do such a thing?${end} " DETAILS
DETAILS=${DETAILS:-'This is a toy project. There is no bigger tragedy than taking oneself to seriously.'}

if [ -f larryville.config ] 
then
    . larryville.config
    TOKEN=$GH_TOKEN
    NAME=$GH_NAME
    if  [[ ${#NAME} == 0 ]]
    then
        read -p "${cyn}What is your Github Name?${end} " NAME
        NAME=${NAME}
        rm larryville.config
        printf "GH_TOKEN=${TOKEN}\nGH_NAME=${NAME}\n" > larryville.config  
    fi
    if  [[ ${#TOKEN} != 40 ]]
    then
        read -p "${cyn}Github Access Token?${end} " TOKEN
        TOKEN=${TOKEN}
        rm larryville.config
        printf "GH_TOKEN=${TOKEN}\nGH_NAME=${GH_NAME}\n" > larryville.config  
    fi
else
    read -p "${cyn}What is your Github Name?${end} " NAME
    read -p "${cyn}Github Access Token?${end} " TOKEN
    TOKEN=${TOKEN}    
    if [[ TOKEN && ${#TOKEN} == 40 ]]; then
        rm larryville.config
        printf "GH_TOKEN=${TOKEN}\nGH_NAME=${NAME}\n" > larryville.config        
    fi
fi

if [[ ! ${#TOKEN} == 40 ]]
then
    printf "${red_bold}Your github access token appears to be invalid.\n${end}"
    read -p "${red_bold}Do you want to continue without GitHub? y/n: ${end} " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        "${cyn}Exiting until GitHub personal access token is correct ${end} "
        exit 0
    fi
fi

if [ -d ${DIRECTORY} ] 
then
    cd ./${DIRECTORY}
    laravel new ./
else
    laravel new ${DIRECTORY}
    cd ${DIRECTORY}
fi

printf "# ${APP}\n\n## ${DESCRIPTION}\n\n ### ${DETAILS}\n" > README.md

php artisan key:generate 
git init
git add .
git commit -m "initial"

if [[ TOKEN && ${#TOKEN} == 40 ]] 
then
    STATUS=$(http -hdo ./body https://api.github.com/user/repos\?access_token\=${TOKEN} 2>&1 | grep HTTP/  | cut -d ' ' -f 2)
    if [[ ${STATUS} != 200 ]]
    then
        printf "${red_bold}Your github name and or access token appear to be invalid.\n Received HTTP error response ${STATUS}\n${end}"
        rm -f ./body
        exit 1
    fi
    http post https://api.github.com/user/repos\?access_token\=${TOKEN} name="${PWD##*/}" description="${DESCRIPTION}" homepage="${DOMAIN}" private:=false
    git remote add origin git@github.com:${NAME}/${PWD##*/}.git
    git push -u origin main
    rm -f ./body
else
    printf "${red_bold}Your github name and or access token appear to be invalid.\n${end}"
fi

echo "${yel}Welcome to${end} ${red_bold}Larryville${end}${yel}, let's get to work on ${APP}!${end}"
exit 0
