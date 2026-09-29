const fileInput = document.getElementById("banner");
const uploadLabel = document.querySelector(".upload-label");

const preview = document.createElement("img");
preview.id = "previewImage";

preview.style.display = "none";
preview.style.width = "100%";
preview.style.height = "170px";
preview.style.objectFit = "cover";
preview.style.borderRadius = "12px";
preview.style.marginTop = "10px";

uploadLabel.appendChild(preview);

fileInput.addEventListener("change", function(){

    const file = this.files[0];

    if(file){

        const reader = new FileReader();

        reader.onload = function(e){

            preview.src = e.target.result;
            preview.style.display = "block";

            uploadLabel.querySelector("p").style.display="none";
            uploadLabel.querySelector("span").style.display="none";
            uploadLabel.querySelector(".upload-icon").style.display="none";

        }

        reader.readAsDataURL(file);

    }

});

uploadLabel.addEventListener("dragover",function(e){

    e.preventDefault();

    uploadLabel.classList.add("drag");

});

uploadLabel.addEventListener("dragleave",function(){

    uploadLabel.classList.remove("drag");

});

uploadLabel.addEventListener("drop",function(e){

    e.preventDefault();

    uploadLabel.classList.remove("drag");

    fileInput.files=e.dataTransfer.files;

    fileInput.dispatchEvent(new Event("change"));

});