// 3D 텍스트 시스템
const text3DElements = {};

// 메시지 리스너
window.addEventListener('message', function(event) {
    const data = event.data;

    switch(data.type) {
        case 'show3DText':
            show3DText(data.id, data.text, data.position);
            break;
        case 'update3DText':
            update3DText(data.id, data.text, data.x, data.y, data.distance);
            break;
        case 'remove3DText':
            remove3DText(data.id);
            break;
    }
});

// 3D 텍스트 표시
function show3DText(id, text, position) {
    const container = document.getElementById('text3d-container');

    // 이미 존재하면 업데이트
    if (text3DElements[id]) {
        text3DElements[id].textContent = text;
        return;
    }

    // 새로 생성
    const textElement = document.createElement('div');
    textElement.className = 'text3d';
    textElement.id = `text3d-${id}`;
    textElement.textContent = text;

    container.appendChild(textElement);
    text3DElements[id] = textElement;
}

// 3D 텍스트 업데이트 (화면 좌표)
function update3DText(id, text, x, y, distance) {
    let textElement = text3DElements[id];

    // 없으면 생성
    if (!textElement) {
        const container = document.getElementById('text3d-container');
        textElement = document.createElement('div');
        textElement.className = 'text3d';
        textElement.id = `text3d-${id}`;
        container.appendChild(textElement);
        text3DElements[id] = textElement;
    }

    // 위치 업데이트
    textElement.textContent = text;
    textElement.style.left = (x * 100) + '%';
    textElement.style.top = (y * 100) + '%';

    // 거리에 따라 크기 조정
    const scale = Math.max(0.5, 1 - (distance / 50));
    textElement.style.transform = `translate(-50%, -50%) scale(${scale})`;

    // 거리에 따라 투명도 조정
    const opacity = Math.max(0.3, 1 - (distance / 30));
    textElement.style.opacity = opacity;
}

// 3D 텍스트 제거
function remove3DText(id) {
    const textElement = text3DElements[id];
    if (textElement) {
        textElement.remove();
        delete text3DElements[id];
    }
}

// 모든 3D 텍스트 제거
function clearAll3DText() {
    Object.keys(text3DElements).forEach(id => {
        remove3DText(id);
    });
}
