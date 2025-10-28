// HUD 스크립트

// 메시지 리스너
window.addEventListener('message', function(event) {
    const data = event.data;

    switch(data.type) {
        case 'bumbercar:ui:showHud':
            showHUD();
            break;
        case 'bumbercar:ui:hideHud':
            hideHUD();
            break;
        case 'updateHealth':
            updateHealth(data.health, data.maxHealth, data.percentage);
            break;
        case 'updateStats':
            updateStats(data);
            break;
        case 'updateSpeed':
            updateSpeed(data.speed);
            break;
        case 'updateItemSlot':
            updateItemSlot(data.slot, data.itemId, data.itemData);
            break;
        case 'addEffect':
            addEffect(data.effectName, data.duration);
            break;
        case 'removeEffect':
            removeEffect(data.effectName);
            break;
        case 'startRoundTimer':
            startRoundTimer(data.time);
            break;
        case 'updateRoundTimer':
            updateRoundTimer(data.time);
            break;
        case 'showResults':
            showResults(data.results, data.winner);
            break;
        case 'bumbercar:ui:showTimer':
            showBoundaryTimer(data.timer, data.message);
            break;
        case 'bumbercar:ui:hideTimer':
            hideBoundaryTimer();
            break;
        case 'updateTimer':
            updateBoundaryTimer(data.timer);
            break;
        case 'receiveBomb':
            showBombTimer(data.timer);
            break;
        case 'removeBomb':
            hideBombTimer();
            break;
        case 'updateBombTimer':
            updateBombTimer(data.timer);
            break;
    }
});

// HUD 표시
function showHUD() {
    document.getElementById('gameHUD').classList.remove('hidden');
}

// HUD 숨기기
function hideHUD() {
    document.getElementById('gameHUD').classList.add('hidden');
}

// 체력 업데이트
function updateHealth(health, maxHealth, percentage) {
    const healthBar = document.getElementById('healthBar');
    const healthText = document.getElementById('healthText');

    healthBar.style.width = percentage + '%';
    healthText.textContent = `${Math.floor(health)}/${maxHealth}`;

    // 색상 변경
    if (percentage < 30) {
        healthBar.style.background = 'linear-gradient(90deg, #ff0000 0%, #ff0000 100%)';
    } else if (percentage < 60) {
        healthBar.style.background = 'linear-gradient(90deg, #ffaa00 0%, #ff6b00 100%)';
    } else {
        healthBar.style.background = 'linear-gradient(90deg, #00ff00 0%, #00aa00 100%)';
    }
}

// 스탯 업데이트
function updateStats(data) {
    if (data.damage) {
        document.getElementById('damageText').textContent = Math.floor(data.damage);
    }
    if (data.defense) {
        document.getElementById('defenseText').textContent = Math.floor(data.defense);
    }
}

// 속도 업데이트
function updateSpeed(speed) {
    document.getElementById('speedText').textContent = speed;
}

// 아이템 슬롯 업데이트
function updateItemSlot(slot, itemId, itemData) {
    const slotElement = document.getElementById(`itemSlot${slot}`);
    const slotContent = slotElement.querySelector('.slot-content');

    if (itemId && itemData) {
        slotContent.innerHTML = itemData.icon;
        slotElement.classList.add('has-item');
        slotElement.title = itemData.name;
    } else {
        slotContent.innerHTML = '';
        slotElement.classList.remove('has-item');
        slotElement.title = '';
    }
}

