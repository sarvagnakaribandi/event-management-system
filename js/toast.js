/**
 * Toast Notification Feedback Client (Phase 7)
 */

(function () {
    function getToastContainer() {
        let container = document.getElementById('toastContainer');
        if (!container) {
            container = document.createElement('div');
            container.id = 'toastContainer';
            container.className = 'toast-container';
            document.body.appendChild(container);
        }
        return container;
    }

    function getToastIcon(type) {
        switch (type) {
            case 'success': return '✓';
            case 'error': return '✕';
            case 'warning': return '⚠';
            case 'info':
            default: return 'ℹ';
        }
    }

    function getDefaultTitle(type) {
        switch (type) {
            case 'success': return 'Success';
            case 'error': return 'Error';
            case 'warning': return 'Notice';
            case 'info':
            default: return 'Information';
        }
    }

    window.showToast = function (type, message, title, duration = 4000) {
        if (!message) return;
        const container = getToastContainer();
        const toast = document.createElement('div');
        toast.className = `toast toast-${type}`;

        const finalTitle = title || getDefaultTitle(type);
        const iconChar = getToastIcon(type);

        toast.innerHTML = `
            <div class="toast-icon">${iconChar}</div>
            <div class="toast-content">
                <div class="toast-title">${finalTitle}</div>
                <div class="toast-message">${message}</div>
            </div>
            <button class="toast-close-btn" aria-label="Close">&times;</button>
            <div class="toast-progress" style="animation-duration: ${duration}ms;"></div>
        `;

        container.appendChild(toast);

        // Animate entrance
        requestAnimationFrame(() => {
            toast.classList.add('show');
        });

        // Close button handler
        const closeBtn = toast.querySelector('.toast-close-btn');
        closeBtn.addEventListener('click', () => {
            dismissToast(toast);
        });

        // Auto dismiss after duration
        const timer = setTimeout(() => {
            dismissToast(toast);
        }, duration);

        toast.addEventListener('mouseenter', () => clearTimeout(timer));

        function dismissToast(el) {
            el.classList.remove('show');
            el.classList.add('hide');
            setTimeout(() => {
                if (el.parentNode) {
                    el.parentNode.removeChild(el);
                }
            }, 350);
        }
    };

    // Auto-detect URL query parameters (?success=..., ?error=..., ?msg=...)
    document.addEventListener('DOMContentLoaded', function () {
        const urlParams = new URLSearchParams(window.location.search);
        let hasToastParam = false;

        if (urlParams.has('success')) {
            showToast('success', urlParams.get('success'), 'Success');
            hasToastParam = true;
        } else if (urlParams.has('error')) {
            showToast('error', urlParams.get('error'), 'Action Failed');
            hasToastParam = true;
        } else if (urlParams.has('warning')) {
            showToast('warning', urlParams.get('warning'), 'Notice');
            hasToastParam = true;
        } else if (urlParams.has('msg')) {
            showToast('info', urlParams.get('msg'), 'Notification');
            hasToastParam = true;
        }

        // Clean up URL query parameters so refresh doesn't trigger the toast again
        if (hasToastParam && window.history && window.history.replaceState) {
            const cleanUrl = window.location.protocol + "//" + window.location.host + window.location.pathname;
            window.history.replaceState({ path: cleanUrl }, '', cleanUrl);
        }
    });
})();
