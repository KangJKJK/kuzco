#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # 색상 초기화

# 초기 선택 메뉴
echo -e "${YELLOW}옵션을 선택하세요:${NC}"
echo -e "${GREEN}1: kuzco 노드 설치(CLI)${NC}"
echo -e "${GREEN}2: kuzco 노드 업데이트 및 재실행(CLI)${NC}"
echo -e "${GREEN}3: kuzco 노드 삭제 및 재설치(CLI)${NC}"
echo -e "${GREEN}4: kuzco 노드 설치(Docker)${NC}"
echo -e "${GREEN}5: kuzco 노드 재설치(Docker)${NC}"
echo -e "${RED}노드 구동 후 대시보드 연동까지 최소 5분~10분정도 소요됩니다. 충분히 기다리세요!${NC}"

read -p "선택 (1, 2, 3, 4, 5): " option

if [ "$option" == "1" ]; then
    echo "kuzco 노드 새로 설치를 선택했습니다."
    
    echo -e "${YELLOW}NVIDIA 드라이버 설치 옵션을 선택하세요:${NC}"
    echo -e "1: 일반 그래픽카드 (RTX, GTX 시리즈) 드라이버 설치"
    echo -e "2: 서버용 GPU (T4, L4, A100 등) 드라이버 설치"
    echo -e "3: 기존 드라이버 및 CUDA 완전 제거"
    echo -e "4: 드라이버 설치 건너뛰기"
    
    while true; do
        read -p "선택 (1, 2, 3): " driver_option
        
        case $driver_option in
            1)
                sudo apt update
                sudo apt install -y nvidia-utils-550
                sudo apt install -y nvidia-driver-550
                sudo apt-get install -y cuda-drivers-550 
                sudo apt-get install -y cuda-12-3
                ;;
            2)
                distribution=$(. /etc/os-release;echo $ID$VERSION_ID | sed -e 's/\.//g')
                wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
                sudo dpkg -i cuda-keyring_1.1-1_all.deb
                sudo apt-get update
                sudo apt install -y nvidia-utils-550-server
                sudo apt install -y nvidia-driver-550-server
                sudo apt-get install -y cuda-12-3
                ;;
            3)
                echo "기존 드라이버 및 CUDA를 제거합니다..."
                sudo apt-get purge -y nvidia*
                sudo apt-get purge -y cuda*
                sudo apt-get purge -y libnvidia*
                sudo apt autoremove -y
                sudo rm -rf /usr/local/cuda*
                echo "드라이버 및 CUDA가 완전히 제거되었습니다."
                ;;
            4)
                echo "드라이버 설치를 건너뜁니다."
                break
                ;;
            *)
                echo "잘못된 선택입니다. 다시 선택해주세요."
                continue
                ;;
        esac
        
        if [ "$driver_option" != "4" ]; then
            echo -e "\n${YELLOW}NVIDIA 드라이버 설치 옵션을 선택하세요:${NC}"
            echo -e "1: 일반 그래픽카드 (RTX, GTX 시리즈) 드라이버 설치"
            echo -e "2: 서버용 GPU (T4, L4, A100 등) 드라이버 설치"
            echo -e "3: 기존 드라이버 및 CUDA 완전 제거"
            echo -e "4: 드라이버 설치 건너뛰기"
        fi
    done
    
        # CUDA 툴킷 설치 여부 확인
        if command -v nvcc &> /dev/null; then
            echo -e "${GREEN}CUDA 툴킷이 이미 설치되어 있습니다.${NC}"
            nvcc --version
            read -p "CUDA 툴킷을 다시 설치하시겠습니까? 최초설치시 업데이트를 위해 다시설치하세요. (y/n): " reinstall_cuda
            if [ "$reinstall_cuda" == "y" ]; then
                sudo apt-get -y install cuda-toolkit-12-3
                echo 'export PATH=/usr/local/cuda-12.3/bin:$PATH' >> ~/.bashrc
                echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.3/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
                export PATH=/usr/local/cuda/bin:$PATH
                export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
                source ~/.bashrc
                sudo ln -s /usr/local/cuda-12.3 /usr/local/cuda
            fi
        else
            echo -e "${YELLOW}CUDA 툴킷을 설치합니다...${NC}"
            sudo apt-get install -y nvidia-cuda-toolkit
        fi

        export PATH=/usr/local/cuda/bin:$PATH
        export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
        source ~/.bashrc

        echo "wsl --set-default-version 2"
        echo "wsl --shutdown"
        echo "wsl --update"
        read -p "윈도우라면 파워셸을 관리자권한으로 열어서 위 명령어들을 입력하세요"
    
        # 사용자 안내
        echo -e "${YELLOW}https://kuzco.xyz/ 로 이동하시고 회원가입을 진행해주세요.${NC}"
        echo -e "${YELLOW}Workers 탭에 이동하신 후 Create worker를 클릭해 주세요.${NC}"
        echo -e "${YELLOW}CLI를 선택하신 후 워커네임을 지정해주세요.${NC}"
        read -p "위 단계를 필수적으로 진행하셔야 합니다. 진행하셨다면 엔터를 입력하세요."
        
        # 작업공간생성 및 이동
        mkdir -p "$HOME/kuzco"
        cd "$HOME/kuzco"
        echo -e "${GREEN}작업 디렉토리 이동${NC}"
    
        # 스크립트를 파일로 저장
        curl -fsSL https://kuzco.xyz/install.sh | sh
        
        # 실행 권한 부여
        chmod +x install.sh
        
        # 저장된 스크립트 실행
        kuzco init
        
