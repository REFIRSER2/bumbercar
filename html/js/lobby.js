// 로비 스크립트
let currentLobbyData = null;
let isReady = false;
let isSpectating = false;

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
    }
});

// 로비 표시
function showLobby() {
    document.getElementById('lobby').classList.remove('hidden');
}

// 로비 숨기기
function hideLobby() {
    document.getElementById('lobby').classList.add('hidden');
}

// 로비 닫기
function closeLobby() {
    hideLobby();
    sendToLua('closeLobby', {});
}

// 로비 업데이트
function updateLobby(data) {
    currentLobbyData = data;

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
            <span>${player.name}</span>
            <span>${statusIcon}</span>
        `;

        playerList.appendChild(playerItem);
    });
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

    const readyText = document.getElementById('readyText');
    readyText.textContent = isReady ? '준비 해제' : '준비 완료';

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
