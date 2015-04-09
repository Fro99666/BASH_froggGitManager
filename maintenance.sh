#!/bin/bash
#            _ __ _
#        ((-)).--.((-))
#        /     ''     \
#       (   \______/   )
#        \    (  )    /
#        / /~~~~~~~~\ \
#   /~~\/ /          \ \/~~\
#  (   ( (            ) )   )
#   \ \ \ \          / / / /
#   _\ \/  \.______./  \/ /_
#   ___/ /\__________/\ \___
#  *****************************
SCN="WebMaintenance"   			# script name
SCD="Create/Save GIT Web"		# script description
SCT="Debian"					# script OS Test
SCC="bash ${0##*/}"				# script call
SCV="1.004"						# script version
SCO="2015/02/09"				# script date creation
SCU="2015/04/09"				# script last modification
SCA="Marsiglietti Remy (Frogg)"	# script author
SCM="admin@frogg.fr"			# script author Mail
SCS="cv.frogg.fr"				# script author Website
SCF="Arnaud Marsiglietti"		# script made for
SCP=$PWD						# script path
SCY="2015"						# script copyright year

#find TODO in this file:
# - TODO : check version pattern [v][0-9]+[\.][0-9]{4}
# - TODO : set %04d as var
#############
# Script    : Commit & Create a new version auto incremented on Local & Origin server
# Important : - Git version format has to be vX.XXX in project root folder in file version.txt
#             - For save process, Script file has to be started in root folder
#############

#===SERVER INFOS
#Git server address
gIP="xxxxx.frogg.fr"
#Git server port
gPort="xxxxx"
#Git ssh server User
gUser="xxxxx"
#Git server directory
gDir="/opt/git/"
#Git project directory
pDir="xxxxx.git"
#Git userName
gMail="arnaud.marsiglietti@ima.umn.edu"
#remote directory (relative to this script path)
rDir="public_html/"
#Project version file (in project root folder)
vFile="version.txt"

#===COLORS
INFOun="\e[4m"							#underline
INFObo="\e[1m"							#bold
INFb="\e[34m"							#blue
INFr="\e[31m"							#red
INFOb="\e[107m${INFb}"					#blue (+white bg)
INFObb="\e[107m${INFObo}${INFb}"		#bold blue (+white bg)
INFOr="\e[107m${INFr}"					#red (+white bg)
INFOrb="\e[107m${INFObo}${INFr}"		#bold red (+white bg)

NORM="\e[0m"
GOOD="\e[1m\e[97m\e[42m"
OLD="\e[1m\e[97m\e[45m"
CHECK="\e[1m\e[97m\e[43m"
WARN="\e[1m\e[97m\e[48;5;208m"
ERR="\e[1m\e[97m\e[41m"

#==COLOR STYLE TYPE

#echo with "good" result color
good()
{
echo -e "${GOOD}$1${NORM}"
}

#echo with "warn" result color
warn()
{
echo -e "${WARN}$1${NORM}"
}

#echo with "check" result color
check()
{
echo -e "${CHECK}$1${NORM}"
}

#echo with "old" result color
old()
{
echo -e "${OLD}$1${NORM}"
}

#echo with "err" result color
err()
{
echo -e "${ERR}$1${NORM}"
}

#echo with "info" result color
info()
{
echo -e "${INFObb}$1${NORM}"
}

# echo an title format
title()
{
case $2 in
	"0")echo -e "\n${INFObb}${INFOun}$1${NORM}";;
	"1")
		x=0 	#reset lvl 3
		y=0		#reset lvl 2
		((z++))	#increase lvl 1
		echo -e "\n${INFObb}${INFOun}${z}] $1${NORM}"
	;;
	"2")
		x=0 	#reset lvl 3
		((y++))	#increase lvl 2
		echo -e "\n${INFOb}${INFOun}${z}.${y}] $1${NORM}"
	;;
	"3")
		((x++)) #increase lvl 3
		echo -e "\n${INFOb}${INFOun}${z}.${y}.${x}] $1${NORM}"
	;;
	*)echo -e "\n$1";;
esac
}