// 효과 추가
function addEffect(effectName, duration) {
    const effectsContainer = document.getElementById('activeEffects');

    // 이미 존재하면 제거
    removeEffect(effectName);

    const effectItem = document.createElement('div');
    effectItem.className = 'effect-item';
    effectItem.id = `effect-${effectName}`;

    let effectDisplayName = effectName;
    let effectIcon = '✨';

    switch(effectName) {
        case 'damage_boost':
            effectDisplayName = '공격력 증가';
            effectIcon = '⚔️';
            break;
        case 'defense_boost':
            effectDisplayName = '방어력 증가';
            effectIcon = '🛡️';
            break;
        case 'speed_boost':
            effectDisplayName = '속도 증가';
            effectIcon = '⚡';
            break;
    }

    effectItem.innerHTML = `
        <span>${effectIcon} ${effectDisplayName}</span>
        <div class="effect-timer" id="timer-${effectName}">${duration}s</div>
    `;

    effectsContainer.appendChild(effectItem);

    // 타이머 카운트다운
    let timeLeft = duration;
    const timer = setInterval(() => {
        timeLeft--;
        const timerElement = document.getElementById(`timer-${effectName}`);
        if (timerElement) {
            timerElement.textContent = `${timeLeft}s`;
        }

        if (timeLeft <= 0) {
            clearInterval(timer);
        }
    }, 1000);
}

// 효과 제거
function removeEffect(effectName) {
    const effectItem = document.getElementById(`effect-${effectName}`);
    if (effectItem) {
        effectItem.remove();
    }
}

// 라운드 타이머 시작
function startRoundTimer(time) {
    updateRoundTimer(time);
}

// 라운드 타이머 업데이트
function updateRoundTimer(time) {
    const minutes = Math.floor(time / 60);
    const seconds = time % 60;
    const formatted = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;

    document.getElementById('roundTimer').textContent = formatted;

    // 색상 변경
    const timerElement = document.getElementById('roundTimer').parentElement;
    if (time <= 30) {
        timerElement.style.background = 'rgba(255, 0, 0, 0.8)';
    } else if (time <= 60) {
        timerElement.style.background = 'rgba(255, 165, 0, 0.8)';
    } else {
        timerElement.style.background = 'rgba(0, 0, 0, 0.8)';
    }
}

// 경계 타이머 표시
function showBoundaryTimer(timer, message) {
    const timerElement = document.getElementById('boundaryTimer');
    timerElement.classList.remove('hidden');
    updateBoundaryTimer(timer);
}

// 경계 타이머 숨기기
function hideBoundaryTimer() {
    document.getElementById('boundaryTimer').classList.add('hidden');
}

// 경계 타이머 업데이트
function updateBoundaryTimer(timer) {
    document.getElementById('boundaryTime').textContent = timer;
}

// 폭탄 타이머 표시
function showBombTimer(timer) {
    const timerElement = document.getElementById('bombTimer');
    timerElement.classList.remove('hidden');
    updateBombTimer(timer);
}

// 폭탄 타이머 숨기기
function hideBombTimer() {
    document.getElementById('bombTimer').classList.add('hidden');
}

// 폭탄 타이머 업데이트
function updateBombTimer(timer) {
    document.getElementById('bombTime').textContent = timer;
}

// 결과 화면 표시
function showResults(results, winner) {
    const resultsScreen = document.getElementById('resultsScreen');
    resultsScreen.classList.remove('hidden');

    // 승자 텍스트
    let winnerText = '게임 종료';
    if (winner) {
        if (typeof winner === 'number') {
            // 개인 승리
            winnerText = `🏆 ${results[0].name} 승리!`;
        } else if (winner === 1) {
            winnerText = '🏆 레드 팀 승리!';
        } else if (winner === 2) {
            winnerText = '🏆 블루 팀 승리!';
        }
    } else {
        winnerText = '무승부';
    }

    document.getElementById('winnerText').textContent = winnerText;

    // 결과 테이블
    const resultsBody = document.getElementById('resultsBody');
    resultsBody.innerHTML = '';

    results.forEach((player, index) => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${index + 1}</td>
            <td>${player.name}</td>
            <td>${player.kills}</td>
            <td>${player.deaths}</td>
            <td>${Math.floor(player.damageDealt)}</td>
        `;

        // 1위 하이라이트
        if (index === 0) {
            row.style.background = 'rgba(255, 215, 0, 0.3)';
            row.style.fontWeight = '700';
        }

        resultsBody.appendChild(row);
    });

    // 10초 후 자동으로 숨기기
    setTimeout(() => {
        resultsScreen.classList.add('hidden');
    }, 10000);
}
