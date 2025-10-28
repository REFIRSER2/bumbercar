// 메인 앱 스크립트
let currentState = 'lobby';

// NUI 메시지 수신
window.addEventListener('message', function(event) {
    const data = event.data;

    switch(data.type) {
        case 'initialize':
            initialize();
            break;
        case 'cleanup':
            cleanup();
            break;
        case 'stateChanged':
            handleStateChange(data.state);
            break;
        case 'notify':
            showNotification(data.message, data.notifType);
            break;
        case 'showDamage':
            showDamage(data.damage);
            break;
        case 'returnToLobby':
            returnToLobby();
            break;

        // 기타 이벤트
        default:
            // 다른 JS 파일에서 처리
            break;
    }
});

// 초기화
function initialize() {
    console.log('BumberCar UI initialized');
    hideAll();
}

// 정리
function cleanup() {
    hideAll();
}

// 모든 UI 숨기기
function hideAll() {
    document.getElementById('lobby').classList.add('hidden');
    document.getElementById('gameHUD').classList.add('hidden');
    document.getElementById('spectatorUI').classList.add('hidden');
    document.getElementById('resultsScreen').classList.add('hidden');
    document.getElementById('boundaryTimer').classList.add('hidden');
    document.getElementById('bombTimer').classList.add('hidden');
}

// 상태 변경
function handleStateChange(state) {
    currentState = state;
    console.log('State changed:', state);

    hideAll();

    switch(state) {
        case 'lobby':
            // 로비는 커맨드로만 열림
            break;
        case 'playing':
            document.getElementById('gameHUD').classList.remove('hidden');
            break;
        case 'ending':
            // 결과 화면은 별도 이벤트로 표시
            break;
    }
}

// 로비로 복귀
function returnToLobby() {
    hideAll();
    // 모든 데이터 초기화
    document.getElementById('activeEffects').innerHTML = '';
    document.getElementById('itemSlot1').querySelector('.slot-content').innerHTML = '';
    document.getElementById('itemSlot2').querySelector('.slot-content').innerHTML = '';
    document.getElementById('itemSlot1').classList.remove('has-item');
    document.getElementById('itemSlot2').classList.remove('has-item');
}

// 알림 표시
function showNotification(message, type = 'info') {
    const notificationContainer = document.getElementById('notifications');

    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.textContent = message;

    notificationContainer.appendChild(notification);

    // 3초 후 제거
    setTimeout(() => {
        notification.style.animation = 'slideOut 0.3s forwards';
        setTimeout(() => {
            notification.remove();
        }, 300);
    }, 3000);
}

// 데미지 표시
function showDamage(damage) {
    const damageDisplay = document.getElementById('damageDisplay');
    damageDisplay.textContent = `-${damage}`;
    damageDisplay.classList.remove('hidden');

    setTimeout(() => {
        damageDisplay.classList.add('hidden');
    }, 1000);
}

// ESC 키로 로비 닫기
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        const lobby = document.getElementById('lobby');
        if (!lobby.classList.contains('hidden')) {
            closeLobby();
        }
    }
});

// Lua로 메시지 전송
function sendToLua(callback, data) {
    fetch(`https://${GetParentResourceName()}/${callback}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(data)
    }).then(resp => resp.json()).then(resp => {
        // 응답 처리
    });
}

// 리소스 이름 가져오기
function GetParentResourceName() {
    let url = window.location.href;
    let match = url.match(/https?:\/\/(.*?)\/nui\/(.*?)\//);
    if (match) {
        return match[2];
    }
    return 'bumbercar';
}
