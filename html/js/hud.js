// ==================== HUD SCRIPT ====================
console.log('[HUD] hud.js loaded');

// HUD state
let effectTimers = {};

// ==================== SHOW/HIDE HUD ====================
function showHUD() {
    console.log('[HUD] Showing HUD');
    document.getElementById('gameHUD').classList.remove('hidden');
}

function hideHUD() {
    console.log('[HUD] Hiding HUD');
    document.getElementById('gameHUD').classList.add('hidden');
}

// ==================== HEALTH ====================
function updateHealth(health, maxHealth, percentage) {
    const healthBar = document.getElementById('healthBar');
    const healthText = document.getElementById('healthText');

    if (!healthBar || !healthText) return;

    healthBar.style.width = percentage + '%';
    healthText.textContent = `${Math.floor(health)}/${maxHealth}`;

    // Color gradient based on percentage
    if (percentage <= 25) {
        healthBar.style.background = 'linear-gradient(90deg, #F44336 0%, #E53935 100%)';
    } else if (percentage <= 50) {
        healthBar.style.background = 'linear-gradient(90deg, #FF9800 0%, #FF6B00 100%)';
    } else if (percentage <= 75) {
        healthBar.style.background = 'linear-gradient(90deg, #FFEB3B 0%, #FDD835 100%)';
    } else {
        healthBar.style.background = 'linear-gradient(90deg, #4CAF50 0%, #66BB6A 100%)';
    }
}

// ==================== VEHICLE STATS ====================
function updateStats(damage, defense) {
    if (damage !== undefined) {
        const damageValue = document.getElementById('damageValue');
        if (damageValue) damageValue.textContent = Math.floor(damage);
    }
    if (defense !== undefined) {
        const defenseValue = document.getElementById('defenseValue');
        if (defenseValue) defenseValue.textContent = Math.floor(defense);
    }
}

function updateSpeed(speed) {
    const speedValue = document.getElementById('speedValue');
    if (speedValue) {
        speedValue.textContent = `${Math.floor(speed)} km/h`;
    }
}

// ==================== GAME MODE & TIMER ====================
function updateGameMode(modeName) {
    const gameModeLabel = document.getElementById('gameModeLabel');
    if (gameModeLabel) {
        gameModeLabel.textContent = modeName;
    }
}

function updateRoundTimer(time) {
    const roundTimer = document.getElementById('roundTimer');
    if (!roundTimer) return;

    const minutes = Math.floor(time / 60);
    const seconds = time % 60;
    const formatted = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;

    roundTimer.textContent = formatted;

    // Apply warning/danger classes
    roundTimer.classList.remove('warning', 'danger');
    if (time <= 10) {
        roundTimer.classList.add('danger');
    } else if (time <= 30) {
        roundTimer.classList.add('warning');
    }
}

// ==================== ITEMS ====================
function addItemToSlot(slot, item) {
    console.log('[HUD] Adding item to slot', slot, item);
    const slotElement = document.getElementById(`itemSlot${slot}`);
    const iconElement = document.getElementById(`slot${slot}Icon`);
    const nameElement = document.getElementById(`slot${slot}Name`);

    if (!slotElement || !iconElement || !nameElement) return;

    slotElement.classList.add('has-item');
    iconElement.textContent = item.icon || '📦';
    nameElement.textContent = item.name || '';
}

function removeItemFromSlot(slot) {
    console.log('[HUD] Removing item from slot', slot);
    const slotElement = document.getElementById(`itemSlot${slot}`);
    const iconElement = document.getElementById(`slot${slot}Icon`);
    const nameElement = document.getElementById(`slot${slot}Name`);

    if (!slotElement || !iconElement || !nameElement) return;

    slotElement.classList.remove('has-item');
    iconElement.textContent = '';
    nameElement.textContent = '';
}

// ==================== EFFECTS ====================
function addEffect(effectId, duration) {
    console.log('[HUD] Adding effect:', effectId, duration);
    const container = document.getElementById('activeEffects');
    if (!container) return;

    // Remove existing effect if present
    removeEffect(effectId);

    // Map effect IDs to display info
    const effectInfo = getEffectInfo(effectId);

    const effectBadge = document.createElement('div');
    effectBadge.className = 'effect-badge';
    effectBadge.id = `effect-${effectId}`;
    effectBadge.innerHTML = `
        <div class="effect-icon">${effectInfo.icon}</div>
        <div class="effect-info">
            <div class="effect-name">${effectInfo.name}</div>
            <div class="effect-timer" id="timer-${effectId}">${duration}초</div>
        </div>
    `;

    container.appendChild(effectBadge);

    // Start countdown timer
    let timeLeft = duration;
    effectTimers[effectId] = setInterval(() => {
        timeLeft--;
        const timerElement = document.getElementById(`timer-${effectId}`);
        if (timerElement) {
            timerElement.textContent = `${timeLeft}초`;
        }

        if (timeLeft <= 0) {
            clearInterval(effectTimers[effectId]);
            delete effectTimers[effectId];
            removeEffect(effectId);
        }
    }, 1000);
}

function removeEffect(effectId) {
    console.log('[HUD] Removing effect:', effectId);
    const effectBadge = document.getElementById(`effect-${effectId}`);
    if (effectBadge) {
        effectBadge.remove();
    }

    // Clear timer
    if (effectTimers[effectId]) {
        clearInterval(effectTimers[effectId]);
        delete effectTimers[effectId];
    }
}

