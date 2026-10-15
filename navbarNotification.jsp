<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%-- EventSphere Reusable Notification Bell Widget (Phase 7) --%>
<div class="notif-bell-container">
    <button type="button" class="notif-bell-btn" id="notifBellBtn" onclick="toggleNotifDropdown(event)" title="Notifications" aria-label="Notifications">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" class="notif-bell-svg">
            <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path>
            <path d="M13.73 21a2 2 0 0 1-3.46 0"></path>
        </svg>
        <span class="notif-badge" id="notifBadge"></span>
    </button>
    <div class="notif-dropdown" id="notifDropdown">
        <div class="notif-header">
            <h4>
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#a855f7" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" style="display:inline-block; vertical-align:middle; margin-right:6px;">
                    <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path>
                    <path d="M13.73 21a2 2 0 0 1-3.46 0"></path>
                </svg>
                Notifications <span class="notif-count-pill" id="notifCountPill">0 new</span>
            </h4>
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