elif [ "$option" == "2" ]; then
    echo "업데이트 및 재실행을 선택하셨습니다."

        cd "$HOME/kuzco"
        echo -e "${GREEN}작업 디렉토리 이동${NC}"

        # 노드 중지 및 업그레이드
        sudo kuzco worker stop
        kuzco upgrade

        # kuzco worker 실행
        echo -e "${GREEN}Kuzco 워커를 시작합니다...${NC}"
        sudo kuzco worker restart

elif [ "$option" == "3" ]; then
    echo "삭제 및 재설치를 선택하셨습니다."

        # 노드 중지 및 업그레이드
        sudo kuzco worker stop
        sudo kuzco worker clean

        export PATH=/usr/local/cuda/bin:$PATH
        export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
        source ~/.bashrc
        
        # 작업공간생성 및 이동
        sudo rm -rf kuzco
        mkdir -p "$HOME/kuzco"
        cd "$HOME/kuzco"
        echo -e "${GREEN}작업 디렉토리 이동${NC}"
    
        # 스크립트를 파일로 저장
        curl -fsSL https://kuzco.xyz/install.sh | sh
        
        # 실행 권한 부여
        chmod +x install.sh
        
        # 저장된 스크립트 실행
        kuzco init

    elif [ "$option" == "4" ]; then
    echo -e "${GREEN}Kuzco노드 중복설치를 시작합니다. CLI설치를 우선 하시고 이 옵션을 선택하세요.${NC}"
    read -p "정말로 계속하시겠습니까? (y/n): " confirm
    
    # Docker 설치 확인
    echo -e "${BLUE}Docker 설치/업데이트를 확인합니다...${NC}"
    
    # 기존 Docker 설치 확인 및 업데이트
    if dpkg -l | grep -q docker-ce; then
        echo -e "${GREEN}기존 Docker CE가 설치되어 있습니다. 업데이트를 진행합니다...${NC}"
        sudo apt update
        sudo apt upgrade -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
    else
        # Docker가 설치되어 있지 않은 경우, 새로 설치 진행
        if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
            # 필요한 패키지 설치
            sudo apt update
            sudo apt install -y ca-certificates curl gnupg lsb-release
            
            # Docker 공식 GPG key 추가
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            
            # Docker 리포지토리 설정
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        fi
        
        # 패키지 업데이트 및 Docker 설치
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
    fi
    
    # Docker 버전 확인
    echo -e "${GREEN}현재 Docker 버전:${NC}"
    docker --version
    
    # Docker Compose 설치
    echo -e "${BLUE}Docker Compose 최신 버전을 설치합니다...${NC}"
    
    # GitHub API에서 최신 버전 확인
    LATEST_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
    echo -e "${GREEN}최신 버전: ${LATEST_VERSION}${NC}"
    
    # Docker Compose 설치
    mkdir -p $HOME/.docker/cli-plugins
    curl -SL "https://github.com/docker/compose/releases/download/${LATEST_VERSION}/docker-compose-linux-x86_64" -o $HOME/.docker/cli-plugins/docker-compose
    chmod +x $HOME/.docker/cli-plugins/docker-compose
    
    # 버전 확인
    echo -e "${GREEN}설치된 Docker Compose 버전:${NC}"
    docker compose version
    
    # Docker 서비스 시작 및 자동 시작 설정
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # 현재 사용자를 docker 그룹에 추가
    if ! groups $USER | grep &>/dev/null '\bdocker\b'; then
        echo -e "${BLUE}사용자를 docker 그룹에 추가합니다...${NC}"
        sudo usermod -aG docker $USER
        newgrp docker
    fi
    
    # NVIDIA Container Toolkit 설치 여부 확인
    if nvidia-ctk --version &> /dev/null && docker info | grep -i "nvidia" &> /dev/null; then
        echo -e "${GREEN}NVIDIA Container Toolkit이 이미 설치되어 있습니다.${NC}"
        echo -e "${GREEN}설치 단계를 건너뜁니다...${NC}"
    else
        echo -e "${BLUE}NVIDIA Container Toolkit을 설치합니다...${NC}"
        
        # 현재 실행 중인 컨테이너 목록 저장
        echo -e "${YELLOW}현재 실행 중인 컨테이너 정보를 저장합니다...${NC}"
        running_containers=$(docker ps --format '{{.Names}}:{{.ID}}')
        
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

        curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

        sudo apt-get update
        sudo apt-get install -y nvidia-container-toolkit nvidia-container-runtime
        sudo nvidia-ctk runtime configure --runtime=docker
    fi
    
    # Docker 런타임 설정 확인
    echo -e "${GREEN}Docker 런타임 설정을 확인합니다...${NC}"
    docker info | grep -i runtime

    # Kuzco Docker 설치
    docker pull kuzcoxyz/amd64-ollama-nvidia-worker:latest

    #Docker 재시작
    echo -e "${YELLOW}Docker 서비스를 재시작합니다.${NC}"
    sudo systemctl restart docker

    # 이용자에게 정보 받기
    echo -e "${YELLOW}https://kuzco.xyz/ 로에서 Workers 탭으로 이동하세요.${NC}"
    echo -e "${YELLOW}Create woker를 누르신후 docker를 선택해주세요.${NC}"
    echo -e "${YELLOW}instance탭으로 가셔서 Launch worker를 클릭하세요.${NC}"
    echo -e "${YELLOW}workerID와 instanceID가 필요하니 기억해두세요.${NC}"
    read -p "위 단계를 필수적으로 진행하셔야 합니다. 진행하셨다면 엔터를 입력하세요."

    # 워커 정보 입력 받기
    read -p "워커 ID를 입력하세요: " worker_name
    read -p "워커 Instance ID를 입력하세요: " worker_code
    
    # 환경변수로 설정
    export KUZCO_WORKER_NAME="$worker_name"
    export KUZCO_WORKER_CODE="$worker_code"
    
    # kuzco worker 실행
    echo -e "${GREEN}Kuzco 워커를 시작합니다...${NC}"         
    sudo docker run -d --restart=always --runtime=nvidia --gpus all -e CACHE_DIRECTORY=/root/models -v ~/.kuzco/models:/root/models kuzcoxyz/amd64-ollama-nvidia-worker --worker "$KUZCO_WORKER_NAME" --code "$KUZCO_WORKER_CODE"

