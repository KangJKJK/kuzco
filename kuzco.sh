#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # 색상 초기화

# 초기 선택 메뉴
echo -e "${YELLOW}옵션을 선택하세요:${NC}"
echo -e "${GREEN}1: kuzco 노드 새로 설치${NC}"
echo -e "${GREEN}2: 방화벽 허용${NC}"
read -p "선택 (1, 2): " option

if [ "$option" == "1" ]; then
    echo "Lumoz 노드 새로 설치를 선택했습니다."
    
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
    
        # 사용자 입력 받기
        read -p "GPU 종류를 선택하세요 (1: NVIDIA, 2: AMD): " gpu_choice
        read -p "kuzco 지갑 주소를 입력하세요: " wallet_address
        read -p "채굴자 이름을 입력하세요: " miner_name
    
        # GPU 선택에 따른 다운로드 및 설치
        if [ "$gpu_choice" == "1" ]; then
            echo "NVIDIA GPU 마이너를 다운로드합니다..."
            wget https://github.com/6block/zkwork_moz_prover/releases/download/v1.0.2/moz_prover-v1.0.2_cuda.tar.gz
            tar -zvxf moz_prover-v1.0.2_cuda.tar.gz
        elif [ "$gpu_choice" == "2" ]; then
            echo "AMD GPU 마이너를 다운로드합니다..."
            wget https://github.com/6block/zkwork_moz_prover/releases/download/v1.0.2/moz_prover-v1.0.2_ocl.tar.gz
            tar -zvxf moz_prover-v1.0.2_ocl.tar.gz
        else
            echo "잘못된 선택입니다."
            exit 1
        fi

        # 작업공간생성 및 이동
        mkdir -p "./kuzco"
        cd "./kuzco"
        echo -e "${GREEN}작업 디렉토리 이동${NC}"
    
        # 스크립트 다운로드 및 실행
        sh -c "$(curl -sSL https://kuzco.xyz/setup-kuzco.sh)"

        # 실행 권한 부여
        chmod +x setup-kuzco.sh

        # 스크립트 실행
        ./setup-kuzco.sh       

elif [ "$option" == "2" ]; then
    echo "방화벽 허용을 선택했습니다."

        # UFW 활성화 (아직 활성화되지 않은 경우)
        sudo ufw enable
        
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

elif [ "$option" == "3" ]; then
    echo "Lumoz 노드 삭제를 선택했습니다."

    # 작업 디렉토리 삭제
    if [ -d "./kuzco" ]; then
        rm -rf "./kuzco"
        echo "Lumoz 마이너 디렉토리가 삭제되었습니다."
    fi
    
    # 1. 먼저 실행 중인 모든 관련 프로세스 확인
    ps aux | grep "[m]oz_prover"

    # 2. sudo를 사용하여 프로세스 종료
    sudo kill $(pgrep moz_prover)
    sudo kill $(pgrep run_prover)

    # 3. 여전히 실행 중이라면 강제 종료
    sudo pkill -f "moz_prover"
    sudo pkill -f "run_prover.sh"
    sudo pkill -9 moz_prover
    
    # 실제 moz_prover 프로세스 찾기 및 종료
    moz_pid=$(ps aux | grep "[m]oz_prover" | awk '{print $2}')
    if [ ! -z "$moz_pid" ]; then
        echo "moz_prover 프로세스(PID: $moz_pid)를 종료합니다..."
        sudo kill $moz_pid
        sleep 2
        
        # 프로세스가 여전히 실행 중이면 강제 종료
        if ps -p $moz_pid > /dev/null; then
            echo "프로세스를 강제 종료합니다..."
            sudo kill -9 $moz_pid
        fi
        echo "프로세스가 종료되었습니다."
    else
        echo "실행 중인 moz_prover 프로세스를 찾을 수 없습니다."
    fi

else
    echo "잘못된 선택입니다."
    exit 1
fi
