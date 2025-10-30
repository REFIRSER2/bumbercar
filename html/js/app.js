// ==================== MAIN APP SCRIPT ====================
console.log('[APP] BumberCar app.js loaded');

// Global state
let currentState = 'lobby';
let isResourceLoaded = false;

// ==================== NUI MESSAGE HANDLER ====================
window.addEventListener('message', function(event) {
    const data = event.data;

    // Log all messages for debugging
    if (data.type) {
        console.log('[APP] Received message:', data.type, data);
    }

    // Route messages to appropriate handlers
    switch(data.type) {
        // Core system messages
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
            showNotification(data.message, data.notifType || 'info');
            break;

        // Lobby messages
        case 'bumbercar:ui:showLobby':
        case 'showLobby':
            if (window.showLobby) window.showLobby();
            break;
        case 'bumbercar:ui:hideLobby':
        case 'hideLobby':
            if (window.hideLobby) window.hideLobby();
            break;
        case 'bumbercar:ui:updateLobby':
        case 'updateLobby':
            if (window.updateLobby) window.updateLobby(data.data || data);
            break;
        case 'autoStartTimer':
            if (window.updateAutoStartTimer) window.updateAutoStartTimer(data.time);
            break;
        case 'lobbyChatMessage':
            if (window.addChatMessage) window.addChatMessage(data.author, data.message);
            break;

        // HUD messages
        case 'bumbercar:ui:showHud':
        case 'showHUD':
            if (window.showHUD) window.showHUD();
            break;
        case 'bumbercar:ui:hideHud':
        case 'hideHUD':
            if (window.hideHUD) window.hideHUD();
            break;
        case 'updateHealth':
            if (window.updateHealth) window.updateHealth(data.health, data.maxHealth, data.percentage);
            break;
        case 'updateSpeed':
            if (window.updateSpeed) window.updateSpeed(data.speed);
            break;
        case 'updateRoundTimer':
            if (window.updateRoundTimer) window.updateRoundTimer(data.time);
            break;
        case 'updateGameMode':
            if (window.updateGameMode) window.updateGameMode(data.mode);
            break;

        // Item messages
        case 'itemAdded':
            if (window.addItemToSlot) window.addItemToSlot(data.slot, data.item);
            break;
        case 'itemRemoved':
            if (window.removeItemFromSlot) window.removeItemFromSlot(data.slot);
            break;

        // Effect messages
        case 'effectApplied':
            if (window.addEffect) window.addEffect(data.effect, data.duration);
            break;
        case 'effectRemoved':
            if (window.removeEffect) window.removeEffect(data.effect);
            break;

        // Bomb messages
        case 'bombAssigned':
            if (window.showBombTimer) window.showBombTimer(data.time);
            break;
        case 'updateBombTimer':
            if (window.updateBombTimer) window.updateBombTimer(data.time);
            break;
        case 'bombRemoved':
            if (window.hideBombTimer) window.hideBombTimer();
            break;

        // Boundary messages
        case 'boundaryWarning':
            if (window.showBoundaryWarning) window.showBoundaryWarning(data.time);
            break;
        case 'updateBoundaryTimer':
            if (window.updateBoundaryTimer) window.updateBoundaryTimer(data.time);
            break;
        case 'hideBoundaryWarning':
            if (window.hideBoundaryWarning) window.hideBoundaryWarning();
            break;

        // Weapon HUD messages
        case 'weaponAssigned':
            if (window.showWeaponHUD) window.showWeaponHUD();
            break;
        case 'ammoUpdate':
            if (window.updateAmmo) window.updateAmmo(data.current, data.max);
            break;
        case 'weaponFired':
            if (window.showCrosshair) window.showCrosshair();
            break;
        case 'weaponHit':
            if (window.showHitMarker) window.showHitMarker();
            break;
        case 'showDamageNumber':
            if (window.showDamageNumber) window.showDamageNumber(data.damage, data.x, data.y);
            break;
        case 'hideWeaponHUD':
            if (window.hideWeaponHUD) window.hideWeaponHUD();
            break;

        // Spectator messages
        case 'bumbercar:ui:showSpectator':
        case 'showSpectator':
            if (window.showSpectatorUI) window.showSpectatorUI();
            break;
        case 'bumbercar:ui:hideSpectator':
        case 'hideSpectator':
            if (window.hideSpectatorUI) window.hideSpectatorUI();
            break;
        case 'bumbercar:ui:updateSpectator':
        case 'updateSpectatorTarget':
            if (window.updateSpectatorUI) window.updateSpectatorUI(data.targetName, data.currentIndex, data.totalTargets);
            break;

        // 3D Text messages
        case 'add3DText':
            if (window.add3DText) window.add3DText(data.id, data.text);
            break;
        case 'update3DText':
            if (window.update3DText) window.update3DText(data.id, data.text, data.x, data.y, data.distance);
            break;
        case 'remove3DText':
            if (window.remove3DText) window.remove3DText(data.id);
            break;

        // Results messages
        case 'showResults':
            if (window.showResults) window.showResults(data.results, data.winner);
            break;
        case 'updateReturnCountdown':
            if (window.updateReturnCountdown) window.updateReturnCountdown(data.time);
            break;

        default:
            // Message not handled by app.js, other scripts will handle it
            break;
    }
});