elif [ "$option" == "5" ]; then
    echo -e "${YELLOW}실행 중인 모든 Kuzco Docker 컨테이너를 확인합니다...${NC}"
    
    # kuzco-worker 관련 컨테이너 목록 조회
    containers=$(docker ps -a --filter "name=kuzco-worker" --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}")
    
    if [ -z "$containers" ]; then
        echo -e "${RED}실행 중인 Kuzco 컨테이너가 없습니다.${NC}"
    else
        echo -e "${GREEN}발견된 Kuzco 컨테이너 목록:${NC}"
        echo "$containers"
        
        read -p "모든 Kuzco 컨테이너를 삭제하시겠습니까? (y/n): " confirm
        if [ "$confirm" == "y" ]; then
            echo -e "${YELLOW}컨테이너를 중지하고 삭제합니다...${NC}"
            docker ps -a --filter "name=kuzco-worker" -q | xargs -r docker stop
            docker ps -a --filter "name=kuzco-worker" -q | xargs -r docker rm
            echo -e "${GREEN}모든 Kuzco 컨테이너가 성공적으로 삭제되었습니다.${NC}"
        else
            echo "작업이 취소되었습니다."
        fi
    fi

    # 현재 사용자를 docker 그룹에 추가
    if ! groups $USER | grep &>/dev/null '\bdocker\b'; then
        echo -e "${BLUE}사용자를 docker 그룹에 추가합니다...${NC}"
        sudo usermod -aG docker $USER
        # 서브셸에서 newgrp 실행
        bash -c "newgrp docker"
    fi

    # Kuzco Docker 설치
    docker pull kuzcoxyz/amd64-ollama-nvidia-worker:latest

    #Docker 재시작
    echo -e "${YELLOW}Docker 서비스를 재시작합니다.${NC}"
    sudo systemctl restart docker

    # 이용자에게 정보 받기
    echo -e "${YELLOW}https://kuzco.xyz/ 로에서 Workers 탭으로 이동하세요.${NC}"
    echo -e "${YELLOW}Create woker를 누르신후 docker를 선택해주세요.${NC}"
    echo -e "${YELLOW}instance탭으로 가셔서 Launch worker를 클릭하세요.${NC}"
    echo -e "${YELLOW}workerID와 instanceID가 필요하니 기억해두세요.${NC}"
    read -p "위 단계를 필수적으로 진행하셔야 합니다. 진행하셨다면 엔터를 입력하세요."

    # 워커 정보 입력 받기
    read -p "워커 ID를 입력하세요: " worker_name
    read -p "워커 Instance ID를 입력하세요: " worker_code
    
    # 환경변수로 설정
    export KUZCO_WORKER_NAME="$worker_name"
    export KUZCO_WORKER_CODE="$worker_code"
    
    # kuzco worker 실행
    echo -e "${GREEN}Kuzco 워커를 시작합니다...${NC}"
    sudo mkdir -p /home/$USER/kuzco-cache && chmod 777 /home/$USER/kuzco-cache
    sudo docker run -d --restart=always --runtime=nvidia --gpus all -e CACHE_DIRECTORY=/root/models -v ~/.kuzco/models:/root/models kuzcoxyz/amd64-ollama-nvidia-worker --worker "$KUZCO_WORKER_NAME" --code "$KUZCO_WORKER_CODE"
else
    echo "잘못된 선택입니다."
    exit 1
fi


