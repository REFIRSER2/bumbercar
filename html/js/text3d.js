// ==================== 3D TEXT SCRIPT ====================
console.log('[TEXT3D] text3d.js loaded');

// Store all 3D text elements
const text3DElements = {};

// ==================== ADD 3D TEXT ====================
function add3DText(id, text) {
    console.log('[TEXT3D] Adding 3D text:', id, text);
    const container = document.getElementById('text3dContainer');
    if (!container) return;

    // If element already exists, update text
    if (text3DElements[id]) {
        text3DElements[id].textContent = text;
        return;
    }

    // Create new element
    const textElement = document.createElement('div');
    textElement.className = 'text3d-element';
    textElement.id = `text3d-${id}`;
    textElement.textContent = text;

    container.appendChild(textElement);
    text3DElements[id] = textElement;
}

// ==================== UPDATE 3D TEXT ====================
function update3DText(id, text, x, y, distance) {
    let textElement = text3DElements[id];

    // Create if doesn't exist
    if (!textElement) {
        const container = document.getElementById('text3dContainer');
        if (!container) return;

        textElement = document.createElement('div');
        textElement.className = 'text3d-element';
        textElement.id = `text3d-${id}`;
        container.appendChild(textElement);
        text3DElements[id] = textElement;
    }

    // Update text and position
    textElement.textContent = text;
    textElement.style.left = `${x * 100}%`;
    textElement.style.top = `${y * 100}%`;

    // Scale based on distance (closer = larger)
    const scale = Math.max(0.5, Math.min(1.5, 1 - (distance / 100)));
    textElement.style.transform = `translate(-50%, -50%) scale(${scale})`;

    // Opacity based on distance
    const opacity = Math.max(0.2, Math.min(1, 1 - (distance / 50)));
    textElement.style.opacity = opacity;
}

// ==================== REMOVE 3D TEXT ====================
function remove3DText(id) {
    console.log('[TEXT3D] Removing 3D text:', id);
    const textElement = text3DElements[id];
    if (textElement) {
        textElement.remove();
        delete text3DElements[id];
    }
}

// ==================== CLEAR ALL 3D TEXT ====================
function clearAll3DText() {
    console.log('[TEXT3D] Clearing all 3D text');
    Object.keys(text3DElements).forEach(id => {
        remove3DText(id);
    });
}

// ==================== GLOBAL EXPORTS ====================
window.add3DText = add3DText;
window.update3DText = update3DText;
window.remove3DText = remove3DText;
window.clearAll3DText = clearAll3DText;

console.log('[TEXT3D] text3d.js initialization complete');
