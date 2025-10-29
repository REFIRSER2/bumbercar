// ==================== LOBBY SCRIPT ====================
console.log('[LOBBY] lobby.js loaded');

// Lobby state
let currentLobbyData = null;
let isReady = false;
let isSpectating = false;

// ==================== SHOW/HIDE LOBBY ====================
function showLobby() {
    console.log('[LOBBY] Showing lobby');
    document.getElementById('lobbyContainer').classList.remove('hidden');
}

function hideLobby() {
    console.log('[LOBBY] Hiding lobby');
    document.getElementById('lobbyContainer').classList.add('hidden');
}

function closeLobby() {
    console.log('[LOBBY] Closing lobby (user initiated)');
    hideLobby();
    sendToLua('closeLobby', {});
}

// ==================== LOBBY DATA UPDATE ====================
function updateLobby(data) {
    console.log('[LOBBY] Updating lobby with data:', data);
    currentLobbyData = data;

    // Update info bar
    const currentMap = data.maps.find(m => m.id === data.currentMap);
    const currentMode = data.gameModes.find(m => m.id === data.currentGameMode);

    document.getElementById('currentMapDisplay').textContent = currentMap ? currentMap.name : '-';
    document.getElementById('currentModeDisplay').textContent = currentMode ? currentMode.name : '-';
    document.getElementById('currentPlayerCount').textContent = data.players.length;
    document.getElementById('lobbyPlayerCount').textContent = `(${data.players.length})`;

    // Update map grid
    const mapGrid = document.getElementById('mapGrid');
    mapGrid.innerHTML = '';

    data.maps.forEach(map => {
        const mapCard = document.createElement('div');
        mapCard.className = 'map-card';
        if (map.id === data.currentMap) {
            mapCard.classList.add('selected');
        }

        mapCard.innerHTML = `
            <div class="map-icon">${map.icon || '🗺️'}</div>
            <div class="map-name">${map.name}</div>
            <div class="map-desc">${map.description || ''}</div>
        `;

        mapCard.onclick = () => selectMap(map.id);
        mapGrid.appendChild(mapCard);
    });

    // Update game mode grid
    const gameModeGrid = document.getElementById('gameModeGrid');
    gameModeGrid.innerHTML = '';

    data.gameModes.forEach(mode => {
        const modeCard = document.createElement('div');
        modeCard.className = 'mode-card';
        if (mode.id === data.currentGameMode) {
            modeCard.classList.add('selected');
        }

        modeCard.innerHTML = `
            <div class="mode-name">${mode.name}</div>
            <div class="mode-desc">${mode.description || ''}</div>
        `;

        modeCard.onclick = () => selectGameMode(mode.id);
        gameModeGrid.appendChild(modeCard);
    });

    // Update player list
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
            statusIcon = '👁';
        } else if (player.ready) {
            statusIcon = '✅';
        } else {
            statusIcon = '⏳';
        }

        playerItem.innerHTML = `
            <span class="player-name">${escapeHtml(player.name)}</span>
            <span class="player-status">${statusIcon}</span>
        `;

        playerList.appendChild(playerItem);
    });
}

// ==================== MAP/MODE SELECTION ====================
function selectMap(mapId) {
    console.log('[LOBBY] Selecting map:', mapId);
    sendToLua('selectMap', { map: mapId });
}

function selectGameMode(gameModeId) {
    console.log('[LOBBY] Selecting game mode:', gameModeId);
    sendToLua('selectGameMode', { gameMode: gameModeId });
}

// ==================== READY/SPECTATE BUTTONS ====================
function toggleReady() {
    console.log('[LOBBY] Toggling ready, current state:', isReady);
    isReady = !isReady;

    const readyBtn = document.getElementById('readyBtn');
    const readyBtnText = document.getElementById('readyBtnText');

    if (isReady) {
        readyBtnText.textContent = '준비 해제';
        readyBtn.classList.add('active');
    } else {
        readyBtnText.textContent = '준비 완료';
        readyBtn.classList.remove('active');
    }

    sendToLua('toggleReady', { ready: isReady });
}

function toggleSpectate() {
    console.log('[LOBBY] Toggling spectate, current state:', isSpectating);
    isSpectating = !isSpectating;

    const spectateBtn = document.getElementById('spectateBtn');
    const spectateBtnText = document.getElementById('spectateBtnText');

    if (isSpectating) {
        spectateBtnText.textContent = '게임 참가';
        spectateBtn.classList.add('active');
    } else {
        spectateBtnText.textContent = '관전 모드';
        spectateBtn.classList.remove('active');
    }

    sendToLua('toggleSpectate', { spectate: isSpectating });
}

// ==================== AUTO-START TIMER ====================
function updateAutoStartTimer(time) {
    const timerElement = document.getElementById('autoStartTimer');
    const secondsElement = document.getElementById('autoStartSeconds');

    if (time > 0) {
        timerElement.classList.remove('hidden');
        secondsElement.textContent = time;
    } else {
        timerElement.classList.add('hidden');
    }
}

// ==================== CHAT ====================
function addChatMessage(author, message) {
    const chatContainer = document.getElementById('chatMessages');
    if (!chatContainer) return;

    const messageDiv = document.createElement('div');
    messageDiv.className = 'chat-message';
    messageDiv.innerHTML = `
        <span class="chat-author">${escapeHtml(author)}:</span>
        <span class="chat-text">${escapeHtml(message)}</span>
    `;

    chatContainer.appendChild(messageDiv);

    // Auto-scroll to bottom
    chatContainer.scrollTop = chatContainer.scrollHeight;

    // Limit messages (max 50)
    while (chatContainer.children.length > 50) {
        chatContainer.removeChild(chatContainer.firstChild);
    }
}

function sendChatMessage() {
    console.log('[LOBBY] Sending chat message');
    const input = document.getElementById('chatInput');
    const message = input.value.trim();

    if (message.length > 0) {
        console.log('[LOBBY] Chat message:', message);
        sendToLua('sendLobbyChat', { message: message });
        input.value = '';
    }
}

// ==================== CHAT INPUT EVENTS ====================
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

// ==================== GLOBAL EXPORTS ====================
window.showLobby = showLobby;
window.hideLobby = hideLobby;
window.closeLobby = closeLobby;
window.updateLobby = updateLobby;
window.selectMap = selectMap;
window.selectGameMode = selectGameMode;
window.toggleReady = toggleReady;
window.toggleSpectate = toggleSpectate;
window.updateAutoStartTimer = updateAutoStartTimer;
window.addChatMessage = addChatMessage;
window.sendChatMessage = sendChatMessage;

console.log('[LOBBY] lobby.js initialization complete');
