// ==================== RESULTS SCRIPT ====================
console.log('[RESULTS] results.js loaded');

// Results state
let returnCountdownInterval = null;

// ==================== SHOW RESULTS ====================
function showResults(results, winner) {
    console.log('[RESULTS] Showing results:', results, winner);

    const resultsScreen = document.getElementById('resultsScreen');
    if (!resultsScreen) return;

    resultsScreen.classList.remove('hidden');

    // Determine winner text
    let winnerText = '게임 종료';
    if (winner) {
        if (typeof winner === 'string') {
            // Player name winner
            winnerText = `🏆 ${winner} 승리!`;
        } else if (typeof winner === 'number') {
            // Team winner
            if (winner === 1) {
                winnerText = '🏆 레드 팀 승리!';
            } else if (winner === 2) {
                winnerText = '🏆 블루 팀 승리!';
            }
        } else if (winner.name) {
            // Winner object with name
            winnerText = `🏆 ${winner.name} 승리!`;
        }
    } else {
        winnerText = '무승부';
    }

    const winnerElement = document.getElementById('resultsWinner');
    if (winnerElement) {
        winnerElement.textContent = winnerText;
    }

    // Populate results table
    const tableBody = document.getElementById('resultsTableBody');
    if (tableBody && results) {
        tableBody.innerHTML = '';

        results.forEach((player, index) => {
            const row = document.createElement('tr');

            // Add rank class for top 3
            if (index === 0) {
                row.classList.add('rank-1');
            } else if (index === 1) {
                row.classList.add('rank-2');
            } else if (index === 2) {
                row.classList.add('rank-3');
            }

            row.innerHTML = `
                <td>${index + 1}</td>
                <td>${escapeHtml(player.name || 'Unknown')}</td>
                <td>${player.kills || 0}</td>
                <td>${player.deaths || 0}</td>
                <td>${Math.floor(player.damageDealt || 0)}</td>
            `;

            tableBody.appendChild(row);
        });
    }

    // Start return countdown (10 seconds)
    startReturnCountdown(10);
}

// ==================== HIDE RESULTS ====================
function hideResults() {
    console.log('[RESULTS] Hiding results');
    const resultsScreen = document.getElementById('resultsScreen');
    if (resultsScreen) {
        resultsScreen.classList.add('hidden');
    }

    // Clear countdown
    if (returnCountdownInterval) {
        clearInterval(returnCountdownInterval);
        returnCountdownInterval = null;
    }
}

// ==================== RETURN COUNTDOWN ====================
function startReturnCountdown(seconds) {
    const countdownElement = document.getElementById('lobbyReturnCountdown');
    if (!countdownElement) return;

    let timeLeft = seconds;
    countdownElement.textContent = timeLeft;

    // Clear any existing countdown
    if (returnCountdownInterval) {
        clearInterval(returnCountdownInterval);
    }

    returnCountdownInterval = setInterval(() => {
        timeLeft--;
        countdownElement.textContent = timeLeft;

        if (timeLeft <= 0) {
            clearInterval(returnCountdownInterval);
            returnCountdownInterval = null;
            hideResults();
        }
    }, 1000);
}

function updateReturnCountdown(time) {
    const countdownElement = document.getElementById('lobbyReturnCountdown');
    if (countdownElement) {
        countdownElement.textContent = time;
    }
}

// ==================== GLOBAL EXPORTS ====================
window.showResults = showResults;
window.hideResults = hideResults;
window.updateReturnCountdown = updateReturnCountdown;

console.log('[RESULTS] results.js initialization complete');
