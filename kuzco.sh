#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # 색상 초기화

# 초기 선택 메뉴
echo -e "${YELLOW}옵션을 선택하세요:${NC}"
echo -e "${GREEN}1: kuzco 노드 새로 설치${NC}"
echo -e "${GREEN}2: kuzco 노드 업데이트 및 재실행${NC}"
echo -e "${GREEN}3: 방화벽 포트 자동 개방 (자산이 있는 개인지갑이 설치된 PC는 절대 실행하지 마세요)${NC}"
echo -e "${RED}노드 구동 후 대시보드상 인증까지 최소 5분~10분정도 소요됩니다. 충분히 기다리세요!${NC}"

read -p "선택 (1, 2): " option

if [ "$option" == "1" ]; then
    echo "kuzco 노드 새로 설치를 선택했습니다."
    
    echo -e "${YELLOW}NVIDIA 드라이버 설치 옵션을 선택하세요:${NC}"
    echo -e "1: 일반 그래픽카드 (RTX, GTX 시리즈) 드라이버 설치"
    echo -e "2: 서버용 GPU (T4, L4, A100 등) 드라이버 설치"
    echo -e "3: 기존 드라이버 및 CUDA 완전 제거"
    echo -e "4: 드라이버 설치 건너뛰기"
    
    while true; do
        read -p "선택 (1, 2, 3, 4): " driver_option
        
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
        curl -sSL https://kuzco.xyz/setup-kuzco.sh > setup-kuzco.sh
        
        # 실행 권한 부여
        chmod +x setup-kuzco.sh
        
        # 저장된 스크립트 실행
        ./setup-kuzco.sh    

elif [ "$option" == "2" ]; then
    echo "업데이트 및 재실행을 선택하셨습니다."

        cd "$HOME/kuzco"
        echo -e "${GREEN}작업 디렉토리 이동${NC}"
    
        # 사용자 안내
        echo -e "${YELLOW}https://kuzco.xyz/ 로에서 Workers 탭으로 이동하세요.${NC}"
        echo -e "${YELLOW}기존에 실행중이였던 Worker의 이름을 기억해주세요. 기억이나지않는다면 새로 생성하세요.${NC}"
        echo -e "${YELLOW}CLI를 선택하신 후 워커네임을 지정해주세요.${NC}"
        echo -e "${RED}워커 네임과 코드를 반드시 기억해주세요.${NC}"
        read -p "위 단계를 필수적으로 진행하셔야 합니다. 진행하셨다면 엔터를 입력하세요."

        # 노드 중지 및 업그레이드
        sudo kuzco worker stop
        kuzco upgrade

        # 워커 정보 입력 받기
        read -p "워커 이름을 입력하세요: " worker_name
        read -p "워커 Instance ID를 입력하세요: " worker_code
        
        # 환경변수로 설정
        export KUZCO_WORKER_NAME="$worker_name"
        export KUZCO_WORKER_CODE="$worker_code"
        
        # kuzco worker 실행
        echo -e "${GREEN}Kuzco 워커를 시작합니다...${NC}"
        sudo kuzco worker start --background --worker "$KUZCO_WORKER_NAME" --code "$KUZCO_WORKER_CODE"    
        
elif [ "$option" == "3" ]; then
    echo -e "${RED}경고: 이 옵션은 서버에서만 실행해야 합니다!${NC}"
    echo -e "${RED}개인 PC에서 실행 시 보안에 위험할 수 있습니다!${NC}"
    echo -e "${RED}이용 중인 모든 포트에 대한 방화벽이 허용됩니다. 가상 서버가 아니라면 보안에 취약하므로 주의해야 합니다.${NC}"
    read -p "정말로 계속하시겠습니까? (y/n): " confirm
    
    if [ "$confirm" == "y" ]; then
        # 현재 사용 중인 포트 확인 및 허용
        echo -e "${GREEN}현재 사용 중인 포트를 확인합니다...${NC}"

        # TCP 포트 확인 및 허용
        echo -e "${YELLOW}TCP 포트 확인 및 허용 중...${NC}"
        sudo ss -tlpn | grep LISTEN | awk '{print $4}' | cut -d':' -f2 | while read port; do
            echo -e "TCP 포트 ${GREEN}$port${NC} 허용"
            sudo ufw allow $port/tcp
        done

        # UDP 포트 확인 및 허용
        echo -e "${YELLOW}UDP 포트 확인 및 허용 중...${NC}"
        sudo ss -ulpn | grep LISTEN | awk '{print $4}' | cut -d':' -f2 | while read port; do
            echo -e "UDP 포트 ${GREEN}$port${NC} 허용"
            sudo ufw allow $port/udp
        done
        
        echo -e "${GREEN}포트 개방이 완료되었습니다.${NC}"
    else
        echo "작업이 취소되었습니다."
    fi
else
    echo "잘못된 선택입니다."
    exit 1
fi
