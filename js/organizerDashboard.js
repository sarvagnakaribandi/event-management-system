// EventSphere Organizer Dashboard Scripts
document.addEventListener("DOMContentLoaded", () => {
    // Add subtle hover or interactive animations for metric cards
    const statCards = document.querySelectorAll(".stat-box");
    statCards.forEach(card => {
        card.addEventListener("mouseenter", () => {
            card.style.transform = "translateY(-4px)";
            card.style.transition = "transform 0.2s ease";
        });
        card.addEventListener("mouseleave", () => {
            card.style.transform = "translateY(0)";
        });
    });
});
