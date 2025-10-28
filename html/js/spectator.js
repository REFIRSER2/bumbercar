// 관전 스크립트

// 메시지 리스너
window.addEventListener('message', function(event) {
    const data = event.data;

    switch(data.type) {
        case 'bumbercar:ui:showSpectator':
            showSpectatorUI();
            break;
        case 'bumbercar:ui:hideSpectator':
            hideSpectatorUI();
            break;
        case 'bumbercar:ui:updateSpectator':
            updateSpectatorUI(data.targetName, data.currentIndex, data.totalTargets);
            break;
        case 'updateSpectatorInfo':
            updateSpectatorInfo(data);
            break;
    }
});

// 관전 UI 표시
function showSpectatorUI() {
    document.getElementById('spectatorUI').classList.remove('hidden');
    document.getElementById('gameHUD').classList.remove('hidden');
}

// 관전 UI 숨기기
function hideSpectatorUI() {
    document.getElementById('spectatorUI').classList.add('hidden');
}

// 관전 UI 업데이트
function updateSpectatorUI(targetName, currentIndex, totalTargets) {
    document.getElementById('spectateTargetName').textContent = targetName;
    document.getElementById('spectateIndex').textContent = currentIndex;
    document.getElementById('spectatTotal').textContent = totalTargets;
}

// 관전 정보 업데이트 (차량 스탯 등)
function updateSpectatorInfo(data) {
    if (data.health !== undefined && data.maxHealth !== undefined) {
        const percentage = (data.health / data.maxHealth) * 100;
        updateHealth(data.health, data.maxHealth, percentage);
    }

    if (data.speed !== undefined) {
        updateSpeed(Math.floor(data.speed));
    }
}