#===FUNCTIONS
#func used to ask user to answer yes or no, return 1 or 0
makeachoice()
	{
	userChoice=0
	while true; do
		check " [ Q ] Do you wish to $1 ?"
		read -p "" yn
		case $yn in
			y|Y|yes|YES|Yes|yeah|YEAH|Yeah|ya|YA|Ya|ja|JA|Ja|O|o|oui|OUI|Oui|oue|OUE|Oue|ouep|OUEP|Ouep)userChoice=1;break;;
			n|N|no|NO|No|non|NON|Non|na|Na|NA)userChoice=0;break;;
			* )err " [ ERROR ] '$yn' isn't a correct value, Please choose yes or no";;
		esac
	done
	return $userChoice
	}

#newaction {question} {title}
newaction()
{
#ask user to continue
makeachoice "$2"
if [ $? = 0 ];then
	warn "Script aborted by user"
	exit 1
else
	title "$1" "1"
fi
}

#Check if git project has been initialized (hide result message)
gitExist()
{
exist=0
if git status &> /dev/null;then
	#Git has been found
	exist=1
fi
return $exist
}

getGitIp()
{
#Get server IP Adress from Git configuration
srvOriginGit=$(git config --get remote.origin.url)
IFS='@' read -a arraySrv <<< "$srvOriginGit"
IFS=':' read -a arraySrv2 <<< "${arraySrv[1]}"
echo ${arraySrv2[0]}
}

getNewGitVersion()
{
#get last version
oldVersion=$( git tag | tail -1 )
#split it
arrVersion=( ${oldVersion//./ } )
#get before . version part
preVersion=${arrVersion[0]//v/}
#get after . version part
subVersion=$(expr ${arrVersion[1]} + 1)
#check subversion
if [ $subVersion -eq 9999 ];then
	subVersion=0
	preVersion=$(expr ${preVersion} + 1)
fi
#format subversion
#TODO : set %04d as var
subVersion=$(printf "%04d\n" $subVersion)
#return
echo "v${preVersion}.${subVersion}"
}

#===================[ 0 ] SCRIPT MENU=================
#--Process Check param
#VAR create new git project
create=0
for params in $*
do
	IFS=: val=($params)
	case ${val[0]} in
		"-ip")		gIP=${val[1]};;
		"-port")	gPort=${val[1]};;
		"-user")	gUser=${val[1]};;
		"-git")		gDir=${val[1]};;
		"-project")	pDir=${val[1]};;
		"-mail")	gMail=${val[1]};;
		"-remote")	rDir=${val[1]};;
		"-create")	create=1;;
	esac
done

echo -e "\n*******************************"
echo -e "# ${SCN}"
echo -e "# ${SCD}"
echo -e "# Tested on   : ${SCT}"
echo -e "# v${SCV} ${SCU}, Powered By ${SCA} - ${SCM} - ${SCS} - Copyright ${SCY}"
echo -e "# For         : ${SCF}"
echo -e "# script call : ${SCC}\n"
echo -e "Optional Parameters [Default values]"
echo -e " -create: Create the Git project [NoValuesRequired]"
echo -e " -ip: Origin Server Git Address [$gIP]"
echo -e " -port: Origin Server Git Port [$gPort]"
echo -e " -user: Origin Server Git User login [$gUser]"
echo -e " -git: Origin Server Git Path [$gDir]"
echo -e " -project: Origin Server Git Project path [$pDir]"
echo -e " -remote: Remote Server Web folder [$rDir]"
echo -e " -mail: User Project Mail [$gMail]"
echo -e " -version: Project version file[$vFile]"
echo -e "*******************************\n"

# Ask if sure to start the script
if makeachoice "Do you wish to continue"; then
	warn " [ END ] End of the script, aborted by user"
	exit
fi