// ==================== INITIALIZATION ====================
function initialize() {
    console.log('[APP] BumberCar UI initialized');
    isResourceLoaded = true;
    hideAll();
}

// ==================== CLEANUP ====================
function cleanup() {
    console.log('[APP] Cleaning up UI');
    hideAll();
    clearAllEffects();
    clearAllNotifications();
    isResourceLoaded = false;
}

// ==================== STATE MANAGEMENT ====================
function handleStateChange(state) {
    currentState = state;
    console.log('[APP] State changed to:', state);

    hideAll();

    switch(state) {
        case 'lobby':
            // Lobby is opened manually via command
            break;
        case 'playing':
            if (window.showHUD) window.showHUD();
            break;
        case 'spectating':
            if (window.showSpectatorUI) window.showSpectatorUI();
            if (window.showHUD) window.showHUD();
            break;
        case 'ending':
            // Results screen is shown via separate message
            break;
    }
}

// ==================== UI VISIBILITY ====================
function hideAll() {
    const containers = [
        'lobbyContainer',
        'gameHUD',
        'weaponHUD',
        'spectatorUI',
        'resultsScreen',
        'bombTimer',
        'boundaryWarning'
    ];

    containers.forEach(id => {
        const element = document.getElementById(id);
        if (element) {
            element.classList.add('hidden');
        }
    });
}

// ==================== NOTIFICATIONS ====================
function showNotification(message, type = 'info') {
    const container = document.getElementById('notifications');
    if (!container) return;

    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.textContent = message;

    container.appendChild(notification);

    // Auto-remove after 3 seconds
    setTimeout(() => {
        notification.style.animation = 'notificationSlideOut 0.3s forwards';
        setTimeout(() => {
            if (notification.parentNode) {
                notification.remove();
            }
        }, 300);
    }, 3000);
}

function clearAllNotifications() {
    const container = document.getElementById('notifications');
    if (container) {
        container.innerHTML = '';
    }
}

// ==================== EFFECTS MANAGEMENT ====================
function clearAllEffects() {
    const container = document.getElementById('activeEffects');
    if (container) {
        container.innerHTML = '';
    }
}

// ==================== KEYBOARD EVENTS ====================
document.addEventListener('keydown', function(e) {
    // ESC key - Close lobby
    if (e.key === 'Escape') {
        const lobby = document.getElementById('lobbyContainer');
        if (lobby && !lobby.classList.contains('hidden')) {
            if (window.closeLobby) window.closeLobby();
        }
    }
});

// ==================== LUA COMMUNICATION ====================
function sendToLua(callback, data) {
    console.log('[APP] Sending to Lua:', callback, data);

    const resourceName = GetParentResourceName();
    const url = `https://${resourceName}/${callback}`;

    console.log('[APP] URL:', url);

    fetch(url, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(data)
    })
    .then(resp => {
        console.log('[APP] Response received for', callback);
        return resp.json();
    })
    .then(resp => {
        console.log('[APP] Response data for', callback, ':', resp);
    })
    .catch(err => {
        console.error('[APP] Error sending to Lua:', callback, err);
    });
}

// Get FiveM resource name
function GetParentResourceName() {
    let url = window.location.href;
    let match = url.match(/https?:\/\/(.*?)\/nui\/(.*?)\//);
    if (match) {
        return match[2];
    }
    return 'bumbercar';
}

// ==================== UTILITY FUNCTIONS ====================
function escapeHtml(text) {
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return String(text).replace(/[&<>"']/g, m => map[m]);
}

function formatTime(seconds) {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
}

// ==================== GLOBAL EXPORTS ====================
window.sendToLua = sendToLua;
window.showNotification = showNotification;
window.escapeHtml = escapeHtml;
window.formatTime = formatTime;
window.GetParentResourceName = GetParentResourceName;

console.log('[APP] BumberCar app.js initialization complete');
