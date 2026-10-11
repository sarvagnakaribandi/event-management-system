document.addEventListener("DOMContentLoaded", () => {
    const track = document.querySelector(".category-track");
    if (track) {
        track.innerHTML += track.innerHTML;
        let position = 0;
        const speed = 0.3;

        function animate() {
            position--;
            if (Math.abs(position) >= track.scrollWidth / 2) {
                position = 0;
            }
            track.style.transform = `translateX(${position}px)`;
            requestAnimationFrame(animate);
        }
        animate();
    }
});

function filterDashboardEvents() {
    const input = (document.getElementById("dashboardSearch")?.value || "").toLowerCase().trim();
    const cards = document.querySelectorAll(".event-card");
    let visibleCount = 0;

    cards.forEach(card => {
        const name = (card.getAttribute("data-name") || "").toLowerCase();
        const category = (card.getAttribute("data-category") || "").toLowerCase();
        const venue = (card.getAttribute("data-venue") || "").toLowerCase();

        if (name.includes(input) || category.includes(input) || venue.includes(input)) {
            card.style.display = "";
            visibleCount++;
        } else {
            card.style.display = "none";
        }
    });

    const noResultsMsg = document.getElementById("noEventsMessage");
    if (noResultsMsg) {
        noResultsMsg.style.display = visibleCount === 0 ? "block" : "none";
    }
}

function filterCategory(catName) {
    const searchInput = document.getElementById("dashboardSearch");
    if (searchInput) {
        searchInput.value = catName === 'ALL' ? '' : catName;
    }
    const cards = document.querySelectorAll(".event-card");
    let visibleCount = 0;

    cards.forEach(card => {
        const category = (card.getAttribute("data-category") || "").toLowerCase();
        if (catName === 'ALL' || category.includes(catName.toLowerCase())) {
            card.style.display = "";
            visibleCount++;
        } else {
            card.style.display = "none";
        }
    });

    const noResultsMsg = document.getElementById("noEventsMessage");
    if (noResultsMsg) {
        noResultsMsg.style.display = visibleCount === 0 ? "block" : "none";
    }

    const eventsSection = document.getElementById("events");
    if (eventsSection) {
        eventsSection.scrollIntoView({ behavior: "smooth" });
    }
}