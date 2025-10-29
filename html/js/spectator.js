// ==================== SPECTATOR SCRIPT ====================
console.log('[SPECTATOR] spectator.js loaded');

// ==================== SHOW/HIDE SPECTATOR UI ====================
function showSpectatorUI() {
    console.log('[SPECTATOR] Showing spectator UI');
    document.getElementById('spectatorUI').classList.remove('hidden');
    // Also show HUD so spectator can see target's stats
    if (window.showHUD) window.showHUD();
}

function hideSpectatorUI() {
    console.log('[SPECTATOR] Hiding spectator UI');
    document.getElementById('spectatorUI').classList.add('hidden');
}

// ==================== UPDATE SPECTATOR INFO ====================
function updateSpectatorUI(targetName, currentIndex, totalTargets) {
    console.log('[SPECTATOR] Updating spectator UI:', targetName, currentIndex, totalTargets);

    const nameElement = document.getElementById('spectatorTargetName');
    const indexElement = document.getElementById('spectatorIndex');
    const totalElement = document.getElementById('spectatorTotal');

    if (nameElement) {
        nameElement.textContent = targetName || '-';
    }
    if (indexElement) {
        indexElement.textContent = currentIndex || 1;
    }
    if (totalElement) {
        totalElement.textContent = totalTargets || 1;
    }
}

// ==================== GLOBAL EXPORTS ====================
window.showSpectatorUI = showSpectatorUI;
window.hideSpectatorUI = hideSpectatorUI;
window.updateSpectatorUI = updateSpectatorUI;

console.log('[SPECTATOR] spectator.js initialization complete');
