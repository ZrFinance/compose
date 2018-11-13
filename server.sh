check(){
        if [ $(echo $?) -gt 0 ]
        then
		echo "$1 error!"
		exit
        fi
}

system_yum_command(){
        if [ $(uname -a | grep centos | wc -l) -gt 0 ]
        then
                echo yum -y install
        elif [ $(uname -a | grep Debian | wc -l) -gt 0 ]
        then
                echo apt-get install -y
        fi
}
yum=system_yum_command


install_mysql(){
	$($yum) wget && wget -i -c http://dev.mysql.com/get/mysql57-community-release-el7-10.noarch.rpm && $($yum) mysql57-community-release-el7-10.noarch.rpm && $($yum) mysql-community-server && systemctl start  mysqld.service
	rm -rf mysql57-community-release-el7-10.noarch.rpm
}

install_docker(){
	$($yum) wget && wget -qO- get.docker.com/ | sh && service docker start	
	check install_docker
}

install_compose(){
	pip -v > /dev/null 2>&1
	if [ $(echo $?) -gt 0 ] 
	then
		$($yum) epel-release && $($yum) python-pip && pip install --upgrade pip
	fi
	if [ $(pip list | grep requests | wc -l) -gt 0 ]
	then
		pip install docker-compose --ignore-installed requests 
	else
		pip install docker-compose 
	fi
	check install_compose
}

check_docker(){
	docker -v > /dev/null 2>&1
	if [ $(echo $?) -gt 0 ] 
	then
		install_docker
	fi
}

check_compose(){
	docker-compose -v  > /dev/null 2>&1
	if [ $(echo $?) -gt 0 ] 
	then
		install_compose
	fi
}

check_all(){
	check_compose
	check_docker
}

main(){
	check_all

	curdir=$(pwd)
	for item in $(ls $curdir)
	do
		if [ ! -d $curdir/$item ]
		then	
			continue
		fi	
		echo "$item start..."
		cd $curdir/$item
		docker-compose pull && docker-compose up -d
		if [ $item == 'zrfinance_sso' ]
		then
			a=$(docker ps | grep zrfinance/server:latest | awk '{print $1}')
			docker exec -it $a python manage.py crontab add
		fi
		check $item
		echo "$item end"
	done
	cd $curdir
}

echo "server start..."
main
echo "server success!"
