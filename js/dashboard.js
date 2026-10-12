let currentCategory = 'ALL';
let currentSearch = '';

document.addEventListener("DOMContentLoaded", () => {
    // Clone category track once for continuous CSS ticker if present
    const track = document.querySelector(".category-track");
    if (track && track.children.length > 0 && !track.dataset.cloned) {
        track.dataset.cloned = "true";
        // Clone items for smooth infinite loop in CSS
        const items = Array.from(track.children);
        items.forEach(item => {
            const clone = item.cloneNode(true);
            track.appendChild(clone);
        });
    }

    // Check URL parameters (e.g. ?category=Gaming or ?search=hack)
    const urlParams = new URLSearchParams(window.location.search);
    const catParam = urlParams.get("category");
    const searchParam = urlParams.get("search");

    if (catParam) {
        currentCategory = catParam;
    }
    if (searchParam) {
        currentSearch = searchParam.toLowerCase().trim();
        const searchInput = document.getElementById("dashboardSearch");
        if (searchInput) searchInput.value = searchParam;
    }

    applyDashboardFilters();

    if (catParam || searchParam) {
        const eventsSec = document.getElementById("events");
        if (eventsSec) {
            setTimeout(() => {
                eventsSec.scrollIntoView({ behavior: "smooth" });
            }, 100);
        }
    }
});

function applyDashboardFilters() {
    const cards = document.querySelectorAll(".event-card");
    let visibleCount = 0;

    cards.forEach(card => {
        const name = (card.getAttribute("data-name") || "").toLowerCase();
        const category = (card.getAttribute("data-category") || "").toLowerCase();
        const venue = (card.getAttribute("data-venue") || "").toLowerCase();
        const desc = (card.getAttribute("data-description") || "").toLowerCase();

        const matchesCategory = (currentCategory === 'ALL' || category === currentCategory.toLowerCase() || category.includes(currentCategory.toLowerCase()));
        const matchesSearch = (!currentSearch || name.includes(currentSearch) || category.includes(currentSearch) || venue.includes(currentSearch) || desc.includes(currentSearch));

        if (matchesCategory && matchesSearch) {
            card.style.display = "";
            visibleCount++;
        } else {
            card.style.display = "none";
        }
    });

    // Toggle no events message
    const noResultsMsg = document.getElementById("noEventsMessage");
    if (noResultsMsg) {
        noResultsMsg.style.display = visibleCount === 0 ? "block" : "none";
    }

    // Update active filter toolbar
    const toolbar = document.getElementById("filterToolbar");
    const activeLabel = document.getElementById("activeFilterPill");
    if (toolbar && activeLabel) {
        const isFiltered = currentCategory !== 'ALL' || currentSearch.length > 0;
        toolbar.style.display = isFiltered ? "block" : "none";

        let labelText = "";
        if (currentCategory !== 'ALL') {
            labelText += "Category: " + currentCategory;
        }
        if (currentSearch.length > 0) {
            if (labelText) labelText += " | ";
            labelText += 'Search: "' + currentSearch + '"';
        }
        activeLabel.textContent = labelText || "All Events";
    }

    // Highlight active category pills
    const allCatCards = document.querySelectorAll(".cat-card");
    allCatCards.forEach(card => {
        const cardText = card.textContent.trim().toLowerCase();
        if (currentCategory === 'ALL') {
            if (cardText.includes("all events")) {
                card.classList.add("cat-card-active");
            } else {
                card.classList.remove("cat-card-active");
            }
        } else {
            if (cardText.includes(currentCategory.toLowerCase())) {
                card.classList.add("cat-card-active");
            } else {
                card.classList.remove("cat-card-active");
            }
        }
    });
}

function filterDashboardEvents() {
    const input = (document.getElementById("dashboardSearch")?.value || "").toLowerCase().trim();
    currentSearch = input;
    applyDashboardFilters();
}

function filterCategory(catName) {
    if (currentCategory.toLowerCase() === catName.toLowerCase() && catName !== 'ALL') {
        currentCategory = 'ALL';
    } else {
        currentCategory = catName;
    }
    applyDashboardFilters();

    const eventsSection = document.getElementById("events");
    if (eventsSection) {
        eventsSection.scrollIntoView({ behavior: "smooth" });
    }
}

function resetAllFilters() {
    currentCategory = 'ALL';
    currentSearch = '';
    const searchInput = document.getElementById("dashboardSearch");
    if (searchInput) searchInput.value = '';
    applyDashboardFilters();
}