function getEffectInfo(effectId) {
    const effects = {
        'speed_boost': { icon: '⚡', name: '속도 증가' },
        'damage_boost': { icon: '⚔', name: '공격력 증가' },
        'defense_boost': { icon: '🛡', name: '방어력 증가' },
        'shield': { icon: '🛡', name: '보호막' },
        'invisibility': { icon: '👻', name: '투명화' },
        'invincibility': { icon: '✨', name: '무적' }
    };

    return effects[effectId] || { icon: '✨', name: effectId };
}

// ==================== BOMB TIMER ====================
function showBombTimer(time) {
    console.log('[HUD] Showing bomb timer:', time);
    const bombTimer = document.getElementById('bombTimer');
    if (bombTimer) {
        bombTimer.classList.remove('hidden');
        updateBombTimer(time);
    }
}

function hideBombTimer() {
    console.log('[HUD] Hiding bomb timer');
    const bombTimer = document.getElementById('bombTimer');
    if (bombTimer) {
        bombTimer.classList.add('hidden');
    }
}

function updateBombTimer(time) {
    const bombCountdown = document.getElementById('bombCountdown');
    if (bombCountdown) {
        bombCountdown.textContent = time;
    }
}

// ==================== BOUNDARY WARNING ====================
function showBoundaryWarning(time) {
    console.log('[HUD] Showing boundary warning:', time);
    const boundaryWarning = document.getElementById('boundaryWarning');
    if (boundaryWarning) {
        boundaryWarning.classList.remove('hidden');
        updateBoundaryTimer(time);
    }
}

function hideBoundaryWarning() {
    console.log('[HUD] Hiding boundary warning');
    const boundaryWarning = document.getElementById('boundaryWarning');
    if (boundaryWarning) {
        boundaryWarning.classList.add('hidden');
    }
}

function updateBoundaryTimer(time) {
    const boundaryCountdown = document.getElementById('boundaryCountdown');
    if (boundaryCountdown) {
        boundaryCountdown.textContent = time;
    }
}

// ==================== WEAPON HUD ====================
function showWeaponHUD() {
    console.log('[HUD] Showing weapon HUD');
    const weaponHUD = document.getElementById('weaponHUD');
    if (weaponHUD) {
        weaponHUD.classList.remove('hidden');
    }
}

function hideWeaponHUD() {
    console.log('[HUD] Hiding weapon HUD');
    const weaponHUD = document.getElementById('weaponHUD');
    if (weaponHUD) {
        weaponHUD.classList.add('hidden');
    }
}

function updateAmmo(current, max) {
    const ammoCurrent = document.getElementById('ammoCurrent');
    const ammoMax = document.getElementById('ammoMax');

    if (ammoCurrent) ammoCurrent.textContent = current;
    if (ammoMax) ammoMax.textContent = max;
}

function showCrosshair() {
    const crosshair = document.getElementById('crosshair');
    if (crosshair) {
        crosshair.classList.remove('hidden');
    }
}

function hideCrosshair() {
    const crosshair = document.getElementById('crosshair');
    if (crosshair) {
        crosshair.classList.add('hidden');
    }
}

function showHitMarker() {
    console.log('[HUD] Showing hit marker');
    const hitMarker = document.getElementById('hitMarker');
    if (!hitMarker) return;

    hitMarker.classList.remove('hidden');

    // Auto-hide after 200ms
    setTimeout(() => {
        hitMarker.classList.add('hidden');
    }, 200);
}

function showDamageNumber(damage, x, y) {
    console.log('[HUD] Showing damage number:', damage, 'at', x, y);
    const container = document.getElementById('damageNumbers');
    if (!container) return;

    const damageNumber = document.createElement('div');
    damageNumber.className = 'damage-number';
    damageNumber.textContent = `-${Math.floor(damage)}`;
    damageNumber.style.left = `${x * 100}%`;
    damageNumber.style.top = `${y * 100}%`;

    container.appendChild(damageNumber);

    // Remove after animation (1 second)
    setTimeout(() => {
        if (damageNumber.parentNode) {
            damageNumber.remove();
        }
    }, 1000);
}

function showLockOn() {
    const lockOn = document.getElementById('lockOnIndicator');
    if (lockOn) {
        lockOn.classList.remove('hidden');
    }
}

function hideLockOn() {
    const lockOn = document.getElementById('lockOnIndicator');
    if (lockOn) {
        lockOn.classList.add('hidden');
    }
}

// ==================== GLOBAL EXPORTS ====================
window.showHUD = showHUD;
window.hideHUD = hideHUD;
window.updateHealth = updateHealth;
window.updateStats = updateStats;
window.updateSpeed = updateSpeed;
window.updateGameMode = updateGameMode;
window.updateRoundTimer = updateRoundTimer;
window.addItemToSlot = addItemToSlot;
window.removeItemFromSlot = removeItemFromSlot;
window.addEffect = addEffect;
window.removeEffect = removeEffect;
window.showBombTimer = showBombTimer;
window.hideBombTimer = hideBombTimer;
window.updateBombTimer = updateBombTimer;
window.showBoundaryWarning = showBoundaryWarning;
window.hideBoundaryWarning = hideBoundaryWarning;
window.updateBoundaryTimer = updateBoundaryTimer;
window.showWeaponHUD = showWeaponHUD;
window.hideWeaponHUD = hideWeaponHUD;
window.updateAmmo = updateAmmo;
window.showCrosshair = showCrosshair;
window.hideCrosshair = hideCrosshair;
window.showHitMarker = showHitMarker;
window.showDamageNumber = showDamageNumber;
window.showLockOn = showLockOn;
window.hideLockOn = hideLockOn;

console.log('[HUD] hud.js initialization complete');
