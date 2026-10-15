<%-- EventSphere Reusable Notification Bell Widget (Phase 7) --%>
<div class="notif-bell-container">
    <button type="button" class="notif-bell-btn" id="notifBellBtn" onclick="toggleNotifDropdown(event)" title="Notifications" aria-label="Notifications">
        🔔
        <span class="notif-badge" id="notifBadge"></span>
    </button>
    <div class="notif-dropdown" id="notifDropdown">
        <div class="notif-header">
            <h4>🔔 Notifications <span class="notif-count-pill" id="notifCountPill">0 new</span></h4>
            <button type="button" class="notif-mark-all-btn" onclick="markAllNotificationsRead()">Mark all read</button>
        </div>
        <ul class="notif-list" id="notifList">
            <li class="notif-empty">
                <div class="notif-empty-icon">⏳</div>
                <p>Loading notifications...</p>
            </li>
        </ul>
        <div class="notif-footer">
            <a href="notifications.jsp">View all in Notification Center &rarr;</a>
        </div>
    </div>
</div>
