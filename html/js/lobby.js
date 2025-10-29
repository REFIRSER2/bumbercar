// 로비 스크립트
let currentLobbyData = null;
let isReady = false;
let isSpectating = false;
let chatMessages = [];

// 메시지 리스너
window.addEventListener('message', function(event) {
    const data = event.data;

    switch(data.type) {
        case 'bumbercar:ui:showLobby':
            showLobby();
            break;
        case 'bumbercar:ui:hideLobby':
            hideLobby();
            break;
        case 'bumbercar:ui:updateLobby':
            updateLobby(data.data);
            break;
        case 'autoStartTimer':
            updateAutoStartTimer(data.time);
            break;
        case 'lobbyChatMessage':
            addChatMessage(data.author, data.message);
            break;
    }
});

// 로비 표시
function showLobby() {
    document.getElementById('lobby').classList.remove('hidden');
    // 채팅 입력 포커스 방지
    document.getElementById('chatInput').blur();
}

// 로비 숨기기
function hideLobby() {
    document.getElementById('lobby').classList.add('hidden');
}

// 로비 닫기 (NUI 포커스 해제 포함)
function closeLobby() {
    hideLobby();
    sendToLua('closeLobby', {});
}

// 로비 업데이트
function updateLobby(data) {
    currentLobbyData = data;

    // 정보 바 업데이트
    const currentMap = data.maps.find(m => m.id === data.currentMap);
    const currentMode = data.gameModes.find(m => m.id === data.currentGameMode);

    document.getElementById('currentMapName').textContent = currentMap ? currentMap.name : '-';
    document.getElementById('currentGameModeName').textContent = currentMode ? currentMode.name.split(' ')[0] : '-';
    document.getElementById('playerCountValue').textContent = data.players.length;

    // 맵 목록 업데이트
    const mapList = document.getElementById('mapList');
    mapList.innerHTML = '';

    data.maps.forEach(map => {
        const mapCard = document.createElement('div');
        mapCard.className = 'map-card';
        if (map.id === data.currentMap) {
            mapCard.classList.add('selected');
        }

        mapCard.innerHTML = `
            <div class="map-icon">${map.icon}</div>
            <div class="map-name">${map.name}</div>
            <div class="map-desc">${map.description}</div>
        `;

        mapCard.onclick = () => selectMap(map.id);
        mapList.appendChild(mapCard);
    });

    // 게임 모드 목록 업데이트
    const gameModeList = document.getElementById('gameModeList');
    gameModeList.innerHTML = '';

    data.gameModes.forEach(mode => {
        const modeCard = document.createElement('div');
        modeCard.className = 'gamemode-card';
        if (mode.id === data.currentGameMode) {
            modeCard.classList.add('selected');
        }

        modeCard.innerHTML = `
            <div class="map-name">${mode.name}</div>
            <div class="map-desc">${mode.description}</div>
        `;

        modeCard.onclick = () => selectGameMode(mode.id);
        gameModeList.appendChild(modeCard);
    });

    // 플레이어 목록 업데이트
    const playerList = document.getElementById('playerList');
    playerList.innerHTML = '';

    data.players.forEach(player => {
        const playerItem = document.createElement('div');
        playerItem.className = 'player-item';

        if (player.ready) {
            playerItem.classList.add('ready');
        }
        if (player.spectating) {
            playerItem.classList.add('spectating');
        }

        let statusIcon = '';
        if (player.spectating) {
            statusIcon = '👁️';
        } else if (player.ready) {
            statusIcon = '✅';
        } else {
            statusIcon = '⏳';
        }

        playerItem.innerHTML = `
            <span class="player-name">${player.name}</span>
            <span class="player-status">${statusIcon}</span>
        `;

        playerList.appendChild(playerItem);
    });

    // 사이드바 플레이어 카운트 업데이트
    const menuTitle = document.querySelector('.menu-section-title');
    if (menuTitle) {
        menuTitle.textContent = `플레이어 (${data.players.length})`;
    }
}

// 맵 선택
function selectMap(mapId) {
    sendToLua('selectMap', { map: mapId });
}

// 게임 모드 선택
function selectGameMode(gameMode) {
    sendToLua('selectGameMode', { gameMode: gameMode });
}

// 준비 완료/해제
function toggleReady() {
    isReady = !isReady;

    const readyBtn = document.getElementById('readyBtn');
    const readyText = document.getElementById('readyText');

    if (isReady) {
        readyText.textContent = '준비 해제';
        readyBtn.classList.add('ready');
    } else {
        readyText.textContent = '준비 완료';
        readyBtn.classList.remove('ready');
    }

    sendToLua('toggleReady', { ready: isReady });
}

// 관전 모드 토글
function toggleSpectate() {
    isSpectating = !isSpectating;

    const spectateText = document.getElementById('spectateText');
    spectateText.textContent = isSpectating ? '게임 참가' : '관전 모드';

    sendToLua('toggleSpectate', { spectate: isSpectating });
}

// 자동 시작 타이머 업데이트
function updateAutoStartTimer(time) {
    const timerElement = document.getElementById('autoStartTimer');
    const timeText = document.getElementById('autoStartTime');

    if (time > 0) {
        timerElement.classList.remove('hidden');
        timeText.textContent = time;
    } else {
        timerElement.classList.add('hidden');
    }
}

// 채팅 메시지 추가
function addChatMessage(author, message) {
    const chatContainer = document.getElementById('chatMessages');

    const messageDiv = document.createElement('div');
    messageDiv.className = 'chat-message';
    messageDiv.innerHTML = `
        <span class="chat-author">${author}:</span>
        <span class="chat-text">${escapeHtml(message)}</span>
    `;

    chatContainer.appendChild(messageDiv);

    // 스크롤 맨 아래로
    chatContainer.scrollTop = chatContainer.scrollHeight;

    // 메시지 제한 (최대 50개)
    while (chatContainer.children.length > 50) {
        chatContainer.removeChild(chatContainer.firstChild);
    }
}

// 채팅 메시지 전송
function sendChatMessage() {
    const input = document.getElementById('chatInput');
    const message = input.value.trim();

    if (message.length > 0) {
        sendToLua('sendLobbyChat', { message: message });
        input.value = '';
    }
}

// 엔터키로 채팅 전송
document.addEventListener('DOMContentLoaded', function() {
    const chatInput = document.getElementById('chatInput');
    if (chatInput) {
        chatInput.addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                sendChatMessage();
            }
        });
    }
});

// HTML 이스케이프 (XSS 방지)
function escapeHtml(text) {
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return text.replace(/[&<>"']/g, m => map[m]);
}