#===================[ 1 ] CREATE PROJECT [ORIGIN]===================
# Create project From Scratch or Existing file require create=1
if [ $create = 1 ]; then
	#check if server git folder exist
	if [ ! -d $gDir$pDir ]; then
		# create git dir (-p for fun)
		mkdir -p $gDir$pDir
		good "Creating Git Project from scratch in folder '$gDir$pDir'"
	else
		good "Found Project Files in folder '$gDir$pDir'"
	fi
	#Change current folder to git project folder
	cd $gDir$pDir
	#Check if git project has been initialized (hide result message)
	if gitExist;then
		#Create Git project
		git init
		# Set user name and email to local repository
		git config user.name "${gMail%%@*}"
		git config user.email "$gMail"
		# Set git to use the credential memory cache
		git config credential.helper cache
		# Set the cache to time out after 1 hour (setting is in seconds)
		git config credential.helper 'cache --timeout=3600'
		# Allow modification on master branch from remote GIT
		git config receive.denyCurrentBranch ignore
		# Allow remote folder to be owned by remote user
		git config core.sharedRepository 1
		#set version
		if [ -e $vFile ];then
			#TODO : check version pattern [v][0-9]+[\.][0-9]{4}
			version=$(cat $vFile)
		else
			#TODO : set %04d as var
			version="v1."$(printf "%04d\n" $subVersion)
			echo $version > $vFile
		fi
		# Init first commit
		git add .
		git commit -m "Project '$pDir' Init"
		git tag ${version} -m '${version}'
		# success message
		good "Git project '$pDir' has been successfully configured in '$gDir$pDir'"
	else
		# already exist message
		warn "Git project '$pDir' already exist in '$gDir$pDir', nothing need to be done"
	fi
	#stop script
	exit
fi

#===================[ 2 ] GET OR SAVE PROJECT [REMOTE]===================
#server IP Adress
srvOriginGit=$gIP
if gitExist;then
	#go to remote dir
	mkdir -p ${rDir}
	cd ${rDir}
	good " [ A ] Project folder is now './${rDir}' !"
	#Get server IP Adress from default configuration
	if gitExist;then
		#Get server IP Adress from default configuration
		srvOriginGit=$gIP
	else
		#Get server IP Adress from Git configuration
		srvOriginGit=$(getGitIp)
	fi
else
	#Get server IP Adress from Git configuration
	srvOriginGit=$(getGitIp)
fi

#check if empty (case local git server pulled)
[ -z $srvOriginGit ]&&srvOriginGit=$gIP

#Test if Git server port is UP
check "...Checking if GIT Origin server '${srvOriginGit}' is available, please wait..."
if nc -w5 -z ${srvOriginGit} ${gPort} &> /dev/null;then
	good " [ A ] Server Git Origin [${srvOriginGit}:${gPort}] port is opened !"
else
	err " [ A ] Can't access to Server Git Origin Port [${srvOriginGit}:${gPort}], End of the script"
	exit
fi

#===================GET PROJECT [REMOTE]===================
#If first time case
if gitExist;then
	if git clone ssh://${gUser}@${gIP}:${gPort}/${gDir}${pDir} ./;then
		#Send success message
		good "[ END ] Congratz ! Project has been successfully downloaded to ${rDir} ^_^"
	else
		#Send success message
		err "[ END ] Error while getting Git data from $gIP"
	fi
	#exist script
	exit
fi

#===================SAVE PROJECT [REMOTE]===================
#If project change and need to be save on origin server

#test if version file exist
if [ ! -e $vFile ];then
	err " [ END ] End of the script, cannot find $vFile in ${rDir}"
	exit
fi

# Ask if sure to start the script
if makeachoice "Save a new version of $pDir Project"; then
	warn " [ END ] End of the script, aborted by user"
	exit
fi

#
##################LOCAL GIT
#
#Correct git infos
git config user.name "${gMail%%@*}"
git config user.email "$gMail"
git config core.sharedRepository 1
##Add new file not referenced
info "...adding files please wait..."
git add -A
##Add news file to local git
info "...committing files please wait..."
git commit -a
##Update local project with server change
info "...downloading & merging server changed files please wait..."
git pull
##update current git version number
version=$(getNewGitVersion)
echo $version > $vFile
info "...updating version file to ${version}..."
git commit -a -m 'update version file to ${version}'
##Create the new version in git
if git tag ${version} -m '${version}';then
	info "...committing tag ${version} please wait..."
else
	err " [ END ] An error occurred while committing tag ${version}"
	exit
fi
#
##################ORIGIN GIT
##Send file to centralized GIT server
if git push -f; then
	##send tags
	git pull --tags
	if git push --tags; then
		info "...tags pushed..."
	else
		err " [ END ] An error occurred while pushing tag ${version}"
		exit
	fi
else
	err " [ END ] An error occurred while pushing files to git server"
	exit
fi
#Send success message
good "[ END ] Congratz ! save has been successfully done ^_^"
