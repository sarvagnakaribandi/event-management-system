document.addEventListener("DOMContentLoaded", () => {

    const track = document.querySelector(".category-track");

    track.innerHTML += track.innerHTML;

    let position = 0;
    const speed = 0.3; // Increase for faster movement

    function animate() {

        position--;

        if (Math.abs(position) >= track.scrollWidth / 2) {
            position = 0;
        }

        track.style.transform = `translateX(${position}px)`;

        requestAnimationFrame(animate);
    }

    animate();

});