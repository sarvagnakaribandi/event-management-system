/**
 * EventSphere In-App Notification Center Client (Phase 7)
 */

(function () {
    let pollingInterval = null;

    function getIconForType(type) {
        switch ((type || '').toLowerCase()) {
            case 'booking':
                return { icon: '🎟️', cls: 'notif-icon-booking' };
            case 'payment':
                return { icon: '💳', cls: 'notif-icon-payment' };
            case 'proposal':
                return { icon: '📝', cls: 'notif-icon-proposal' };
            case 'verification':
                return { icon: '🛡️', cls: 'notif-icon-verification' };
            default:
                return { icon: '🔔', cls: 'notif-icon-system' };
        }
    }

    function escapeHtml(str) {
        if (!str) return '';
        return str.replace(/&/g, '&amp;')
                  .replace(/</g, '&lt;')
                  .replace(/>/g, '&gt;')
                  .replace(/"/g, '&quot;')
                  .replace(/'/g, '&#39;');
    }

    window.toggleNotifDropdown = function (event) {
        if (event) event.stopPropagation();
        const dropdown = document.getElementById('notifDropdown');
        if (!dropdown) return;
        const isShown = dropdown.classList.contains('show');
        if (isShown) {
            dropdown.classList.remove('show');
        } else {
            dropdown.classList.add('show');
            loadNotifications();
        }
    };

    window.loadNotifications = function () {
        fetch('getNotifications.jsp')
            .then(res => res.json())
            .then(data => {
                if (!data.authenticated) return;

                const badge = document.getElementById('notifBadge');
                const countPill = document.getElementById('notifCountPill');
                const list = document.getElementById('notifList');

                // Update badge
                if (badge) {
                    if (data.unreadCount > 0) {
                        badge.innerText = data.unreadCount > 99 ? '99+' : data.unreadCount;
                        badge.style.display = 'inline-flex';
                    } else {
                        badge.style.display = 'none';
                    }
                }

                if (countPill) {
                    countPill.innerText = data.unreadCount + ' new';
                }

                // Render list
                if (list) {
                    if (!data.notifications || data.notifications.length === 0) {
                        list.innerHTML = `
                            <li class="notif-empty">
                                <div class="notif-empty-icon">🔕</div>
                                <p>You're all caught up! No notifications yet.</p>
                            </li>
                        `;
                        return;
                    }

                    list.innerHTML = data.notifications.map(n => {
                        const iconData = getIconForType(n.type);
                        const unreadClass = !n.isRead ? 'unread' : '';
                        const targetUrl = n.url ? escapeHtml(n.url) : '';

                        return `
                            <li class="notif-item ${unreadClass}" onclick="handleNotifClick(${n.id}, '${targetUrl}')">
                                <div class="notif-icon-box ${iconData.cls}">
                                    ${iconData.icon}
                                </div>
                                <div class="notif-content">
                                    <div class="notif-title">
                                        <span>${escapeHtml(n.title)}</span>
                                    </div>
                                    <p class="notif-desc">${escapeHtml(n.message)}</p>
                                    <span class="notif-time">${escapeHtml(n.timeAgo)}</span>
                                </div>
                            </li>
                        `;
                    }).join('');
                }
            })
            .catch(err => console.debug('Notifications fetch error:', err));
    };

    window.handleNotifClick = function (notifId, targetUrl) {
        fetch(`markNotificationRead.jsp?id=${notifId}`)
            .then(res => res.json())
            .then(() => {
                if (targetUrl && targetUrl.trim() !== '') {
                    window.location.href = targetUrl;
                } else {
                    loadNotifications();
                }
            })
            .catch(() => {
                if (targetUrl && targetUrl.trim() !== '') {
                    window.location.href = targetUrl;
                }
            });
    };

    window.markAllNotificationsRead = function () {
        fetch('markNotificationRead.jsp?action=all')
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    loadNotifications();
                    if (window.showToast) {
                        window.showToast('success', 'All notifications marked as read', 'Notifications');
                    }
                }
            })
            .catch(err => console.debug(err));
    };

    // Close dropdown on outside click
    document.addEventListener('click', function (e) {
        const dropdown = document.getElementById('notifDropdown');
        const bellBtn = document.getElementById('notifBellBtn');
        if (dropdown && dropdown.classList.contains('show')) {
            if (!dropdown.contains(e.target) && (!bellBtn || !bellBtn.contains(e.target))) {
                dropdown.classList.remove('show');
            }
        }
    });

    // Initialize when DOM is ready
    document.addEventListener('DOMContentLoaded', function () {
        loadNotifications();
        // Poll every 30 seconds
        if (!pollingInterval) {
            pollingInterval = setInterval(loadNotifications, 30000);
        }
    });
})();
