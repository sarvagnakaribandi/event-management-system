// Mobile Menu Toggle

const menu = document.querySelector(".nav-toggle");
const nav = document.querySelector("nav");

if (menu) {
    menu.onclick = () => {
        nav.classList.toggle("show");
    };
}